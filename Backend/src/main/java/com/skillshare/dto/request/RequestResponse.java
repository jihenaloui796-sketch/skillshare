package com.skillshare.dto.request;

import com.skillshare.model.RequestStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RequestResponse {
    private Long id;
    private Long requesterId;
    private String requesterFullName;
    private Long skillId;
    private String skillName;
    private Long skillOwnerId;
    private RequestStatus status;
    private String message;
    private Instant createdAt;
}
