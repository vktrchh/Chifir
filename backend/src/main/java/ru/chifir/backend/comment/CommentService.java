package ru.chifir.backend.comment;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.chifir.backend.comment.dto.CommentResponse;
import ru.chifir.backend.comment.dto.CreateCommentRequest;
import ru.chifir.backend.post.Post;
import ru.chifir.backend.post.PostRepository;
import ru.chifir.backend.user.User;
import ru.chifir.backend.user.UserRepository;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CommentService {

    private final CommentRepository commentRepository;
    private final PostRepository postRepository;
    private final UserRepository userRepository;

    @Transactional
    public CommentResponse create(UUID postId, UUID userId, CreateCommentRequest request) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Пост не найден"));

        if (post.isDeleted() || post.isHidden()) {
            throw new IllegalArgumentException("Пост не найден");
        }

        User author = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));

        Comment comment = new Comment();
        comment.setPost(post);
        comment.setAuthor(author);
        comment.setContent(request.content());

        Comment savedComment = commentRepository.save(comment);

        post.setCommentsCount(post.getCommentsCount() + 1);
        postRepository.save(post);

        return toResponse(savedComment);
    }

    @Transactional(readOnly = true)
    public List<CommentResponse> getByPost(UUID postId) {
        return commentRepository.findByPostIdAndDeletedFalseOrderByCreatedAtDesc(postId)
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public void delete(UUID commentId) {
        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new IllegalArgumentException("Комментарий не найден"));

        if (!comment.isDeleted()) {
            comment.setDeleted(true);

            Post post = comment.getPost();
            if (post.getCommentsCount() > 0) {
                post.setCommentsCount(post.getCommentsCount() - 1);
                postRepository.save(post);
            }

            commentRepository.save(comment);
        }
    }

    private CommentResponse toResponse(Comment comment) {
        return new CommentResponse(
                comment.getId(),
                comment.getPost().getId(),
                comment.getAuthor().getId(),
                comment.getAuthor().getUsername(),
                comment.getAuthor().getDisplayName(),
                comment.getContent(),
                comment.getCreatedAt(),
                comment.getUpdatedAt()
        );
    }
}