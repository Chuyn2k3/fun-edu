package com.ibme.funedu.server.auth;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

/**
 * The "Sign in with Apple" key used to talk to Apple's token endpoints
 * (exchange the authorization code, revoke on account deletion). All from
 * the environment; without them those calls are skipped.
 */
@ConfigurationProperties("funedu.apple")
public record AppleProperties(
        String teamId,
        String keyId,
        /** Contents of the .p8 key (PKCS#8 PEM). */
        String privateKey,
        @DefaultValue("https://appleid.apple.com/auth/token") String tokenUrl,
        @DefaultValue("https://appleid.apple.com/auth/revoke") String revokeUrl) {

    public boolean configured() {
        return notBlank(teamId) && notBlank(keyId) && notBlank(privateKey);
    }

    private static boolean notBlank(String s) {
        return s != null && !s.isBlank();
    }
}
