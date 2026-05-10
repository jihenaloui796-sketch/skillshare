package com.skillshare.service;

import com.skillshare.dto.auth.AuthResponse;
import com.skillshare.dto.auth.LoginRequest;
import com.skillshare.dto.auth.RegisterRequest;
import com.skillshare.exception.BadRequestException;
import com.skillshare.model.Role;
import com.skillshare.model.User;
import com.skillshare.repository.UserRepository;
import com.skillshare.security.JwtService;
import jakarta.transaction.Transactional;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       AuthenticationManager authenticationManager,
                       JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        if (userRepository.existsByEmail(email)) {
            throw new BadRequestException("Email already in use");
        }

        User user = User.builder()
                .email(email)
                .fullName(request.getFullName().trim())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(Role.USER)
                .build();

        userRepository.save(user);

        String token = jwtService.generateToken(user.getId(), user.getEmail());
        log.info("User registered id={} email={}", user.getId(), user.getEmail());
        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(email, request.getPassword())
        );

        User user = userRepository.findByEmail(authentication.getName())
                .orElseThrow(() -> new BadRequestException("Invalid credentials"));

        String token = jwtService.generateToken(user.getId(), user.getEmail());
        log.info("User login id={} email={}", user.getId(), user.getEmail());
        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .build();
    }
}
