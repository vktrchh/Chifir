package ru.chifir.backend.post.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record PostResponse(
        UUID id,
        UUID authorId,
        String authorUsername,
        String authorDisplayName,
        String content,
        String imageUrl,
        UUID originalPostId,
        long likesCount,
        long reblogsCount,
        long commentsCount,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
}