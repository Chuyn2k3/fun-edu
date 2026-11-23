package com.ibme.funedu.server.friends;

import com.fasterxml.jackson.databind.node.ObjectNode;
import com.ibme.funedu.server.auth.AuthService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/showcase")
public class ShowcaseController {

    public record ReactRequest(@NotBlank String kind) {}

    private final AuthService auth;
    private final ShowcaseService showcases;

    public ShowcaseController(AuthService auth, ShowcaseService showcases) {
        this.auth = auth;
        this.showcases = showcases;
    }

    @PutMapping("/{kidUuid}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void put(
            @AuthenticationPrincipal Jwt token,
            @PathVariable String kidUuid,
            @RequestBody(required = false) byte[] rawBody) {
        AuthService.Parent parent = auth.currentParent(token);
        showcases.put(parent.familyId(), kidUuid, rawBody);
    }

    @GetMapping("/{familyId}/{kidUuid}")
    public ObjectNode get(
            @AuthenticationPrincipal Jwt token,
            @PathVariable UUID familyId,
            @PathVariable String kidUuid) {
        AuthService.Parent parent = auth.currentParent(token);
        return showcases.get(parent.familyId(), familyId, kidUuid);
    }

    @PostMapping("/{familyId}/{kidUuid}/react")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void react(
            @AuthenticationPrincipal Jwt token,
            @PathVariable UUID familyId,
            @PathVariable String kidUuid,
            @Valid @RequestBody ReactRequest req) {
        AuthService.Parent parent = auth.currentParent(token);
        showcases.react(parent.familyId(), familyId, kidUuid, req.kind());
    }
}
