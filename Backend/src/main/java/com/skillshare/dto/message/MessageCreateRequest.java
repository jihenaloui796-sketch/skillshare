package com.skillshare.dto.message;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class MessageCreateRequest {

    @NotNull
    private Long receiverId;

    @NotBlank
    @Size(max = 4000)
    private String content;
}
