package com.ibme.funedu.server.web;

import com.ibme.funedu.server.auth.AuthProperties;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Clock;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * In-memory 1-minute sliding-window rate limiter per IP and per family.
 * Single server instance is enough for this app.
 */
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    static final long WINDOW_MS = 60_000L;
    static final int SYNC_PER_FAMILY = 60;
    static final int SYNC_PER_IP = 120;
    static final int ROOMS_PER_FAMILY = 10;

    private static final class Bucket {
        private final Deque<Long> hits = new ArrayDeque<>();

        synchronized long retryAfterSeconds(long nowMs, int limit, boolean consumeIfAllowed) {
            long cutoff = nowMs - WINDOW_MS;
            while (!hits.isEmpty() && hits.peekFirst() <= cutoff) {
                hits.removeFirst();
            }
            if (hits.size() >= limit) {
                long waitMs = (hits.peekFirst() + WINDOW_MS) - nowMs;
                return Math.max(1L, (waitMs + 999L) / 1000L);
            }
            if (consumeIfAllowed) {
                hits.addLast(nowMs);
            }
            return 0L;
        }

        synchronized boolean isEmptyAt(long nowMs) {
            long cutoff = nowMs - WINDOW_MS;
            while (!hits.isEmpty() && hits.peekFirst() <= cutoff) {
                hits.removeFirst();
            }
            return hits.isEmpty();
        }
    }

    private final int authPerIp;
    private final Clock clock;
    private final ConcurrentHashMap<String, Bucket> authIpBuckets = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Bucket> syncFamilyBuckets = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Bucket> syncIpBuckets = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Bucket> roomsFamilyBuckets = new ConcurrentHashMap<>();

    @Autowired
    public RateLimitFilter(AuthProperties props) {
        this(props.requestsPerMinute(), Clock.systemUTC());
    }

    RateLimitFilter(int authPerIp, Clock clock) {
        this.authPerIp = authPerIp;
        this.clock = clock;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        String uri = req.getRequestURI();
        long now = clock.millis();

        if (uri.startsWith("/api/v1/auth/")) {
            long retry = tryAcquire(authIpBuckets, req.getRemoteAddr(), authPerIp, now);
            if (retry > 0) {
                reject(res, retry);
                return;
            }
        } else if ("/api/v1/sync".equals(uri)) {
            String family = authenticatedFamily();
            if (family != null) {
                long famWait = checkOnly(syncFamilyBuckets, family, SYNC_PER_FAMILY, now);
                if (famWait > 0) {
                    reject(res, famWait);
                    return;
                }
                long ipWait = checkOnly(syncIpBuckets, req.getRemoteAddr(), SYNC_PER_IP, now);
                if (ipWait > 0) {
                    reject(res, ipWait);
                    return;
                }
                long retry = Math.max(
                        tryAcquire(syncFamilyBuckets, family, SYNC_PER_FAMILY, now),
                        tryAcquire(syncIpBuckets, req.getRemoteAddr(), SYNC_PER_IP, now));
                if (retry > 0) {
                    reject(res, retry);
                    return;
                }
            }
        } else if ("POST".equalsIgnoreCase(req.getMethod()) && "/api/v1/rooms".equals(uri)) {
            String family = authenticatedFamily();
            if (family != null) {
                long retry = tryAcquire(roomsFamilyBuckets, family, ROOMS_PER_FAMILY, now);
                if (retry > 0) {
                    reject(res, retry);
                    return;
                }
            }
        }

        chain.doFilter(req, res);
    }

    @Scheduled(fixedDelay = 60_000L)
    void purgeStale() {
        long now = clock.millis();
        purgeMap(authIpBuckets, now);
        purgeMap(syncFamilyBuckets, now);
        purgeMap(syncIpBuckets, now);
        purgeMap(roomsFamilyBuckets, now);
    }

    public void reset() {
        authIpBuckets.clear();
        syncFamilyBuckets.clear();
        syncIpBuckets.clear();
        roomsFamilyBuckets.clear();
    }

    private static void purgeMap(ConcurrentHashMap<String, Bucket> map, long now) {
        map.entrySet().removeIf(e -> e.getValue().isEmptyAt(now));
    }

    private static long checkOnly(ConcurrentHashMap<String, Bucket> map, String key, int limit, long now) {
        Bucket b = map.get(key);
        return b == null ? 0L : b.retryAfterSeconds(now, limit, false);
    }

    private static long tryAcquire(ConcurrentHashMap<String, Bucket> map, String key, int limit, long now) {
        return map.computeIfAbsent(key, k -> new Bucket()).retryAfterSeconds(now, limit, true);
    }

    private static String authenticatedFamily() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth instanceof JwtAuthenticationToken jwt) {
            return jwt.getToken().getSubject();
        }
        return null;
    }

    private static void reject(HttpServletResponse res, long retryAfterSeconds) throws IOException {
        res.setStatus(429);
        res.setHeader("Retry-After", Long.toString(retryAfterSeconds));
        res.setContentType("application/json");
        res.getWriter().write("{\"error\":\"too_many\"}");
    }
}
