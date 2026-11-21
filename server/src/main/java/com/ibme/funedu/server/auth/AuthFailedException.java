package com.ibme.funedu.server.auth;

/** Any sign-in or session failure; always answered with a bare 401. */
public class AuthFailedException extends RuntimeException {
    public AuthFailedException(String reason) {
        super(reason, null, false, false);
    }
}
