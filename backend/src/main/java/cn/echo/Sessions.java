package cn.echo;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
class Sessions {
    private static final Duration LIFETIME = Duration.ofHours(12);

    record User(long id, String nickname, String avatarUrl, String role, int vipLevel) {}
    record Login(String token, User user) {}
    private record Account(User user, byte[] password) {}
    private record Session(User user, Instant expires) {}

    private final Map<String, Account> accounts;
    private final Map<String, Session> tokens = new ConcurrentHashMap<>();

    Sessions(@Value("${echo.listener-password}") String listenerPassword,
             @Value("${echo.operator-password}") String operatorPassword) {
        if (listenerPassword.isBlank() || operatorPassword.isBlank()) {
            throw new IllegalArgumentException("Set both Echo demo account passwords.");
        }
        accounts = Map.of(
            "listener", new Account(new User(1, "实训听众", "", "listener", 0), bytes(listenerPassword)),
            "operator", new Account(new User(2, "内容运营", "", "operator", 0), bytes(operatorPassword)));
    }

    Login login(String account, String password) {
        Account entry = account == null ? null : accounts.get(account.trim());
        if (entry == null || password == null || !MessageDigest.isEqual(entry.password(), bytes(password))) {
            return null;
        }
        Instant now = Instant.now();
        tokens.entrySet().removeIf(item -> !item.getValue().expires().isAfter(now));
        String token = UUID.randomUUID().toString();
        tokens.put(token, new Session(entry.user(), now.plus(LIFETIME)));
        return new Login(token, entry.user());
    }

    User user(String authorization) {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            return null;
        }
        String token = authorization.substring(7);
        Session session = tokens.get(token);
        if (session == null) {
            return null;
        }
        if (!session.expires().isAfter(Instant.now())) {
            tokens.remove(token, session);
            return null;
        }
        return session.user();
    }

    void revoke(String authorization) {
        if (authorization != null && authorization.startsWith("Bearer ")) {
            tokens.remove(authorization.substring(7));
        }
    }

    private static byte[] bytes(String value) {
        return value.getBytes(StandardCharsets.UTF_8);
    }
}