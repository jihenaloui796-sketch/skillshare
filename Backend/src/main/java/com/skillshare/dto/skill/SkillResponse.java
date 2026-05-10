package com.skillshare.dto.skill;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SkillResponse {
    private Long id;
    private String name;
    private String description;
    private String level;
    private Long ownerId;
    private String ownerFullName;
    private Instant createdAt;
}
