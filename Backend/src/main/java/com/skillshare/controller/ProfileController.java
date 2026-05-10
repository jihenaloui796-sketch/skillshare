package com.skillshare.controller;

import com.skillshare.dto.user.UpdateProfileRequest;
import com.skillshare.dto.user.UserProfileResponse;
import com.skillshare.service.ProfileService;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;

@RestController
@RequestMapping("/profile")
public class ProfileController {

    private final ProfileService profileService;

    public ProfileController(ProfileService profileService) {
        this.profileService = profileService;
    }

    @GetMapping
    public ResponseEntity<UserProfileResponse> me() {
        return ResponseEntity.ok(profileService.getMyProfile());
    }

    @PutMapping
    public ResponseEntity<UserProfileResponse> update(@Valid @RequestBody UpdateProfileRequest request) {
        return ResponseEntity.ok(profileService.updateMyProfile(request));
    }

    @PostMapping(value = "/avatar", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<UserProfileResponse> uploadAvatar(@RequestParam("file") MultipartFile file) throws IOException {
        return ResponseEntity.ok(profileService.updateMyAvatar(file));
    }
}
