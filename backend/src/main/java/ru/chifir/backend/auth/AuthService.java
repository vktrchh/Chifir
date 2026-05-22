package ru.chifir.backend.auth;

import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import ru.chifir.backend.auth.dto.AuthResponse;
import ru.chifir.backend.auth.dto.LoginRequest;
import ru.chifir.backend.auth.dto.RegisterRequest;
import ru.chifir.backend.user.Role;
import ru.chifir.backend.user.User;
import ru.chifir.backend.user.UserRepository;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.email())) {
            throw new IllegalArgumentException("Пользователь с таким email уже существует");
        }

        if (userRepository.existsByUsername(request.username())) {
            throw new IllegalArgumentException("Пользователь с таким username уже существует");
        }

        User user = new User();
        user.setEmail(request.email());
        user.setUsername(request.username());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setDisplayName(request.displayName());
        user.setRole(Role.USER);
        user.setEnabled(true);
        user.setDeleted(false);

        User savedUser = userRepository.save(user);

        return toAuthResponse(savedUser);
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.login())
                .or(() -> userRepository.findByUsername(request.login()))
                .orElseThrow(() -> new IllegalArgumentException("Неверный логин или пароль"));

        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Неверный логин или пароль");
        }

        if (!user.isEnabled() || user.isDeleted()) {
            throw new IllegalArgumentException("Пользователь заблокирован или удалён");
        }

        return toAuthResponse(user);
    }

    private AuthResponse toAuthResponse(User user) {
        return new AuthResponse(
                user.getId(),
                user.getEmail(),
                user.getUsername(),
                user.getDisplayName(),
                user.getRole().name()
        );
    }
}