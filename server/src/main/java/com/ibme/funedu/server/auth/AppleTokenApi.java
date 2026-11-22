package com.ibme.funedu.server.auth;

import java.util.Optional;

/** Apple's token endpoints, behind an interface so tests never call Apple. */
public interface AppleTokenApi {

    /** Exchanges an authorization code; returns Apple's refresh token. */
    Optional<String> exchange(String clientId, String code);

    /** Revokes a refresh token (account deletion). */
    void revoke(String clientId, String refreshToken);
}
