package com.ibme.funedu.server.auth;

import com.nimbusds.jose.jwk.JWKSet;
import com.nimbusds.jose.jwk.RSAKey;
import com.nimbusds.jose.jwk.source.ImmutableJWKSet;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.interfaces.RSAPrivateKey;
import java.security.interfaces.RSAPublicKey;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.security.oauth2.jose.jws.SignatureAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;

/**
 * Stands in for Google's and Apple's signing keys: tests mint id tokens with
 * these keys and the server verifies them with the real validation rules.
 */
@TestConfiguration(proxyBeanMethods = false)
public class TestIdTokens {

    public static final KeyPair GOOGLE = rsa();
    public static final KeyPair APPLE = rsa();
    /** A key neither provider uses: tokens it signs must be rejected. */
    public static final KeyPair ROGUE = rsa();

    public static final String GOOGLE_CLIENT = "test-google-client";
    public static final String APPLE_CLIENT = "com.ibme.funedu";

    @Bean
    @Primary
    IdTokenDecoders testIdTokenDecoders(AuthProperties props) {
        return new IdTokenDecoders(Map.of(
                "google", IdTokenDecoders.validated(
                        NimbusJwtDecoder.withPublicKey((RSAPublicKey) GOOGLE.getPublic()).build(), props.google()),
                "apple", IdTokenDecoders.validated(
                        NimbusJwtDecoder.withPublicKey((RSAPublicKey) APPLE.getPublic()).build(), props.apple())));
    }

    public static String googleToken(String subject) {
        return sign(GOOGLE, "https://accounts.google.com", GOOGLE_CLIENT, subject, Instant.now().plusSeconds(600));
    }

    public static String appleToken(String subject) {
        return sign(APPLE, "https://appleid.apple.com", APPLE_CLIENT, subject, Instant.now().plusSeconds(600));
    }

    public static String randomSubject() {
        return "sub-" + UUID.randomUUID();
    }

    public static String sign(KeyPair key, String issuer, String audience, String subject, Instant expiresAt) {
        RSAKey jwk = new RSAKey.Builder((RSAPublicKey) key.getPublic())
                .privateKey((RSAPrivateKey) key.getPrivate())
                .keyID("test")
                .build();
        var encoder = new NimbusJwtEncoder(new ImmutableJWKSet<>(new JWKSet(jwk)));
        var claims = JwtClaimsSet.builder()
                .issuer(issuer)
                .audience(java.util.List.of(audience))
                .subject(subject)
                .issuedAt(expiresAt.minusSeconds(1200))
                .expiresAt(expiresAt)
                .claim("email", subject + "@example.com")
                .build();
        var header = JwsHeader.with(SignatureAlgorithm.RS256).keyId("test").build();
        return encoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }

    private static KeyPair rsa() {
        try {
            var gen = KeyPairGenerator.getInstance("RSA");
            gen.initialize(2048);
            return gen.generateKeyPair();
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }
}
