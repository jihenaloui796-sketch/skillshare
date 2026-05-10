package com.skillshare.service;

import com.skillshare.dto.user.UpdateProfileRequest;
import com.skillshare.dto.user.UserProfileResponse;
import com.skillshare.exception.BadRequestException;
import com.skillshare.model.User;
import com.skillshare.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import jakarta.transaction.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.Instant;
import java.util.Set;

@Service
public class ProfileService {

    private final UserService userService;
    private final UserRepository userRepository;
    private final Path uploadRoot;

    public ProfileService(UserService userService,
                          UserRepository userRepository,
                          @Value("${app.upload-dir:uploads}") String uploadDir) {
        this.userService = userService;
        this.userRepository = userRepository;
        this.uploadRoot = Paths.get(uploadDir);
    }

    public UserProfileResponse getMyProfile() {
        User user = userService.getCurrentUserOrThrow();
        return toResponse(user);
    }

    @Transactional
    public UserProfileResponse updateMyProfile(UpdateProfileRequest request) {
        User user = userService.getCurrentUserOrThrow();
        user.setFullName(request.getFullName().trim());
        user.setBio(request.getBio() != null ? request.getBio().trim() : null);
        userRepository.save(user);
        return toResponse(user);
    }

    @Transactional
    public UserProfileResponse updateMyAvatar(MultipartFile file) throws IOException {
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("Avatar file is empty");
        }

        String original = file.getOriginalFilename();
        String ext = "";
        if (original != null) {
            int idx = original.lastIndexOf('.');
            if (idx >= 0 && idx < original.length() - 1) {
                ext = original.substring(idx + 1).toLowerCase();
            }
        }

        Set<String> allowedExt = Set.of("jpg", "jpeg", "png", "webp", "gif");
        String contentType = file.getContentType();
        boolean isImageByContentType = contentType != null && contentType.startsWith("image/");
        boolean isImageByExt = !ext.isBlank() && allowedExt.contains(ext);
        if (!isImageByContentType && !isImageByExt) {
            throw new BadRequestException("Only image files are allowed");
        }

        User user = userService.getCurrentUserOrThrow();

        Path avatarsDir = uploadRoot.resolve("avatars");
        Files.createDirectories(avatarsDir);

        String dotExt = ext.isBlank() ? "" : ("." + ext);
        String filename = "u" + user.getId() + "_" + Instant.now().toEpochMilli() + dotExt;
        Path dest = avatarsDir.resolve(filename).normalize();

        Files.copy(file.getInputStream(), dest, StandardCopyOption.REPLACE_EXISTING);

        user.setAvatarUrl("/uploads/avatars/" + filename);
        userRepository.save(user);
        return toResponse(user);
    }

    private static UserProfileResponse toResponse(User user) {
        return UserProfileResponse.builder()
                .id(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .bio(user.getBio())
                .avatarUrl(user.getAvatarUrl())
                .role(user.getRole().name())
                .points(user.getPoints())
                .build();
    }
}
