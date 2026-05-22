package ru.chifir.backend.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @Email(message = "Некорректный email")
        @NotBlank(message = "Email обязателен")
        String email,

        @NotBlank(message = "Username обязателен")
        @Size(min = 3, max = 50, message = "Username должен быть от 3 до 50 символов")
        String username,

        @NotBlank(message = "Пароль обязателен")
        @Size(min = 6, max = 100, message = "Пароль должен быть от 6 до 100 символов")
        String password,

        @Size(max = 100, message = "Отображаемое имя не длиннее 100 символов")
        String displayName
) {
}