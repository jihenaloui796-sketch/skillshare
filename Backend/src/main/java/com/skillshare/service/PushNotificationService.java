package com.skillshare.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.lang.Nullable;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class PushNotificationService {

    private static final Logger log = LoggerFactory.getLogger(PushNotificationService.class);

    private final FirebaseMessaging firebaseMessaging;

    public PushNotificationService(@Nullable FirebaseMessaging firebaseMessaging) {
        this.firebaseMessaging = firebaseMessaging;
    }

    public boolean isConfigured() {
        return firebaseMessaging != null;
    }

    public boolean sendToToken(String token, String title, String body, Map<String, String> data) {
        if (firebaseMessaging == null) {
            log.warn("FCM not configured: FirebaseMessaging bean is null (credentials-path missing?)");
            return false;
        }
        if (token == null || token.isBlank()) {
            log.warn("FCM token is blank; skip push send");
            return false;
        }

        Message msg = Message.builder()
                .setToken(token)
                .setNotification(Notification.builder().setTitle(title).setBody(body).build())
                .putAllData(data == null ? Map.of() : data)
                .build();

        try {
            String id = firebaseMessaging.send(msg);
            log.info("Push sent to token (len={}): messageId={}", token.length(), id);
            return true;
        } catch (Exception ex) {
            log.warn("Failed to send push notification", ex);
            return false;
        }
    }
}
