package ru.chifir.backend.user;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import ru.chifir.backend.user.dto.UpdateUserRequest;
import ru.chifir.backend.user.dto.UserProfileResponse;

import java.util.UUID;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/{id}")
    public UserProfileResponse getById(@PathVariable UUID id) {
        return userService.getById(id);
    }

    @PatchMapping("/{id}")
    public UserProfileResponse update(
            @PathVariable UUID id,
            @Valid @RequestBody UpdateUserRequest request
    ) {
        return userService.update(id, request);
    }
}