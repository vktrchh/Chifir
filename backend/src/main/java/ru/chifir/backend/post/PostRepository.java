package ru.chifir.backend.post;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PostRepository extends JpaRepository<Post, UUID> {

    List<Post> findByDeletedFalseAndHiddenFalseOrderByCreatedAtDesc();

    List<Post> findByAuthorIdAndDeletedFalseOrderByCreatedAtDesc(UUID authorId);

    List<Post> findByAuthorIdInAndDeletedFalseAndHiddenFalseOrderByCreatedAtDesc(List<UUID> authorIds);
}