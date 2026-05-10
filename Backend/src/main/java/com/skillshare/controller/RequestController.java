package com.skillshare.controller;

import com.skillshare.dto.request.RequestCreateRequest;
import com.skillshare.dto.request.RequestResponse;
import com.skillshare.dto.request.RequestUpdateRequest;
import com.skillshare.service.RequestService;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/requests")
public class RequestController {

    private final RequestService requestService;

    public RequestController(RequestService requestService) {
        this.requestService = requestService;
    }

    @PostMapping
    public ResponseEntity<RequestResponse> create(@Valid @RequestBody RequestCreateRequest request) {
        return ResponseEntity.ok(requestService.create(request));
    }

    @GetMapping
    public ResponseEntity<Page<RequestResponse>> listMine(Pageable pageable) {
        return ResponseEntity.ok(requestService.listMine(pageable));
    }

    @GetMapping("/incoming")
    public ResponseEntity<Page<RequestResponse>> listIncoming(Pageable pageable) {
        return ResponseEntity.ok(requestService.listIncoming(pageable));
    }

    @PutMapping("/{id}")
    public ResponseEntity<RequestResponse> update(@PathVariable Long id, @Valid @RequestBody RequestUpdateRequest request) {
        return ResponseEntity.ok(requestService.update(id, request));
    }
}
