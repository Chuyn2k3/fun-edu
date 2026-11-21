package com.ibme.funedu.server.room;

import com.ibme.funedu.server.auth.AuthService;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class RoomController {

    private final AuthService auth;
    private final RoomRegistry rooms;

    public RoomController(AuthService auth, RoomRegistry rooms) {
        this.auth = auth;
        this.rooms = rooms;
    }

    /** A parent opens a room; its code is shared with another parent. */
    @PostMapping("/api/v1/rooms")
    public ResponseEntity<Map<String, Object>> create(@AuthenticationPrincipal Jwt token) {
        AuthService.Parent parent = auth.currentParent(token);
        try {
            Room room = rooms.create(parent.familyId());
            return ResponseEntity.ok(Map.of("code", room.code, "expiresAt", room.expiresAt().toEpochMilli()));
        } catch (RoomRegistry.TooManyRooms e) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS).body(Map.of("error", "too_many_requests"));
        }
    }
}
