package com.skillshare.controller;

import com.skillshare.dto.message.ConversationResponse;
import com.skillshare.dto.message.MessageCreateRequest;
import com.skillshare.dto.message.MessageResponse;
import com.skillshare.service.MessageService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/messages")
public class MessageController {

    private final MessageService messageService;

    public MessageController(MessageService messageService) {
        this.messageService = messageService;
    }

    @GetMapping("/conversations")
    public ResponseEntity<List<ConversationResponse>> conversations() {
        return ResponseEntity.ok(messageService.conversations());
    }

    @GetMapping("/with/{userId}")
    public ResponseEntity<List<MessageResponse>> conversation(@PathVariable Long userId) {
        return ResponseEntity.ok(messageService.conversation(userId));
    }

    @PostMapping
    public ResponseEntity<MessageResponse> send(@Valid @RequestBody MessageCreateRequest request) {
        return ResponseEntity.ok(messageService.send(request));
    }

    @PostMapping("/with/{userId}/read")
    public ResponseEntity<Void> markRead(@PathVariable Long userId) {
        messageService.markRead(userId);
        return ResponseEntity.noContent().build();
    }
}
