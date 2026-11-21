package com.ibme.funedu.server.auth;

import java.time.Duration;
import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/** Sign-in settings; secrets come from the environment, never from git. */
@ConfigurationProperties("funedu.auth")
public record AuthProperties(
        String jwtSecret,
        Duration accessTtl,
        Duration refreshTtl,
        int requestsPerMinute,
        Provider google,
        Provider apple) {

    public AuthProperties {
        if (jwtSecret == null || jwtSecret.getBytes(java.nio.charset.StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException("funedu.auth.jwt-secret (AUTH_JWT_SECRET) must be at least 32 bytes");
        }
    }

    /** One identity provider: who may issue tokens and for which app client ids. */
    public record Provider(List<String> issuers, String jwksUri, List<String> clientIds) {
        public Provider {
            issuers = issuers == null ? List.of() : List.copyOf(issuers);
            clientIds = clientIds == null ? List.of() : clientIds.stream().filter(s -> !s.isBlank()).toList();
        }
    }
}
