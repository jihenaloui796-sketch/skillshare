package com.skillshare.controller;

import com.skillshare.dto.user.UserSummaryResponse;
import com.skillshare.model.User;
import com.skillshare.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public ResponseEntity<List<UserSummaryResponse>> list() {
        List<User> users = userService.listOtherUsers();
        List<UserSummaryResponse> res = users.stream()
                .map(u -> UserSummaryResponse.builder()
                        .id(u.getId())
                        .fullName(u.getFullName())
                        .email(u.getEmail())
                        .build())
                .toList();
        return ResponseEntity.ok(res);
    }
}
