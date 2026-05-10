package com.skillshare.controller;

import com.skillshare.dto.rating.RatingStatsResponse;
import com.skillshare.service.RatingService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/ratings")
public class RatingController {

    private final RatingService ratingService;

    public RatingController(RatingService ratingService) {
        this.ratingService = ratingService;
    }

    @GetMapping("/users/{userId}")
    public ResponseEntity<RatingStatsResponse> user(@PathVariable Long userId) {
        return ResponseEntity.ok(ratingService.statsForUser(userId));
    }

    @GetMapping("/skills/{skillId}")
    public ResponseEntity<RatingStatsResponse> skill(@PathVariable Long skillId) {
        return ResponseEntity.ok(ratingService.statsForSkill(skillId));
    }

    @GetMapping("/sessions/{sessionId}")
    public ResponseEntity<RatingStatsResponse> session(@PathVariable Long sessionId) {
        return ResponseEntity.ok(ratingService.statsForSession(sessionId));
    }
}
