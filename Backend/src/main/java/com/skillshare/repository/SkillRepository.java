package com.skillshare.repository;

import com.skillshare.model.Skill;
import com.skillshare.model.SkillLevel;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SkillRepository extends JpaRepository<Skill, Long> {

    Page<Skill> findByNameContainingIgnoreCase(String name, Pageable pageable);

    Page<Skill> findByLevel(SkillLevel level, Pageable pageable);

    Page<Skill> findByLevelAndNameContainingIgnoreCase(SkillLevel level, String name, Pageable pageable);

    Page<Skill> findByOwner_Id(Long ownerId, Pageable pageable);
}
