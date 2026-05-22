package ru.chifir.backend.feed;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import ru.chifir.backend.post.dto.PostResponse;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/feed")
@RequiredArgsConstructor
public class FeedController {

    private final FeedService feedService;

    @GetMapping("/following/{userId}")
    public List<PostResponse> getFollowingFeed(@PathVariable UUID userId) {
        return feedService.getFollowingFeed(userId);
    }
}