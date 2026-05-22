package ru.chifir.backend.follow;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FollowRepository extends JpaRepository<Follow, UUID> {

    boolean existsByFollowerIdAndFollowingId(UUID followerId, UUID followingId);

    Optional<Follow> findByFollowerIdAndFollowingId(UUID followerId, UUID followingId);

    List<Follow> findByFollowerIdOrderByCreatedAtDesc(UUID followerId);

    List<Follow> findByFollowingIdOrderByCreatedAtDesc(UUID followingId);

    long countByFollowerId(UUID followerId);

    long countByFollowingId(UUID followingId);
}