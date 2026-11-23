package com.ibme.funedu.server.web;

import com.ibme.funedu.server.auth.AuthProperties;
import com.ibme.funedu.server.auth.TokenService;
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
    static final long HOUR_WINDOW_MS = 3_600_000L;
    static final int SYNC_PER_FAMILY = 60;
    static final int SYNC_PER_IP = 120;
    static final int ROOMS_PER_FAMILY = 10;
    static final int FRIEND_CODE_PER_FAMILY = 10;
    static final int FRIEND_REDEEM_PER_FAMILY = 20;

    private static final class Bucket {
        private final Deque<Long> hits = new ArrayDeque<>();

        synchronized long retryAfterSeconds(long nowMs, long windowMs, int limit, boolean consumeIfAllowed) {
            long cutoff = nowMs - windowMs;
            while (!hits.isEmpty() && hits.peekFirst() <= cutoff) {
                hits.removeFirst();
            }
            if (hits.size() >= limit) {
                long waitMs = (hits.peekFirst() + windowMs) - nowMs;
                return Math.max(1L, (waitMs + 999L) / 1000L);
            }
            if (consumeIfAllowed) {
                hits.addLast(nowMs);
            }
            return 0L;
        }

        synchronized boolean isEmptyAt(long nowMs, long windowMs) {
            long cutoff = nowMs - windowMs;
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
    private final ConcurrentHashMap<String, Bucket> friendCodeBuckets = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Bucket> friendRedeemBuckets = new ConcurrentHashMap<>();

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
            long retry = tryAcquire(authIpBuckets, req.getRemoteAddr(), WINDOW_MS, authPerIp, now);
            if (retry > 0) {
                reject(res, retry);
                return;
            }
        } else if ("/api/v1/sync".equals(uri)) {
            String family = authenticatedFamily();
            if (family != null) {
                long famWait = checkOnly(syncFamilyBuckets, family, WINDOW_MS, SYNC_PER_FAMILY, now);
                if (famWait > 0) {
                    reject(res, famWait);
                    return;
                }
                long ipWait = checkOnly(syncIpBuckets, req.getRemoteAddr(), WINDOW_MS, SYNC_PER_IP, now);
                if (ipWait > 0) {
                    reject(res, ipWait);
                    return;
                }
                long retry = Math.max(
                        tryAcquire(syncFamilyBuckets, family, WINDOW_MS, SYNC_PER_FAMILY, now),
                        tryAcquire(syncIpBuckets, req.getRemoteAddr(), WINDOW_MS, SYNC_PER_IP, now));
                if (retry > 0) {
                    reject(res, retry);
                    return;
                }
            }
        } else if ("POST".equalsIgnoreCase(req.getMethod()) && "/api/v1/rooms".equals(uri)) {
            String family = authenticatedFamily();
            if (family != null) {
                long retry = tryAcquire(roomsFamilyBuckets, family, WINDOW_MS, ROOMS_PER_FAMILY, now);
                if (retry > 0) {
                    reject(res, retry);
                    return;
                }
            }
        } else if ("POST".equalsIgnoreCase(req.getMethod()) && "/api/v1/friends/code".equals(uri)) {
            String family = authenticatedFamily();
            if (family != null) {
                long retry = tryAcquire(friendCodeBuckets, family, HOUR_WINDOW_MS, FRIEND_CODE_PER_FAMILY, now);
                if (retry > 0) {
                    reject(res, retry);
                    return;
                }
            }
        } else if ("POST".equalsIgnoreCase(req.getMethod()) && "/api/v1/friends/redeem".equals(uri)) {
            String family = authenticatedFamily();
            if (family != null) {
                long retry = tryAcquire(friendRedeemBuckets, family, HOUR_WINDOW_MS, FRIEND_REDEEM_PER_FAMILY, now);
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
        purgeMap(authIpBuckets, now, WINDOW_MS);
        purgeMap(syncFamilyBuckets, now, WINDOW_MS);
        purgeMap(syncIpBuckets, now, WINDOW_MS);
        purgeMap(roomsFamilyBuckets, now, WINDOW_MS);
        purgeMap(friendCodeBuckets, now, HOUR_WINDOW_MS);
        purgeMap(friendRedeemBuckets, now, HOUR_WINDOW_MS);
    }

    public void reset() {
        authIpBuckets.clear();
        syncFamilyBuckets.clear();
        syncIpBuckets.clear();
        roomsFamilyBuckets.clear();
        friendCodeBuckets.clear();
        friendRedeemBuckets.clear();
    }

    private static void purgeMap(ConcurrentHashMap<String, Bucket> map, long now, long windowMs) {
        map.entrySet().removeIf(e -> e.getValue().isEmptyAt(now, windowMs));
    }

    private static long checkOnly(
            ConcurrentHashMap<String, Bucket> map, String key, long windowMs, int limit, long now) {
        Bucket b = map.get(key);
        return b == null ? 0L : b.retryAfterSeconds(now, windowMs, limit, false);
    }

    private static long tryAcquire(
            ConcurrentHashMap<String, Bucket> map, String key, long windowMs, int limit, long now) {
        return map.computeIfAbsent(key, k -> new Bucket()).retryAfterSeconds(now, windowMs, limit, true);
    }

    private static String authenticatedFamily() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth instanceof JwtAuthenticationToken jwt) {
            String fam = jwt.getToken().getClaimAsString(TokenService.FAMILY_CLAIM);
            return fam != null ? fam : jwt.getToken().getSubject();
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
