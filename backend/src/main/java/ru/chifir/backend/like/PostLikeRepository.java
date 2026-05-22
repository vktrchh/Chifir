package ru.chifir.backend.like;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface PostLikeRepository extends JpaRepository<ru.chifir.backend.like.PostLike, UUID> {

    boolean existsByUserIdAndPostId(UUID userId, UUID postId);

    Optional<PostLike> findByUserIdAndPostId(UUID userId, UUID postId);

    long countByPostId(UUID postId);
}