package com.ibme.funedu.server.auth;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.NotNull;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1")
public class AuthController {

    /** [authorizationCode]: Apple only, optional (lets deletion revoke Apple's token). */
    public record SignInRequest(
            @NotBlank @Size(max = 8192) String idToken,
            @Size(max = 2048) String authorizationCode,
            @NotNull UUID deviceId) {}

    public record RefreshRequest(@NotBlank @Size(max = 256) String refreshToken) {}

    public record MeResponse(UUID familyId, String provider, String email) {}

    private final AuthService auth;

    public AuthController(AuthService auth) {
        this.auth = auth;
    }

    @PostMapping("/auth/{provider}")
    public ResponseEntity<?> signIn(@PathVariable String provider, @Valid @RequestBody SignInRequest req) {
        if (!auth.supports(provider)) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "not_found"));
        }
        return ResponseEntity.ok(auth.signIn(provider, req.idToken(), req.authorizationCode(), req.deviceId()));
    }

    @PostMapping("/auth/refresh")
    public AuthService.Session refresh(@Valid @RequestBody RefreshRequest req) {
        return auth.refresh(req.refreshToken());
    }

    @PostMapping("/auth/logout")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void logout(@Valid @RequestBody RefreshRequest req) {
        auth.logout(req.refreshToken());
    }

    @GetMapping("/me")
    public MeResponse me(@AuthenticationPrincipal Jwt token) {
        AuthService.Parent p = auth.currentParent(token);
        return new MeResponse(p.familyId(), p.provider(), p.email());
    }

    /** Required by both stores: parents can delete their account from the app. */
    @DeleteMapping("/account")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteAccount(@AuthenticationPrincipal Jwt token) {
        auth.deleteAccount(auth.currentParent(token));
    }
}
