package com.skillshare.service;

import com.skillshare.dto.review.ReviewCreateRequest;
import com.skillshare.dto.review.ReviewResponse;
import com.skillshare.dto.review.ReviewUpdateRequest;
import com.skillshare.exception.BadRequestException;
import com.skillshare.exception.ResourceNotFoundException;
import com.skillshare.model.Review;
import com.skillshare.model.Session;
import com.skillshare.model.SkillRequest;
import com.skillshare.model.User;
import com.skillshare.repository.ReviewRepository;
import com.skillshare.repository.SessionRepository;
import com.skillshare.repository.SkillRequestRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final SkillRequestRepository requestRepository;
    private final SessionRepository sessionRepository;
    private final UserService userService;
    private final PushNotificationService pushNotificationService;

    public ReviewService(ReviewRepository reviewRepository,
                         SkillRequestRepository requestRepository,
                         SessionRepository sessionRepository,
                         UserService userService,
                         PushNotificationService pushNotificationService) {
        this.reviewRepository = reviewRepository;
        this.requestRepository = requestRepository;
        this.sessionRepository = sessionRepository;
        this.userService = userService;
        this.pushNotificationService = pushNotificationService;
    }

    @Transactional
    public ReviewResponse create(ReviewCreateRequest request) {
        User reviewer = userService.getCurrentUserOrThrow();
        User reviewedUser = userService.getByIdOrThrow(request.getReviewedUserId());

        if (reviewer.getId().equals(reviewedUser.getId())) {
            throw new BadRequestException("You cannot review yourself");
        }

        if (request.getRequestId() == null) {
            throw new BadRequestException("requestId is required");
        }

        reviewRepository.findByReviewer_IdAndRequest_Id(reviewer.getId(), request.getRequestId())
                .ifPresent(r -> {
                    throw new BadRequestException("You already reviewed this session");
                });

        SkillRequest skillRequest = requestRepository.findById(request.getRequestId())
                .orElseThrow(() -> new ResourceNotFoundException("Request not found"));

        Session session = sessionRepository.findByRequest_Id(skillRequest.getId())
                .orElseThrow(() -> new BadRequestException("A session must exist before adding a review"));

        boolean isParticipant = session.getOwner().getId().equals(reviewer.getId())
                || session.getRequester().getId().equals(reviewer.getId());
        if (!isParticipant) {
            throw new BadRequestException("Only session participants can add a review");
        }

        Long otherParticipantId = session.getOwner().getId().equals(reviewer.getId())
                ? session.getRequester().getId()
                : session.getOwner().getId();

        if (!reviewedUser.getId().equals(otherParticipantId)) {
            throw new BadRequestException("You can only review the other participant");
        }

        Review review = Review.builder()
                .reviewer(reviewer)
                .reviewedUser(reviewedUser)
                .request(skillRequest)
                .rating(request.getRating())
                .comment(request.getComment())
                .build();

        Review saved = reviewRepository.save(review);
        userService.addPoints(reviewedUser, 2);

        String token = reviewedUser.getFcmToken();
        if (token != null && !token.isBlank()) {
            pushNotificationService.sendToToken(
                    token,
                    "Nouvel avis",
                    reviewer.getFullName() + " vous a laissé un avis (" + request.getRating() + "/5).",
                    java.util.Map.of(
                            "type", "review_received",
                            "reviewId", String.valueOf(saved.getId()),
                            "requestId", String.valueOf(skillRequest.getId())
                    )
            );
        }

        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<ReviewResponse> getByUser(Long userId) {
        return reviewRepository.findByReviewedUserId(userId).stream().map(ReviewService::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<ReviewResponse> listMine() {
        User current = userService.getCurrentUserOrThrow();
        return reviewRepository.findByReviewer_Id(current.getId()).stream().map(ReviewService::toResponse).toList();
    }

    @Transactional
    public ReviewResponse update(Long id, ReviewUpdateRequest request) {
        User current = userService.getCurrentUserOrThrow();
        Review review = reviewRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Review not found"));

        if (review.getReviewer() == null || !review.getReviewer().getId().equals(current.getId())) {
            throw new BadRequestException("Not allowed to update this review");
        }

        review.setRating(request.getRating());
        review.setComment(request.getComment());
        return toResponse(reviewRepository.save(review));
    }

    @Transactional
    public void delete(Long id) {
        User current = userService.getCurrentUserOrThrow();
        Review review = reviewRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Review not found"));

        if (review.getReviewer() == null || !review.getReviewer().getId().equals(current.getId())) {
            throw new BadRequestException("Not allowed to delete this review");
        }

        reviewRepository.delete(review);
    }

    static ReviewResponse toResponse(Review r) {
        return ReviewResponse.builder()
                .id(r.getId())
                .rating(r.getRating())
                .comment(r.getComment())
                .reviewerId(r.getReviewer() != null ? r.getReviewer().getId() : null)
                .reviewerFullName(r.getReviewer() != null ? r.getReviewer().getFullName() : null)
                .reviewedUserId(r.getReviewedUser() != null ? r.getReviewedUser().getId() : null)
                .requestId(r.getRequest() != null ? r.getRequest().getId() : null)
                .createdAt(r.getCreatedAt())
                .build();
    }
}
