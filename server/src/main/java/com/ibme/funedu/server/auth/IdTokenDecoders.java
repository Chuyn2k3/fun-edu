package com.ibme.funedu.server.auth;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;

/** Verifies Google / Apple id tokens: signature, issuer, audience, expiry. */
public class IdTokenDecoders {

    private static final org.slf4j.Logger log = org.slf4j.LoggerFactory.getLogger(IdTokenDecoders.class);

    private final Map<String, NimbusJwtDecoder> byProvider;

    public IdTokenDecoders(Map<String, NimbusJwtDecoder> byProvider) {
        this.byProvider = Map.copyOf(byProvider);
    }

    public boolean supports(String provider) {
        return byProvider.containsKey(provider);
    }

    public Jwt decode(String provider, String idToken) {
        NimbusJwtDecoder decoder = byProvider.get(provider);
        if (decoder == null) throw new AuthFailedException("unknown provider");
        try {
            Jwt jwt = decoder.decode(idToken);
            if (jwt.getSubject() == null || jwt.getSubject().isBlank() || jwt.getSubject().length() > 255) {
                throw new AuthFailedException("bad subject");
            }
            return jwt;
        } catch (JwtException e) {
            // The reason only ("bad aud", "expired", "no matching key"),
            // never the token: tells a developer which setting is wrong.
            log.info("Rejected {} id token: {}", provider, e.getMessage());
            throw new AuthFailedException("bad id token");
        }
    }

    /** Applies the provider's issuer, audience and expiry rules to [decoder]. */
    public static NimbusJwtDecoder validated(NimbusJwtDecoder decoder, AuthProperties.Provider p) {
        decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(List.of(
                new JwtTimestampValidator(Duration.ofSeconds(60)),
                claim("iss", jwt -> jwt.getIssuer() != null && p.issuers().contains(jwt.getIssuer().toString())),
                // No configured client id means nobody may sign in (fail closed).
                claim("aud", jwt -> jwt.getAudience() != null
                        && jwt.getAudience().stream().anyMatch(p.clientIds()::contains)))));
        return decoder;
    }

    private static OAuth2TokenValidator<Jwt> claim(String name, java.util.function.Predicate<Jwt> ok) {
        OAuth2Error error = new OAuth2Error("invalid_token", "bad " + name, null);
        return jwt -> ok.test(jwt) ? OAuth2TokenValidatorResult.success() : OAuth2TokenValidatorResult.failure(error);
    }
}
