package com.ibme.funedu.server.sync;

import com.ibme.funedu.server.auth.AuthService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/sync")
public class DeviceLinkController {

    public record LinkRequest(@NotBlank String mode) {}

    private final AuthService auth;
    private final DeviceLinkService linkService;
    private final AccountSummary accountSummary;

    public DeviceLinkController(AuthService auth, DeviceLinkService linkService, AccountSummary accountSummary) {
        this.auth = auth;
        this.linkService = linkService;
        this.accountSummary = accountSummary;
    }

    @PostMapping("/link")
    public ResponseEntity<?> link(@AuthenticationPrincipal Jwt token, @Valid @RequestBody LinkRequest req) {
        AuthService.Parent parent = auth.currentParent(token);
        UUID deviceId = DeviceLinkService.deviceIdOf(token);
        if (deviceId == null) {
            throw new DeviceLinkService.LinkRequiredException();
        }
        DeviceLinkService.LinkResult res = linkService.link(parent.familyId(), deviceId, req.mode());
        return ResponseEntity.ok(res);
    }

    @GetMapping("/link")
    public ResponseEntity<?> getLink(@AuthenticationPrincipal Jwt token) {
        AuthService.Parent parent = auth.currentParent(token);
        UUID deviceId = DeviceLinkService.deviceIdOf(token);
        boolean linked = deviceId != null && linkService.isLinked(parent.familyId(), deviceId);
        AccountSummary.Result account = accountSummary.of(parent.familyId());
        return ResponseEntity.ok(Map.of("linked", linked, "account", account));
    }
}
