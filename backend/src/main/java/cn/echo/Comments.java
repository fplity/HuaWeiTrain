package cn.echo;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketHandler;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator;
import org.springframework.web.socket.handler.TextWebSocketHandler;
import org.springframework.web.socket.server.HandshakeInterceptor;

@Component
class Comments extends TextWebSocketHandler {
    private static final Logger LOG = LoggerFactory.getLogger(Comments.class);
    private static final int MAX_HISTORY = 100;
    private static final String AUTH = "authorization";

    record Comment(long id, int songId, String nickname, String text, long createdAt) {}
    private record Event(String type, int songId, Comment comment) {}
    private record Client(WebSocketSession socket, String authorization, int songId) {}

    private final Sessions sessions;
    private final Catalog catalog;
    private final ObjectMapper json;
    private final AtomicLong sequence = new AtomicLong();
    private final Map<Integer, Deque<Comment>> histories = new ConcurrentHashMap<>();
    private final Map<String, Client> clients = new ConcurrentHashMap<>();

    Comments(Sessions sessions, Catalog catalog, ObjectMapper json) {
        this.sessions = sessions;
        this.catalog = catalog;
        this.json = json;
    }

    HandshakeInterceptor authentication() {
        return new HandshakeInterceptor() {
            @Override
            public boolean beforeHandshake(ServerHttpRequest request, ServerHttpResponse response,
                    WebSocketHandler handler, Map<String, Object> attributes) {
                String auth = request.getHeaders().getFirst(HttpHeaders.AUTHORIZATION);
                Sessions.User user = sessions.user(auth);
                if (user == null || !user.role().equals("listener")) {
                    response.setStatusCode(user == null ? HttpStatus.UNAUTHORIZED : HttpStatus.FORBIDDEN);
                    return false;
                }
                attributes.put(AUTH, auth);
                return true;
            }

            @Override
            public void afterHandshake(ServerHttpRequest request, ServerHttpResponse response,
                    WebSocketHandler handler, Exception error) {}
        };
    }

    List<Comment> history(int songId) {
        Deque<Comment> items = histories.get(songId);
        if (items == null) {
            return List.of();
        }
        synchronized (items) {
            return List.copyOf(items);
        }
    }

    Comment publish(int songId, Sessions.User user, String text) {
        Comment comment = new Comment(sequence.incrementAndGet(), songId, user.nickname(), text,
            System.currentTimeMillis());
        Deque<Comment> items = histories.computeIfAbsent(songId, id -> new ArrayDeque<>());
        synchronized (items) {
            items.addFirst(comment);
            if (items.size() > MAX_HISTORY) {
                items.removeLast();
            }
        }
        for (Client client : clients.values()) {
            if (client.songId() == songId) {
                if (sessions.user(client.authorization()) == null) {
                    disconnect(client.socket(), CloseStatus.POLICY_VIOLATION);
                } else {
                    send(client.socket(), new Event("comment", songId, comment));
                }
            }
        }
        return comment;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        session.setTextMessageSizeLimit(2048);
        clients.put(session.getId(), new Client(new ConcurrentWebSocketSessionDecorator(session, 2000, 65536),
            (String) session.getAttributes().get(AUTH), 0));
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        Client client = clients.get(session.getId());
        if (client == null || sessions.user(client.authorization()) == null) {
            disconnect(session, CloseStatus.POLICY_VIOLATION);
            return;
        }
        JsonNode request;
        try {
            request = json.readTree(message.getPayload());
        } catch (IOException error) {
            disconnect(client.socket(), CloseStatus.BAD_DATA);
            return;
        }
        if (request == null || !request.isObject()) {
            disconnect(client.socket(), CloseStatus.BAD_DATA);
            return;
        }
        switch (request.path("type").asText()) {
            case "ping" -> send(client.socket(), new Event("pong", client.songId(), null));
            case "subscribe" -> {
                int songId = request.path("songId").asInt();
                if (catalog.hasSong(songId) && clients.replace(session.getId(), client,
                        new Client(client.socket(), client.authorization(), songId))) {
                    send(client.socket(), new Event("subscribed", songId, null));
                }
            }
            default -> disconnect(client.socket(), CloseStatus.BAD_DATA);
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        clients.remove(session.getId());
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable error) {
        LOG.debug("Comment WebSocket transport interrupted");
        disconnect(session, CloseStatus.SERVER_ERROR);
    }

    private void send(WebSocketSession socket, Event event) {
        try {
            socket.sendMessage(new TextMessage(json.writeValueAsString(event)));
        } catch (IOException | IllegalStateException error) {
            disconnect(socket, CloseStatus.SERVER_ERROR);
        }
    }

    private void disconnect(WebSocketSession socket, CloseStatus status) {
        clients.remove(socket.getId());
        try {
            socket.close(status);
        } catch (IOException error) {
            LOG.debug("Comment WebSocket already unavailable");
        }
    }
}