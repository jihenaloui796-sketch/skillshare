package com.skillshare.service;

import com.skillshare.exception.ResourceNotFoundException;
import com.skillshare.model.User;
import com.skillshare.repository.UserRepository;
import com.skillshare.security.CurrentUserService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Objects;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final CurrentUserService currentUserService;

    public UserService(UserRepository userRepository, CurrentUserService currentUserService) {
        this.userRepository = userRepository;
        this.currentUserService = currentUserService;
    }

    public User getCurrentUserOrThrow() {
        String email = currentUserService.getCurrentUserEmail();
        if (email == null) {
            throw new ResourceNotFoundException("User not found");
        }
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    public User getByIdOrThrow(Long id) {
        return userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    public void addPoints(User user, int delta) {
        Objects.requireNonNull(user, "user");
        if (delta <= 0) return;
        Integer current = user.getPoints();
        if (current == null) current = 0;
        user.setPoints(current + delta);
        userRepository.save(user);
    }

    public List<User> listOtherUsers() {
        User current = getCurrentUserOrThrow();
        return userRepository.findAll().stream()
                .filter(u -> u.getId() != null && !u.getId().equals(current.getId()))
                .toList();
    }

    public void updateMyFcmToken(String token) {
        User current = getCurrentUserOrThrow();
        current.setFcmToken(token);
        userRepository.save(current);
    }
}
