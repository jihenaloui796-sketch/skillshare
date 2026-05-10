package com.skillshare.dto.skill;

import com.skillshare.model.SkillLevel;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class SkillUpdateRequest {

    @NotBlank
    @Size(max = 120)
    private String name;

    @Size(max = 2000)
    private String description;

    @NotNull
    private SkillLevel level;
}
