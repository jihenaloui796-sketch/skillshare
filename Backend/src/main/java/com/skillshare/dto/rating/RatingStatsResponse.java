package com.skillshare.dto.rating;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RatingStatsResponse {
    private double average;
    private long count;
    private Map<Integer, Long> distribution;
}
