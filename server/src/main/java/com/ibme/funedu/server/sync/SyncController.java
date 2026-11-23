package com.ibme.funedu.server.sync;

import com.ibme.funedu.server.auth.AuthService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class SyncController {

    public record SyncRequest(@Min(0) long since, @NotNull List<SyncService.Change> changes) {}

    private final AuthService auth;
    private final SyncService sync;
    private final DeviceLinkService linkService;

    public SyncController(AuthService auth, SyncService sync, DeviceLinkService linkService) {
        this.auth = auth;
        this.sync = sync;
        this.linkService = linkService;
    }

    /** The family comes from the token, never from the request body. */
    @PostMapping("/api/v1/sync")
    public SyncService.Result sync(@AuthenticationPrincipal Jwt token, @Valid @RequestBody SyncRequest req) {
        AuthService.Parent parent = auth.currentParent(token);
        if (!req.changes().isEmpty()) {
            UUID deviceId = DeviceLinkService.deviceIdOf(token);
            if (deviceId == null || !linkService.isLinked(parent.familyId(), deviceId)) {
                throw new DeviceLinkService.LinkRequiredException();
            }
        }
        return sync.sync(parent.familyId(), req.since(), req.changes());
    }
}
