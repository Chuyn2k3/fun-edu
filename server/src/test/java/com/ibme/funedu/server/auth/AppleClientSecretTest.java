package com.ibme.funedu.server.auth;

import static org.assertj.core.api.Assertions.assertThat;

import com.nimbusds.jose.crypto.ECDSAVerifier;
import com.nimbusds.jwt.SignedJWT;
import java.security.KeyPairGenerator;
import java.security.interfaces.ECPublicKey;
import java.security.spec.ECGenParameterSpec;
import java.time.Instant;
import java.util.Base64;
import org.junit.jupiter.api.Test;

class AppleClientSecretTest {

    @Test
    void isAnEs256JwtSignedWithTheAppleKey() throws Exception {
        var gen = KeyPairGenerator.getInstance("EC");
        gen.initialize(new ECGenParameterSpec("secp256r1"));
        var pair = gen.generateKeyPair();
        String pem = "-----BEGIN PRIVATE KEY-----\n"
                + Base64.getMimeEncoder().encodeToString(pair.getPrivate().getEncoded())
                + "\n-----END PRIVATE KEY-----\n";

        var secret = new AppleClientSecret("TEAM123456", "KEY1234567", pem);
        Instant now = Instant.parse("2026-11-22T08:00:00Z");
        SignedJWT jwt = SignedJWT.parse(secret.forClient("com.ibme.funedu", now));

        assertThat(jwt.verify(new ECDSAVerifier((ECPublicKey) pair.getPublic()))).isTrue();
        assertThat(jwt.getHeader().getAlgorithm().getName()).isEqualTo("ES256");
        assertThat(jwt.getHeader().getKeyID()).isEqualTo("KEY1234567");
        var c = jwt.getJWTClaimsSet();
        assertThat(c.getIssuer()).isEqualTo("TEAM123456");
        assertThat(c.getSubject()).isEqualTo("com.ibme.funedu");
        assertThat(c.getAudience()).containsExactly("https://appleid.apple.com");
        assertThat(c.getIssueTime().toInstant()).isEqualTo(now);
        assertThat(c.getExpirationTime().toInstant()).isEqualTo(now.plusSeconds(300));
    }

    @Test
    void tokenCipherRoundTripsAndHidesThePlainText() {
        var cipher = new TokenCipher("test-secret-that-is-at-least-32-bytes-long!!");
        String sealed = cipher.seal("apple-refresh-token");
        assertThat(sealed).doesNotContain("apple-refresh-token");
        assertThat(cipher.open(sealed)).isEqualTo("apple-refresh-token");
        // Fresh IV every time.
        assertThat(cipher.seal("apple-refresh-token")).isNotEqualTo(sealed);
    }
}
