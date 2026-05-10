package com.skillshare.service;

import com.skillshare.dto.message.ConversationResponse;
import com.skillshare.dto.message.MessageCreateRequest;
import com.skillshare.dto.message.MessageResponse;
import com.skillshare.exception.BadRequestException;
import com.skillshare.model.Message;
import com.skillshare.model.User;
import com.skillshare.repository.MessageRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
public class MessageService {

    private final MessageRepository messageRepository;
    private final UserService userService;
    private final PushNotificationService pushNotificationService;

    public MessageService(MessageRepository messageRepository,
                          UserService userService,
                          PushNotificationService pushNotificationService) {
        this.messageRepository = messageRepository;
        this.userService = userService;
        this.pushNotificationService = pushNotificationService;
    }

    @Transactional
    public MessageResponse send(MessageCreateRequest request) {
        User current = userService.getCurrentUserOrThrow();
        User receiver = userService.getByIdOrThrow(request.getReceiverId());

        if (receiver.getId().equals(current.getId())) {
            throw new BadRequestException("You cannot message yourself");
        }

        Message msg = Message.builder()
                .sender(current)
                .receiver(receiver)
                .content(request.getContent())
                .read(false)
                .build();

        Message saved = messageRepository.save(msg);

        pushNotificationService.sendToToken(
                receiver.getFcmToken(),
                "Nouveau message",
                current.getFullName() + ": " + request.getContent(),
                Map.of(
                        "type", "message",
                        "senderId", String.valueOf(current.getId()),
                        "receiverId", String.valueOf(receiver.getId())
                )
        );

        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<MessageResponse> conversation(Long otherUserId) {
        User current = userService.getCurrentUserOrThrow();
        return messageRepository.findConversation(current.getId(), otherUserId)
                .stream()
                .map(MessageService::toResponse)
                .toList();
    }

    @Transactional
    public int markRead(Long otherUserId) {
        User current = userService.getCurrentUserOrThrow();
        return messageRepository.markRead(current.getId(), otherUserId);
    }

    @Transactional(readOnly = true)
    public List<ConversationResponse> conversations() {
        User current = userService.getCurrentUserOrThrow();

        // Get all messages involving current user (small app assumption)
        List<Message> all = messageRepository.findAllForUser(current.getId(), org.springframework.data.domain.Pageable.unpaged())
                .getContent();

        Map<Long, Message> lastByUser = new HashMap<>();
        Map<Long, Long> unreadByUser = new HashMap<>();
        Map<Long, User> userById = new HashMap<>();

        for (Message m : all) {
            Long otherId = Objects.equals(m.getSender().getId(), current.getId())
                    ? m.getReceiver().getId()
                    : m.getSender().getId();

            userById.putIfAbsent(otherId, Objects.equals(m.getSender().getId(), current.getId()) ? m.getReceiver() : m.getSender());

            Message prev = lastByUser.get(otherId);
            if (prev == null || (m.getCreatedAt() != null && prev.getCreatedAt() != null && m.getCreatedAt().isAfter(prev.getCreatedAt()))) {
                lastByUser.put(otherId, m);
            }

            if (!m.isRead() && Objects.equals(m.getReceiver().getId(), current.getId())) {
                unreadByUser.put(otherId, unreadByUser.getOrDefault(otherId, 0L) + 1L);
            }
        }

        List<ConversationResponse> result = new ArrayList<>();
        for (Map.Entry<Long, Message> e : lastByUser.entrySet()) {
            Long otherId = e.getKey();
            Message last = e.getValue();
            User u = userById.get(otherId);

            result.add(ConversationResponse.builder()
                    .userId(otherId)
                    .fullName(u != null ? u.getFullName() : null)
                    .email(u != null ? u.getEmail() : null)
                    .lastMessageId(last.getId())
                    .lastMessageContent(last.getContent())
                    .lastMessageCreatedAt(last.getCreatedAt())
                    .lastMessageSenderId(last.getSender() != null ? last.getSender().getId() : null)
                    .unreadCount(unreadByUser.getOrDefault(otherId, 0L))
                    .build());
        }

        result.sort((a, b) -> {
            if (a.getLastMessageCreatedAt() == null && b.getLastMessageCreatedAt() == null) return 0;
            if (a.getLastMessageCreatedAt() == null) return 1;
            if (b.getLastMessageCreatedAt() == null) return -1;
            return b.getLastMessageCreatedAt().compareTo(a.getLastMessageCreatedAt());
        });

        return result;
    }

    static MessageResponse toResponse(Message m) {
        return MessageResponse.builder()
                .id(m.getId())
                .senderId(m.getSender() != null ? m.getSender().getId() : null)
                .receiverId(m.getReceiver() != null ? m.getReceiver().getId() : null)
                .content(m.getContent())
                .createdAt(m.getCreatedAt())
                .read(m.isRead())
                .build();
    }
}
