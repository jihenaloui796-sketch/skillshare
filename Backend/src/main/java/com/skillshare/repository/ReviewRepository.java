package com.skillshare.repository;

import com.skillshare.dto.rating.RatingBucketRow;
import com.skillshare.model.Review;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ReviewRepository extends JpaRepository<Review, Long> {
    List<Review> findByReviewedUserId(Long userId);

    List<Review> findByReviewer_Id(Long reviewerId);

    Optional<Review> findByReviewer_IdAndRequest_Id(Long reviewerId, Long requestId);

    @Query("select r.rating as rating, count(r) as count from Review r where r.reviewedUser.id = :userId group by r.rating")
    List<RatingBucketRow> ratingBucketsForUser(@Param("userId") Long userId);

    @Query("select r.rating as rating, count(r) as count from Review r where r.request.skill.id = :skillId group by r.rating")
    List<RatingBucketRow> ratingBucketsForSkill(@Param("skillId") Long skillId);

    @Query("select r.rating as rating, count(r) as count from Review r where r.request.id = :requestId group by r.rating")
    List<RatingBucketRow> ratingBucketsForRequest(@Param("requestId") Long requestId);
}
