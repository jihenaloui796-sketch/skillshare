package com.skillshare.controller;

import com.skillshare.dto.skill.SkillCreateRequest;
import com.skillshare.dto.skill.SkillResponse;
import com.skillshare.dto.skill.SkillUpdateRequest;
import com.skillshare.model.SkillLevel;
import com.skillshare.service.SkillService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/skills")
public class SkillController {

    private final SkillService skillService;

    public SkillController(SkillService skillService) {
        this.skillService = skillService;
    }

    @GetMapping
    public ResponseEntity<Page<SkillResponse>> list(
            @RequestParam(required = false) SkillLevel level,
            @RequestParam(required = false) String search,
            Pageable pageable
    ) {
        return ResponseEntity.ok(skillService.list(level, search, pageable));
    }

    @GetMapping("/mine")
    public ResponseEntity<Page<SkillResponse>> listMine(Pageable pageable) {
        return ResponseEntity.ok(skillService.listMine(pageable));
    }

    @PostMapping
    public ResponseEntity<SkillResponse> create(@Valid @RequestBody SkillCreateRequest request) {
        return ResponseEntity.ok(skillService.create(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<SkillResponse> update(@PathVariable Long id, @Valid @RequestBody SkillUpdateRequest request) {
        return ResponseEntity.ok(skillService.update(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        skillService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
