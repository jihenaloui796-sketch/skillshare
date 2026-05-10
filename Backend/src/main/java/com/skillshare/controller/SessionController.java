package com.skillshare.controller;

import com.skillshare.dto.session.SessionResponse;
import com.skillshare.service.SessionService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/sessions")
public class SessionController {

    private final SessionService sessionService;

    public SessionController(SessionService sessionService) {
        this.sessionService = sessionService;
    }

    @GetMapping
    public ResponseEntity<Page<SessionResponse>> listMine(Pageable pageable) {
        return ResponseEntity.ok(sessionService.listMine(pageable));
    }

    @GetMapping("/{id}")
    public ResponseEntity<SessionResponse> getMine(@PathVariable Long id) {
        return ResponseEntity.ok(sessionService.getMine(id));
    }
}
