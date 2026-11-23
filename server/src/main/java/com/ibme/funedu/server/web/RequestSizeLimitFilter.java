package com.ibme.funedu.server.web;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Rejects request bodies larger than 4 MB with HTTP 413 before they reach controllers,
 * both when Content-Length is declared and when streamed/chunked without Content-Length.
 */
@Component
public class RequestSizeLimitFilter extends OncePerRequestFilter {

    public static final int MAX_BYTES = 4 * 1024 * 1024;

    public static class PayloadTooLargeException extends IOException {
        PayloadTooLargeException() {
            super("too_large");
        }
    }

    @Override
    protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
            throws ServletException, IOException {
        long declared = req.getContentLengthLong();
        if (declared > MAX_BYTES) {
            writeTooLarge(res);
            return;
        }
        LimitedRequest wrapped = new LimitedRequest(req, MAX_BYTES);
        try {
            chain.doFilter(wrapped, res);
        } catch (PayloadTooLargeException e) {
            if (!res.isCommitted()) {
                writeTooLarge(res);
                return;
            }
            throw e;
        }
        if (wrapped.exceeded && !res.isCommitted()) {
            writeTooLarge(res);
        }
    }

    static void writeTooLarge(HttpServletResponse res) throws IOException {
        res.setStatus(HttpStatus.PAYLOAD_TOO_LARGE.value());
        res.setContentType("application/json");
        res.getWriter().write("{\"error\":\"too_large\"}");
    }

    private static final class LimitedRequest extends HttpServletRequestWrapper {
        private final long maxBytes;
        volatile boolean exceeded;
        private ServletInputStream stream;

        LimitedRequest(HttpServletRequest request, long maxBytes) {
            super(request);
            this.maxBytes = maxBytes;
        }

        @Override
        public ServletInputStream getInputStream() throws IOException {
            if (stream == null) {
                stream = new CountingServletInputStream(super.getInputStream());
            }
            return stream;
        }

        private final class CountingServletInputStream extends ServletInputStream {
            private final ServletInputStream delegate;
            private long readBytes;

            CountingServletInputStream(ServletInputStream delegate) {
                this.delegate = delegate;
            }

            private void account(int n) throws IOException {
                if (n <= 0) return;
                readBytes += n;
                if (readBytes > maxBytes) {
                    exceeded = true;
                    throw new PayloadTooLargeException();
                }
            }

            @Override
            public int read() throws IOException {
                int b = delegate.read();
                if (b != -1) account(1);
                return b;
            }

            @Override
            public int read(byte[] b, int off, int len) throws IOException {
                int n = delegate.read(b, off, len);
                account(n);
                return n;
            }

            @Override
            public boolean isFinished() {
                return delegate.isFinished();
            }

            @Override
            public boolean isReady() {
                return delegate.isReady();
            }

            @Override
            public void setReadListener(ReadListener readListener) {
                delegate.setReadListener(readListener);
            }

            @Override
            public void close() throws IOException {
                delegate.close();
            }
        }
    }
}
