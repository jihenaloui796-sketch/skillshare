package com.skillshare.repository;

import com.skillshare.model.SkillRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SkillRequestRepository extends JpaRepository<SkillRequest, Long> {
    List<SkillRequest> findByRequesterId(Long requesterId);

    Page<SkillRequest> findByRequesterId(Long requesterId, Pageable pageable);

    Page<SkillRequest> findBySkillOwnerId(Long ownerId, Pageable pageable);

    Page<SkillRequest> findBySkill_Owner_Id(Long ownerId, Pageable pageable);
}
