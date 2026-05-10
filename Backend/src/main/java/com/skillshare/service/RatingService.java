package com.skillshare.service;

import com.skillshare.dto.rating.RatingBucketRow;
import com.skillshare.dto.rating.RatingStatsResponse;
import com.skillshare.exception.ResourceNotFoundException;
import com.skillshare.model.Session;
import com.skillshare.repository.ReviewRepository;
import com.skillshare.repository.SessionRepository;
import com.skillshare.repository.SkillRepository;
import com.skillshare.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class RatingService {

    private final ReviewRepository reviewRepository;
    private final UserRepository userRepository;
    private final SkillRepository skillRepository;
    private final SessionRepository sessionRepository;

    public RatingService(ReviewRepository reviewRepository,
                         UserRepository userRepository,
                         SkillRepository skillRepository,
                         SessionRepository sessionRepository) {
        this.reviewRepository = reviewRepository;
        this.userRepository = userRepository;
        this.skillRepository = skillRepository;
        this.sessionRepository = sessionRepository;
    }

    @Transactional(readOnly = true)
    public RatingStatsResponse statsForUser(Long userId) {
        userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return toStats(reviewRepository.ratingBucketsForUser(userId));
    }

    @Transactional(readOnly = true)
    public RatingStatsResponse statsForSkill(Long skillId) {
        skillRepository.findById(skillId)
                .orElseThrow(() -> new ResourceNotFoundException("Skill not found"));
        return toStats(reviewRepository.ratingBucketsForSkill(skillId));
    }

    @Transactional(readOnly = true)
    public RatingStatsResponse statsForSession(Long sessionId) {
        Session session = sessionRepository.findById(sessionId)
                .orElseThrow(() -> new ResourceNotFoundException("Session not found"));
        if (session.getRequest() == null || session.getRequest().getId() == null) {
            throw new ResourceNotFoundException("Session request not found");
        }
        return toStats(reviewRepository.ratingBucketsForRequest(session.getRequest().getId()));
    }

    private static RatingStatsResponse toStats(List<RatingBucketRow> buckets) {
        Map<Integer, Long> distribution = new HashMap<>();
        for (int i = 1; i <= 5; i++) {
            distribution.put(i, 0L);
        }

        long count = 0;
        long sum = 0;
        for (RatingBucketRow r : buckets) {
            if (r.getRating() == null || r.getCount() == null) continue;
            distribution.put(r.getRating(), r.getCount());
            count += r.getCount();
            sum += (long) r.getRating() * r.getCount();
        }

        double avg = count == 0 ? 0.0 : ((double) sum) / count;
        return RatingStatsResponse.builder()
                .average(avg)
                .count(count)
                .distribution(distribution)
                .build();
    }
}
