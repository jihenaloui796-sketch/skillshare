package com.skillshare.dto.user;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class UpdateProfileRequest {

    @NotBlank
    @Size(max = 120)
    private String fullName;

    @Size(max = 1000)
    private String bio;
}
