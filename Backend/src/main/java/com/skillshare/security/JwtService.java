package com.skillshare.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.Map;
import java.util.Date;

@Service
public class JwtService {

    private final JwtProperties jwtProperties;
    private final SecretKey secretKey;

    public JwtService(JwtProperties jwtProperties) {
        this.jwtProperties = jwtProperties;
        this.secretKey = Keys.hmacShaKeyFor(Decoders.BASE64.decode(toBase64IfNeeded(jwtProperties.getSecret())));
    }

    public String generateToken(Long userId, String email) {
        Instant now = Instant.now();
        Instant expiry = now.plus(jwtProperties.getExpirationMinutes(), ChronoUnit.MINUTES);

        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", userId);
        claims.put("email", email);

        return Jwts.builder()
                .setClaims(claims)
                .setSubject(email)
                .setIssuedAt(Date.from(now))
                .setExpiration(Date.from(expiry))
                .signWith(secretKey, SignatureAlgorithm.HS256)
                .compact();
    }

    public String extractSubject(String token) {
        return parseAllClaims(token).getSubject();
    }

    public Long extractUserId(String token) {
        Object raw = parseAllClaims(token).get("userId");
        if (raw == null) {
            return null;
        }
        if (raw instanceof Number n) {
            return n.longValue();
        }
        return Long.valueOf(String.valueOf(raw));
    }

    public String extractEmailClaim(String token) {
        Object raw = parseAllClaims(token).get("email");
        return raw != null ? String.valueOf(raw) : null;
    }

    public boolean isTokenValid(String token) {
        try {
            parseAllClaims(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private Claims parseAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(secretKey)
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    private static String toBase64IfNeeded(String secret) {
        if (secret == null) {
            return "";
        }
        boolean looksBase64 = secret.matches("^[A-Za-z0-9+/=]+$");
        if (looksBase64 && secret.length() % 4 == 0) {
            return secret;
        }
        return java.util.Base64.getEncoder().encodeToString(secret.getBytes(java.nio.charset.StandardCharsets.UTF_8));
    }
}
