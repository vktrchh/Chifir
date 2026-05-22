package ru.chifir.backend.tag;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface PostTagRepository extends JpaRepository<PostTag, PostTagId> {

    boolean existsByPostIdAndTagId(UUID postId, UUID tagId);

    Optional<PostTag> findByPostIdAndTagId(UUID postId, UUID tagId);

    List<PostTag> findByPostId(UUID postId);

    List<PostTag> findByTagNameOrderByPostCreatedAtDesc(String tagName);
}