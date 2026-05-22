package ru.chifir.backend.follow;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.chifir.backend.user.User;
import ru.chifir.backend.user.UserRepository;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class FollowService {

    private final FollowRepository followRepository;
    private final UserRepository userRepository;

    @Transactional
    public Map<String, Object> follow(UUID targetUserId, UUID followerId) {
        if (targetUserId.equals(followerId)) {
            throw new IllegalArgumentException("Нельзя подписаться на самого себя");
        }

        User follower = userRepository.findById(followerId)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь-подписчик не найден"));

        User following = userRepository.findById(targetUserId)
                .orElseThrow(() -> new IllegalArgumentException("Пользователь для подписки не найден"));

        if (followRepository.existsByFollowerIdAndFollowingId(followerId, targetUserId)) {
            return Map.of(
                    "following", true,
                    "followersCount", followRepository.countByFollowingId(targetUserId),
                    "followingCount", followRepository.countByFollowerId(followerId)
            );
        }

        Follow follow = new Follow();
        follow.setFollower(follower);
        follow.setFollowing(following);
        followRepository.save(follow);

        return Map.of(
                "following", true,
                "followersCount", followRepository.countByFollowingId(targetUserId),
                "followingCount", followRepository.countByFollowerId(followerId)
        );
    }

    @Transactional
    public Map<String, Object> unfollow(UUID targetUserId, UUID followerId) {
        followRepository.findByFollowerIdAndFollowingId(followerId, targetUserId)
                .ifPresent(followRepository::delete);

        return Map.of(
                "following", false,
                "followersCount", followRepository.countByFollowingId(targetUserId),
                "followingCount", followRepository.countByFollowerId(followerId)
        );
    }

    @Transactional(readOnly = true)
    public Map<String, Object> check(UUID targetUserId, UUID followerId) {
        return Map.of(
                "following", followRepository.existsByFollowerIdAndFollowingId(followerId, targetUserId),
                "followersCount", followRepository.countByFollowingId(targetUserId),
                "followingCount", followRepository.countByFollowerId(followerId)
        );
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getFollowers(UUID userId) {
        return followRepository.findByFollowingIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(follow -> userToMap(follow.getFollower()))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getFollowing(UUID userId) {
        return followRepository.findByFollowerIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(follow -> userToMap(follow.getFollowing()))
                .toList();
    }

    private Map<String, Object> userToMap(User user) {
        return Map.of(
                "id", user.getId(),
                "email", user.getEmail(),
                "username", user.getUsername(),
                "displayName", user.getDisplayName(),
                "avatarUrl", user.getAvatarUrl() == null ? "" : user.getAvatarUrl(),
                "bio", user.getBio() == null ? "" : user.getBio()
        );
    }
}