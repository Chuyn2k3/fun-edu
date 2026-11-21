package com.ibme.funedu.server.auth;

import com.nimbusds.jose.jwk.source.ImmutableSecret;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.UUID;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.stereotype.Component;

/** FunEdu's own short-lived access tokens and opaque refresh tokens. */
@Component
public class TokenService {

    public static final String ISSUER = "funedu";
    public static final String FAMILY_CLAIM = "fam";

    private final SecretKey key;
    private final NimbusJwtEncoder encoder;
    private final AuthProperties props;
    private final SecureRandom random = new SecureRandom();

    public TokenService(AuthProperties props) {
        this.props = props;
        this.key = new SecretKeySpec(props.jwtSecret().getBytes(StandardCharsets.UTF_8), "HmacSHA256");
        this.encoder = new NimbusJwtEncoder(new ImmutableSecret<>(key));
    }

    public String accessToken(UUID parentId, UUID familyId) {
        Instant now = Instant.now();
        var claims = JwtClaimsSet.builder()
                .issuer(ISSUER)
                .audience(List.of(ISSUER))
                .subject(parentId.toString())
                .claim(FAMILY_CLAIM, familyId.toString())
                .issuedAt(now)
                .expiresAt(now.plus(props.accessTtl()))
                .build();
        return encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims))
                .getTokenValue();
    }

    /** Decoder for API requests: only our HS256 tokens, our issuer and audience. */
    public JwtDecoder accessTokenDecoder() {
        NimbusJwtDecoder d = NimbusJwtDecoder.withSecretKey(key).macAlgorithm(MacAlgorithm.HS256).build();
        d.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                JwtValidators.createDefaultWithIssuer(ISSUER),
                jwt -> jwt.getAudience() != null && jwt.getAudience().contains(ISSUER)
                        ? org.springframework.security.oauth2.core.OAuth2TokenValidatorResult.success()
                        : org.springframework.security.oauth2.core.OAuth2TokenValidatorResult.failure(
                                new org.springframework.security.oauth2.core.OAuth2Error("invalid_token"))));
        return d;
    }

    /** 256 random bits, URL-safe; only its hash is ever stored. */
    public String newRefreshToken() {
        byte[] bytes = new byte[32];
        random.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public static byte[] hash(String refreshToken) {
        try {
            return MessageDigest.getInstance("SHA-256").digest(refreshToken.getBytes(StandardCharsets.UTF_8));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }
}
