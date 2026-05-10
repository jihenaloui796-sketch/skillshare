package com.skillshare.dto.notification;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RegisterFcmTokenRequest {
    @NotBlank
    private String token;
}
