package com.ibme.funedu.server.auth;

import java.util.Map;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;

@Configuration(proxyBeanMethods = false)
public class AuthConfig {

    /** Google and Apple keys are fetched (and cached) from their JWKS URLs. */
    @Bean
    IdTokenDecoders idTokenDecoders(AuthProperties props) {
        return new IdTokenDecoders(Map.of(
                "google", IdTokenDecoders.validated(
                        NimbusJwtDecoder.withJwkSetUri(props.google().jwksUri()).build(), props.google()),
                "apple", IdTokenDecoders.validated(
                        NimbusJwtDecoder.withJwkSetUri(props.apple().jwksUri()).build(), props.apple())));
    }

    /** API requests carry FunEdu access tokens only. */
    @Bean
    JwtDecoder jwtDecoder(TokenService tokens) {
        return tokens.accessTokenDecoder();
    }
}
