package ru.chifir.backend.post.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public record CreatePostRequest(
        @NotNull(message = "authorId обязателен")
        UUID authorId,

        @NotBlank(message = "Текст поста обязателен")
        String content,

        String imageUrl,

        UUID originalPostId
) {
}