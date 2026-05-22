package ru.chifir.backend.comment.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record CommentResponse(
        UUID id,
        UUID postId,
        UUID authorId,
        String authorUsername,
        String authorDisplayName,
        String content,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}