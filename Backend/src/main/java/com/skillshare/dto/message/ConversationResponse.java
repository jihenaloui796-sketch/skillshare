package com.skillshare.dto.message;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ConversationResponse {
    private Long userId;
    private String fullName;
    private String email;

    private Long lastMessageId;
    private String lastMessageContent;
    private Instant lastMessageCreatedAt;
    private Long lastMessageSenderId;

    private long unreadCount;
}
