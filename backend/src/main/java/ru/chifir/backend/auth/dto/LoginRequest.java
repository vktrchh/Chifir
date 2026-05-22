package ru.chifir.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
        @NotBlank(message = "Email или username обязателен")
        String login,

        @NotBlank(message = "Пароль обязателен")
        String password
) {
}