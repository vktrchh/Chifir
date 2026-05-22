package ru.chifir.backend.post;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import ru.chifir.backend.post.dto.CreatePostRequest;
import ru.chifir.backend.post.dto.PostResponse;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/posts")
@RequiredArgsConstructor
public class PostController {

    private final PostService postService;

    @PostMapping
    public PostResponse create(@Valid @RequestBody CreatePostRequest request) {
        return postService.create(request);
    }

    @GetMapping
    public List<PostResponse> getFeed() {
        return postService.getFeed();
    }

    @GetMapping("/{id}")
    public PostResponse getById(@PathVariable UUID id) {
        return postService.getById(id);
    }

    @GetMapping("/by-author/{authorId}")
    public List<PostResponse> getByAuthor(@PathVariable UUID authorId) {
        return postService.getByAuthor(authorId);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable UUID id) {
        postService.delete(id);
    }
}