package ru.chifir.backend.tag;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import ru.chifir.backend.post.Post;
import ru.chifir.backend.post.PostRepository;
import ru.chifir.backend.post.dto.PostResponse;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TagService {

    private final TagRepository tagRepository;
    private final PostTagRepository postTagRepository;
    private final PostRepository postRepository;

    @Transactional
    public Map<String, Object> addTagToPost(UUID postId, String rawName) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("Пост не найден"));

        if (post.isDeleted() || post.isHidden()) {
            throw new IllegalArgumentException("Пост не найден");
        }

        String name = normalizeTag(rawName);

        Tag tag = tagRepository.findByName(name)
                .orElseGet(() -> {
                    Tag newTag = new Tag();
                    newTag.setName(name);
                    return tagRepository.save(newTag);
                });

        if (!postTagRepository.existsByPostIdAndTagId(postId, tag.getId())) {
            PostTag postTag = new PostTag();
            postTag.setPost(post);
            postTag.setTag(tag);
            postTagRepository.save(postTag);
        }

        return Map.of(
                "postId", postId,
                "tag", tag.getName()
        );
    }

    @Transactional(readOnly = true)
    public List<String> getPostTags(UUID postId) {
        return postTagRepository.findByPostId(postId)
                .stream()
                .map(postTag -> postTag.getTag().getName())
                .toList();
    }

    @Transactional
    public Map<String, Object> removeTagFromPost(UUID postId, String rawName) {
        String name = normalizeTag(rawName);

        Tag tag = tagRepository.findByName(name)
                .orElseThrow(() -> new IllegalArgumentException("Тег не найден"));

        postTagRepository.findByPostIdAndTagId(postId, tag.getId())
                .ifPresent(postTagRepository::delete);

        return Map.of(
                "postId", postId,
                "tag", name,
                "removed", true
        );
    }

    @Transactional(readOnly = true)
    public List<PostResponse> getPostsByTag(String rawName) {
        String name = normalizeTag(rawName);

        return postTagRepository.findByTagNameOrderByPostCreatedAtDesc(name)
                .stream()
                .map(PostTag::getPost)
                .filter(post -> !post.isDeleted() && !post.isHidden())
                .map(this::toResponse)
                .toList();
    }

    private String normalizeTag(String rawName) {
        if (rawName == null || rawName.isBlank()) {
            throw new IllegalArgumentException("Название тега обязательно");
        }

        String name = rawName.trim().toLowerCase();

        if (name.startsWith("#")) {
            name = name.substring(1);
        }

        if (name.length() > 50) {
            throw new IllegalArgumentException("Тег должен быть не длиннее 50 символов");
        }

        return name;
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