package ru.chifir.backend.tag;

import lombok.Getter;
import lombok.Setter;

import java.io.Serializable;
import java.util.UUID;

@Getter
@Setter
public class PostTagId implements Serializable {

    private UUID post;
    private UUID tag;

    public PostTagId() {
    }

    public PostTagId(UUID post, UUID tag) {
        this.post = post;
        this.tag = tag;
    }
}