package com.ibme.funedu.server.web;

import com.ibme.funedu.server.auth.AuthFailedException;
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

    @ExceptionHandler({MethodArgumentNotValidException.class, HttpMessageNotReadableException.class})
    ResponseEntity<Map<String, String>> badRequest() {
        return ResponseEntity.badRequest().body(Map.of("error", "bad_request"));
    }
}
