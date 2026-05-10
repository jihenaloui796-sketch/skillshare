package com.skillshare.controller;

import com.skillshare.dto.notification.RegisterFcmTokenRequest;
import com.skillshare.exception.BadRequestException;
import com.skillshare.service.PushNotificationService;
import com.skillshare.service.UserService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/notifications")
public class NotificationController {

    private final UserService userService;
    private final PushNotificationService pushNotificationService;

    public NotificationController(UserService userService, PushNotificationService pushNotificationService) {
        this.userService = userService;
        this.pushNotificationService = pushNotificationService;
    }

    @PostMapping("/token")
    public ResponseEntity<Void> registerToken(@Valid @RequestBody RegisterFcmTokenRequest req) {
        userService.updateMyFcmToken(req.getToken());
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/test")
    public ResponseEntity<Void> test(@RequestParam(defaultValue = "Test") String title,
                                     @RequestParam(defaultValue = "Hello") String body) {
        var me = userService.getCurrentUserOrThrow();

        if (!pushNotificationService.isConfigured()) {
            throw new BadRequestException("FCM is not configured on backend (firebase.credentials-path is missing/invalid)");
        }
        if (me.getFcmToken() == null || me.getFcmToken().isBlank()) {
            throw new BadRequestException("Your account has no FCM token. Login on mobile and ensure /notifications/token is called.");
        }

        boolean ok = pushNotificationService.sendToToken(me.getFcmToken(), title, body, Map.of("type", "test"));
        if (!ok) {
            throw new BadRequestException("Push send failed. Check backend logs: token may be invalid or Firebase project may mismatch the app.");
        }
        return ResponseEntity.noContent().build();
    }
}
