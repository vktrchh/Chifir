package ru.chifir.backend.user.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record UserProfileResponse(
        UUID id,
        String email,
        String username,
        String displayName,
        String avatarUrl,
        String bio,
        String role,
        LocalDateTime createdAt
) {
}