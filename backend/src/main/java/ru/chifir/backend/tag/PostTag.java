package ru.chifir.backend.tag;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import ru.chifir.backend.post.Post;

@Getter
@Setter
@Entity
@Table(name = "post_tags")
@IdClass(PostTagId.class)
public class PostTag {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id", nullable = false)
    private Post post;

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tag_id", nullable = false)
    private Tag tag;
}