package com.ibme.funedu.server.web;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * At most N sign-in / refresh calls per client address per minute (fixed
 * window, in memory: one server instance is enough for this app).
 */
class AuthRateLimitFilter extends OncePerRequestFilter {

    private record Window(long minute, AtomicInteger count) {}

    private final int perMinute;
    private final ConcurrentHashMap<String, Window> windows = new ConcurrentHashMap<>();

    AuthRateLimitFilter(int perMinute) {
        this.perMinute = perMinute;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith("/api/v1/auth/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        long minute = System.currentTimeMillis() / 60_000;
        if (windows.size() > 10_000) windows.values().removeIf(w -> w.minute() != minute);
        Window w = windows.compute(req.getRemoteAddr(),
                (k, old) -> old == null || old.minute() != minute ? new Window(minute, new AtomicInteger()) : old);
        if (w.count().incrementAndGet() > perMinute) {
            res.setStatus(429);
            res.setContentType("application/json");
            res.getWriter().write("{\"error\":\"too_many_requests\"}");
            return;
        }
        chain.doFilter(req, res);
    }
}
