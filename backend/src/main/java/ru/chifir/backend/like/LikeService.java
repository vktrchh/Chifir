package ru.chifir.backend.like;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.chifir.backend.post.Post;
import ru.chifir.backend.post.PostRepository;
import ru.chifir.backend.user.User;
import ru.chifir.backend.user.UserRepository;

import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class LikeService {

    private final PostLikeRepository postLikeRepository;
    private final PostRepository postRepository;
    private final UserRepository userRepository;

    @Transactional
    public Map<String, Object> like(UUID postId, UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь не найден"));

        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Пост не найден"));

        if (post.isDeleted() || post.isHidden()) {
            throw new IllegalArgumentException("Пост не найден");
        }

        if (postLikeRepository.existsByUserIdAndPostId(userId, postId)) {
            return Map.of(
                    "liked", true,
                    "likesCount", post.getLikesCount()
            );
        }

        PostLike postLike = new PostLike();
        postLike.setUser(user);
        postLike.setPost(post);
        postLikeRepository.save(postLike);

        post.setLikesCount(post.getLikesCount() + 1);
        postRepository.save(post);

        return Map.of(
                "liked", true,
                "likesCount", post.getLikesCount()
        );
    }

    @Transactional
    public Map<String, Object> unlike(UUID postId, UUID userId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Пост не найден"));

        return postLikeRepository.findByUserIdAndPostId(userId, postId)
                .map(postLike -> {
                    postLikeRepository.delete(postLike);

                    if (post.getLikesCount() > 0) {
                        post.setLikesCount(post.getLikesCount() - 1);
                        postRepository.save(post);
                    }

                    return Map.<String, Object>of(
                            "liked", false,
                            "likesCount", post.getLikesCount()
                    );
                })
                .orElseGet(() -> Map.of(
                        "liked", false,
                        "likesCount", post.getLikesCount()
                ));
    }

    @Transactional(readOnly = true)
    public Map<String, Object> check(UUID postId, UUID userId) {
        boolean liked = postLikeRepository.existsByUserIdAndPostId(userId, postId);
        long likesCount = postLikeRepository.countByPostId(postId);

        return Map.of(
                "liked", liked,
                "likesCount", likesCount
        );
    }
}