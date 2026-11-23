package com.ibme.funedu.server.web;

import com.ibme.funedu.server.auth.AuthFailedException;
import com.ibme.funedu.server.sync.DeviceLinkService;
import com.ibme.funedu.server.sync.SyncService;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/** Errors carry a code only: no messages, no stack traces, no internals. */
@RestControllerAdvice
public class ApiErrors {

    @ExceptionHandler(AuthFailedException.class)
    ResponseEntity<Map<String, String>> unauthorized() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "unauthorized"));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    ResponseEntity<Map<String, String>> notReadable(HttpMessageNotReadableException ex) {
        Throwable t = ex;
        while (t != null) {
            if (t instanceof RequestSizeLimitFilter.PayloadTooLargeException) {
                return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE).body(Map.of("error", "too_large"));
            }
            t = t.getCause();
        }
        return ResponseEntity.badRequest().body(Map.of("error", "bad_request"));
    }

    @ExceptionHandler({MethodArgumentNotValidException.class,
            SyncService.BadSyncRequest.class, DeviceLinkService.BadModeException.class})
    ResponseEntity<Map<String, String>> badRequest() {
        return ResponseEntity.badRequest().body(Map.of("error", "bad_request"));
    }

    @ExceptionHandler(DeviceLinkService.LinkRequiredException.class)
    ResponseEntity<Map<String, String>> linkRequired() {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("error", "link_required"));
    }

    @ExceptionHandler(DeviceLinkService.AccountNotEmptyException.class)
    ResponseEntity<Map<String, Object>> accountNotEmpty(DeviceLinkService.AccountNotEmptyException e) {
        return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of(
                "error", "account_not_empty",
                "account", e.account()));
    }
}
