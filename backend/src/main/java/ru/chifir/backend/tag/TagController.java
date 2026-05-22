package ru.chifir.backend.tag;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import ru.chifir.backend.post.dto.PostResponse;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class TagController {

    private final TagService tagService;

    @PostMapping("/api/posts/{postId}/tags")
    public Map<String, Object> addTagToPost(
            @PathVariable UUID postId,
            @RequestParam String name
    ) {
        return tagService.addTagToPost(postId, name);
    }

    @GetMapping("/api/posts/{postId}/tags")
    public List<String> getPostTags(@PathVariable UUID postId) {
        return tagService.getPostTags(postId);
    }

    @DeleteMapping("/api/posts/{postId}/tags")
    public Map<String, Object> removeTagFromPost(
            @PathVariable UUID postId,
            @RequestParam String name
    ) {
        return tagService.removeTagFromPost(postId, name);
    }

    @GetMapping("/api/tags/{name}/posts")
    public List<PostResponse> getPostsByTag(@PathVariable String name) {
        return tagService.getPostsByTag(name);
    }
}