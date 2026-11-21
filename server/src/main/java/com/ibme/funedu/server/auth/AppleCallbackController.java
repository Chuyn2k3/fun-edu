package com.ibme.funedu.server.auth;

import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Sign in with Apple on Android: Apple posts the result to this page, which
 * hands it back to the app through an Android intent (as the
 * sign_in_with_apple plugin expects). Nothing is stored here; the app then
 * sends the id token to /api/v1/auth/apple like on iOS.
 */
@RestController
public class AppleCallbackController {

    private static final String PACKAGE = "com.ibme.funedu";

    @PostMapping(path = "/api/v1/auth/apple/callback", consumes = MediaType.APPLICATION_FORM_URLENCODED_VALUE)
    public ResponseEntity<Void> callback(@RequestParam Map<String, String> form) {
        String query = form.entrySet().stream()
                .filter(e -> e.getKey().matches("code|id_token|state|user|error"))
                .map(e -> enc(e.getKey()) + "=" + enc(e.getValue()))
                .collect(Collectors.joining("&"));
        URI target = URI.create("intent://callback?" + query
                + "#Intent;package=" + PACKAGE + ";scheme=signinwithapple;end");
        HttpHeaders h = new HttpHeaders();
        h.setLocation(target);
        return new ResponseEntity<>(h, HttpStatus.SEE_OTHER);
    }

    private static String enc(String s) {
        return URLEncoder.encode(s, StandardCharsets.UTF_8);
    }
}
