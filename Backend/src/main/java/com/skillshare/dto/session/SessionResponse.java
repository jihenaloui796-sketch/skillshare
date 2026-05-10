package com.skillshare.dto.session;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SessionResponse {
    private Long id;
    private Long requestId;
    private Long skillId;
    private String skillName;
    private Long ownerId;
    private Long requesterId;
    private Instant createdAt;
}
