package com.ibme.funedu.server.auth;

import com.fasterxml.jackson.databind.JsonNode;
import java.time.Clock;
import java.time.Duration;
import java.util.Optional;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.web.client.RestClient;

@Component
public class HttpAppleTokenApi implements AppleTokenApi {

    private final AppleProperties props;
    private final RestClient http;
    private final Clock clock = Clock.systemUTC();
    private volatile AppleClientSecret secret;

    public HttpAppleTokenApi(AppleProperties props) {
        this.props = props;
        var factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout((int) Duration.ofSeconds(5).toMillis());
        factory.setReadTimeout((int) Duration.ofSeconds(5).toMillis());
        this.http = RestClient.builder().requestFactory(factory).build();
    }

    private String clientSecret(String clientId) {
        if (secret == null) {
            secret = new AppleClientSecret(props.teamId(), props.keyId(), props.privateKey());
        }
        return secret.forClient(clientId, clock.instant());
    }

    @Override
    public Optional<String> exchange(String clientId, String code) {
        var form = new LinkedMultiValueMap<String, String>();
        form.add("client_id", clientId);
        form.add("client_secret", clientSecret(clientId));
        form.add("code", code);
        form.add("grant_type", "authorization_code");
        JsonNode res = http.post().uri(props.tokenUrl())
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .body(form).retrieve().body(JsonNode.class);
        return Optional.ofNullable(res).map(r -> r.path("refresh_token").asText(null));
    }

    @Override
    public void revoke(String clientId, String refreshToken) {
        var form = new LinkedMultiValueMap<String, String>();
        form.add("client_id", clientId);
        form.add("client_secret", clientSecret(clientId));
        form.add("token", refreshToken);
        form.add("token_type_hint", "refresh_token");
        http.post().uri(props.revokeUrl())
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .body(form).retrieve().toBodilessEntity();
    }
}
