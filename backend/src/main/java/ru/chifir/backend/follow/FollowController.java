package ru.chifir.backend.follow;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class FollowController {

    private final FollowService followService;

    @PostMapping("/{targetUserId}/follow")
    public Map<String, Object> follow(
            @PathVariable UUID targetUserId,
            @RequestParam UUID followerId
    ) {
        return followService.follow(targetUserId, followerId);
    }

    @DeleteMapping("/{targetUserId}/follow")
    public Map<String, Object> unfollow(
            @PathVariable UUID targetUserId,
            @RequestParam UUID followerId
    ) {
        return followService.unfollow(targetUserId, followerId);
    }

    @GetMapping("/{targetUserId}/follow/check")
    public Map<String, Object> check(
            @PathVariable UUID targetUserId,
            @RequestParam UUID followerId
    ) {
        return followService.check(targetUserId, followerId);
    }

    @GetMapping("/{userId}/followers")
    public List<Map<String, Object>> getFollowers(@PathVariable UUID userId) {
        return followService.getFollowers(userId);
    }

    @GetMapping("/{userId}/following")
    public List<Map<String, Object>> getFollowing(@PathVariable UUID userId) {
        return followService.getFollowing(userId);
    }
}