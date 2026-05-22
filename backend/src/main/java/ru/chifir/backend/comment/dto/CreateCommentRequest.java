package ru.chifir.backend.comment.dto;

import jakarta.validation.constraints.NotBlank;

public record CreateCommentRequest(
        @NotBlank(message = "Текст комментария обязателен")
        String content
) {
}