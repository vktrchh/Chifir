package com.chifir.controller;

import com.chifir.dto.AuthResponse;
import com.chifir.dto.LoginRequest;
import org.springframework.web.bind.annotation.*;
import com.chifir.dto.http.ResponseEntity;

@RestController
@RequestMapping("/api/auth")
public class ApiMockController {

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody LoginRequest request) {
        System.out.println("Login attempt: " + request.getEmail());

        if ("test@example.com".equals(request.getEmail()) &&
                "password123".equals(request.getPassword())) {
            return ResponseEntity.ok(new AuthResponse(true, "Успешный вход", "mock-jwt-token-123"));
        }

        return ResponseEntity.badRequest()
                .body(new AuthResponse(false, "Неверный email или пароль", null));
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@RequestBody RegisterRequest request) {
        System.out.println("Register: " + request.getEmail());

        if (!request.getPassword().equals(request.getConfirmPassword())) {
            return ResponseEntity.badRequest()
                    .body(new AuthResponse(false, "Пароли не совпадают", null));
        }

        return ResponseEntity.ok(new AuthResponse(true, "Аккаунт создан", "mock-token-for-new-user"));
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentUser(@RequestHeader(value = "Authorization", required = false) String token) {
        if (token == null || token.isEmpty()) {
            return ResponseEntity.status(401).body(new AuthResponse(false, "Не авторизован", null));
        }
        return ResponseEntity.ok(new AuthResponse(true, "Авторизован", token));
    }
}