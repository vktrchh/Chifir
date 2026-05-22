package ru.chifir.backend.comment;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import ru.chifir.backend.comment.dto.CommentResponse;
import ru.chifir.backend.comment.dto.CreateCommentRequest;

import java.util.List;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class CommentController {

    private final CommentService commentService;

    @PostMapping("/api/posts/{postId}/comments")
    public CommentResponse create(
            @PathVariable UUID postId,
            @RequestParam UUID userId,
            @Valid @RequestBody CreateCommentRequest request
    ) {
        return commentService.create(postId, userId, request);
    }

    @GetMapping("/api/posts/{postId}/comments")
    public List<CommentResponse> getByPost(@PathVariable UUID postId) {
        return commentService.getByPost(postId);
    }

    @DeleteMapping("/api/comments/{commentId}")
    public void delete(@PathVariable UUID commentId) {
        commentService.delete(commentId);
    }
}