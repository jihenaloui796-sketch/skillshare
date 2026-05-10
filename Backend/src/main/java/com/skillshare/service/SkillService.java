package com.skillshare.service;

import com.skillshare.dto.skill.SkillCreateRequest;
import com.skillshare.dto.skill.SkillResponse;
import com.skillshare.dto.skill.SkillUpdateRequest;
import com.skillshare.exception.BadRequestException;
import com.skillshare.exception.ResourceNotFoundException;
import com.skillshare.model.Skill;
import com.skillshare.model.SkillLevel;
import com.skillshare.model.User;
import com.skillshare.repository.SkillRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SkillService {

    private static final Logger log = LoggerFactory.getLogger(SkillService.class);

    private final SkillRepository skillRepository;
    private final UserService userService;

    public SkillService(SkillRepository skillRepository, UserService userService) {
        this.skillRepository = skillRepository;
        this.userService = userService;
    }

    @Transactional(readOnly = true)
    public Page<SkillResponse> list(SkillLevel level, String search, Pageable pageable) {
        boolean hasLevel = level != null;
        boolean hasSearch = search != null && !search.isBlank();

        Page<Skill> page;
        if (hasLevel && hasSearch) {
            page = skillRepository.findByLevelAndNameContainingIgnoreCase(level, search.trim(), pageable);
        } else if (hasLevel) {
            page = skillRepository.findByLevel(level, pageable);
        } else if (hasSearch) {
            page = skillRepository.findByNameContainingIgnoreCase(search.trim(), pageable);
        } else {
            page = skillRepository.findAll(pageable);
        }

        return page.map(SkillService::toResponse);
    }

    @Transactional(readOnly = true)
    public Page<SkillResponse> listMine(Pageable pageable) {
        User current = userService.getCurrentUserOrThrow();
        return skillRepository.findByOwner_Id(current.getId(), pageable).map(SkillService::toResponse);
    }

    @Transactional
    public SkillResponse create(SkillCreateRequest request) {
        User current = userService.getCurrentUserOrThrow();
        Skill skill = Skill.builder()
                .name(request.getName().trim())
                .description(request.getDescription())
                .level(request.getLevel())
                .owner(current)
                .build();
        Skill saved = skillRepository.save(skill);
        userService.addPoints(current, 5);
        log.info("Skill created id={} ownerId={} name={}", saved.getId(), current.getId(), saved.getName());
        return toResponse(saved);
    }

    @Transactional
    public SkillResponse update(Long id, SkillUpdateRequest request) {
        User current = userService.getCurrentUserOrThrow();
        Skill skill = skillRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Skill not found"));

        if (!skill.getOwner().getId().equals(current.getId())) {
            throw new BadRequestException("Not allowed to update this skill");
        }

        skill.setName(request.getName().trim());
        skill.setDescription(request.getDescription());
        skill.setLevel(request.getLevel());
        return toResponse(skillRepository.save(skill));
    }

    @Transactional
    public void delete(Long id) {
        User current = userService.getCurrentUserOrThrow();
        Skill skill = skillRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Skill not found"));

        if (!skill.getOwner().getId().equals(current.getId())) {
            throw new BadRequestException("Not allowed to delete this skill");
        }

        skillRepository.delete(skill);
    }

    static SkillResponse toResponse(Skill s) {
        return SkillResponse.builder()
                .id(s.getId())
                .name(s.getName())
                .description(s.getDescription())
                .level(s.getLevel() != null ? s.getLevel().name() : null)
                .ownerId(s.getOwner() != null ? s.getOwner().getId() : null)
                .ownerFullName(s.getOwner() != null ? s.getOwner().getFullName() : null)
                .createdAt(s.getCreatedAt())
                .build();
    }
}
