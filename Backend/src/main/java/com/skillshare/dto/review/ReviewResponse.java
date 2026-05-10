package com.skillshare.dto.review;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReviewResponse {
    private Long id;
    private int rating;
    private String comment;
    private Long reviewerId;
    private String reviewerFullName;
    private Long reviewedUserId;
    private Long requestId;
    private Instant createdAt;
}
