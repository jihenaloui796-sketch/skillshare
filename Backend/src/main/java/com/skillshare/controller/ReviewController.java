package com.skillshare.controller;

import com.skillshare.dto.review.ReviewCreateRequest;
import com.skillshare.dto.review.ReviewResponse;
import com.skillshare.dto.review.ReviewUpdateRequest;
import com.skillshare.service.ReviewService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/reviews")
public class ReviewController {

    private final ReviewService reviewService;

    public ReviewController(ReviewService reviewService) {
        this.reviewService = reviewService;
    }

    @PostMapping
    public ResponseEntity<ReviewResponse> create(@Valid @RequestBody ReviewCreateRequest request) {
        return ResponseEntity.ok(reviewService.create(request));
    }

    @GetMapping("/{userId}")
    public ResponseEntity<List<ReviewResponse>> getByUser(@PathVariable Long userId) {
        return ResponseEntity.ok(reviewService.getByUser(userId));
    }

    @GetMapping("/mine")
    public ResponseEntity<List<ReviewResponse>> listMine() {
        return ResponseEntity.ok(reviewService.listMine());
    }

    @PutMapping("/{id}")
    public ResponseEntity<ReviewResponse> update(@PathVariable Long id, @Valid @RequestBody ReviewUpdateRequest request) {
        return ResponseEntity.ok(reviewService.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        reviewService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
