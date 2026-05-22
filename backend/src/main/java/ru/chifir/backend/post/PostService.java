package ru.chifir.backend.post;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.chifir.backend.post.dto.CreatePostRequest;
import ru.chifir.backend.post.dto.PostResponse;
import ru.chifir.backend.user.User;
import ru.chifir.backend.user.UserRepository;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PostService {

    private final PostRepository postRepository;
    private final UserRepository userRepository;

    @Transactional
    public PostResponse create(CreatePostRequest request) {
        User author = userRepository.findById(request.authorId())
                .orElseThrow(() -> new IllegalArgumentException("Автор не найден"));

        Post post = new Post();
        post.setAuthor(author);
        post.setContent(request.content());
        post.setImageUrl(request.imageUrl());

        if (request.originalPostId() != null) {
            Post originalPost = postRepository.findById(request.originalPostId())
                    .orElseThrow(() -> new IllegalArgumentException("Оригинальный пост не найден"));

            post.setOriginalPost(originalPost);
            originalPost.setReblogsCount(originalPost.getReblogsCount() + 1);
            postRepository.save(originalPost);
        }

        Post savedPost = postRepository.save(post);
        return toResponse(savedPost);
    }

    @Transactional(readOnly = true)
    public List<PostResponse> getFeed() {
        return postRepository.findByDeletedFalseAndHiddenFalseOrderByCreatedAtDesc()
                .stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public PostResponse getById(UUID id) {
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Пост не найден"));

        if (post.isDeleted() || post.isHidden()) {
            throw new IllegalArgumentException("Пост не найден");
        }

        return toResponse(post);
    }

    @Transactional(readOnly = true)
    public List<PostResponse> getByAuthor(UUID authorId) {
        return postRepository.findByAuthorIdAndDeletedFalseOrderByCreatedAtDesc(authorId)
                .stream()
                .filter(post -> !post.isHidden())
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public void delete(UUID id) {
        Post post = postRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Пост не найден"));

        post.setDeleted(true);
        postRepository.save(post);
    }

    private PostResponse toResponse(Post post) {
        UUID originalPostId = post.getOriginalPost() == null
                ? null
                : post.getOriginalPost().getId();

        return new PostResponse(
                post.getId(),
                post.getAuthor().getId(),
                post.getAuthor().getUsername(),
                post.getAuthor().getDisplayName(),
                post.getContent(),
                post.getImageUrl(),
                originalPostId,
                post.getLikesCount(),
                post.getReblogsCount(),
                post.getCommentsCount(),
                post.getCreatedAt(),
                post.getUpdatedAt()
        );
    }
}