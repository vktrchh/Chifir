package ru.chifir.backend.user;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.chifir.backend.user.dto.UpdateUserRequest;
import ru.chifir.backend.user.dto.UserProfileResponse;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public UserProfileResponse getById(UUID id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));

        if (user.isDeleted()) {
            throw new IllegalArgumentException("Пользователь не найден");
        }

        return toResponse(user);
    }

    @Transactional
    public UserProfileResponse update(UUID id, UpdateUserRequest request) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));

        if (user.isDeleted()) {
            throw new IllegalArgumentException("Пользователь не найден");
        }

        if (request.displayName() != null) {
            user.setDisplayName(request.displayName());
        }

        if (request.avatarUrl() != null) {
            user.setAvatarUrl(request.avatarUrl());
        }

        if (request.bio() != null) {
            user.setBio(request.bio());
        }

        return toResponse(userRepository.save(user));
    }

    private UserProfileResponse toResponse(User user) {
        return new UserProfileResponse(
                user.getId(),
                user.getEmail(),
                user.getUsername(),
                user.getDisplayName(),
                user.getAvatarUrl(),
                user.getBio(),
                user.getRole().name(),
                user.getCreatedAt()
        );
    }
}