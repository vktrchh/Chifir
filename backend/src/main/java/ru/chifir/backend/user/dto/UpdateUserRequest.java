package ru.chifir.backend.user.dto;

import jakarta.validation.constraints.Size;

public record UpdateUserRequest(
        @Size(max = 100, message = "Отображаемое имя не длиннее 100 символов")
        String displayName,

        String avatarUrl,

        @Size(max = 1000, message = "Описание не длиннее 1000 символов")
        String bio
) {
}