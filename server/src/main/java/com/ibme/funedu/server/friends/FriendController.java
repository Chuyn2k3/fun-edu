package com.ibme.funedu.server.friends;

import com.ibme.funedu.server.auth.AuthService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/friends")
public class FriendController {

    public record RedeemRequest(@NotBlank @Size(max = 32) String code) {}

    private final AuthService auth;
    private final FriendCodeService codes;
    private final FriendService friends;

    public FriendController(AuthService auth, FriendCodeService codes, FriendService friends) {
        this.auth = auth;
        this.codes = codes;
        this.friends = friends;
    }

    @PostMapping("/code")
    public FriendCodeService.FriendCode createCode(@AuthenticationPrincipal Jwt token) {
        AuthService.Parent parent = auth.currentParent(token);
        return codes.createCode(parent.familyId());
    }

    @PostMapping("/redeem")
    public FriendService.RedeemResult redeem(
            @AuthenticationPrincipal Jwt token,
            @Valid @RequestBody RedeemRequest req) {
        AuthService.Parent parent = auth.currentParent(token);
        return friends.redeem(parent.familyId(), req.code());
    }

    @GetMapping("")
    public List<FriendService.FriendDto> list(@AuthenticationPrincipal Jwt token) {
        AuthService.Parent parent = auth.currentParent(token);
        return friends.listFriends(parent.familyId());
    }

    @DeleteMapping("/{familyId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void remove(
            @AuthenticationPrincipal Jwt token,
            @PathVariable UUID familyId) {
        AuthService.Parent parent = auth.currentParent(token);
        friends.remove(parent.familyId(), familyId);
    }
}
