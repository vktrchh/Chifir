package ru.chifir.backend.feed;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.chifir.backend.follow.FollowRepository;
import ru.chifir.backend.post.Post;
import ru.chifir.backend.post.PostRepository;
import ru.chifir.backend.post.dto.PostResponse;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FeedService {

    private final PostRepository postRepository;
    private final FollowRepository followRepository;

    @Transactional(readOnly = true)
    public List<PostResponse> getFollowingFeed(UUID userId) {
        List<UUID> followingIds = followRepository.findByFollowerIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(follow -> follow.getFollowing().getId())
                .toList();

        if (followingIds.isEmpty()) {
            return List.of();
        }

        return postRepository.findByAuthorIdInAndDeletedFalseAndHiddenFalseOrderByCreatedAtDesc(followingIds)
                .stream()
                .map(this::toResponse)
                .toList();
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