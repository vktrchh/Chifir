package ru.chifir.backend.like;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/posts/{postId}/likes")
@RequiredArgsConstructor
public class LikeController {

    private final LikeService likeService;

    @PostMapping
    public Map<String, Object> like(
            @PathVariable UUID postId,
            @RequestParam UUID userId
    ) {
        return likeService.like(postId, userId);
    }

    @DeleteMapping
    public Map<String, Object> unlike(
            @PathVariable UUID postId,
            @RequestParam UUID userId
    ) {
        return likeService.unlike(postId, userId);
    }

    @GetMapping("/check")
    public Map<String, Object> check(
            @PathVariable UUID postId,
            @RequestParam UUID userId
    ) {
        return likeService.check(postId, userId);
    }
}