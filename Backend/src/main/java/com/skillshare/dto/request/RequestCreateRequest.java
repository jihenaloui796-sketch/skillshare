package com.skillshare.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RequestCreateRequest {

    @NotNull
    private Long skillId;

    @Size(max = 2000)
    private String message;
}
