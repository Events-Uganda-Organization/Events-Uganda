package com.eventsuganda.otp.service;

import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Service;
import org.springframework.web.socket.messaging.SessionConnectedEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

import java.security.Principal;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Tracks which users have an active STOMP/WebSocket session, so the chat
 * service can tell whether a message recipient is online at send time
 * (delivery tick semantics).
 */
@Service
public class PresenceService {

    private final Map<String, Set<String>> userSessions = new ConcurrentHashMap<>();

    @EventListener
    public void onSessionConnected(SessionConnectedEvent event) {
        Principal user = event.getUser();
        if (user == null || user.getName() == null || user.getName().isEmpty()) {
            return;
        }
        String sessionId = StompHeaderAccessor.wrap(event.getMessage()).getSessionId();
        if (sessionId == null) {
            sessionId = user.getName();
        }
        userSessions
            .computeIfAbsent(user.getName(), key -> ConcurrentHashMap.newKeySet())
            .add(sessionId);
    }

    @EventListener
    public void onSessionDisconnected(SessionDisconnectEvent event) {
        Principal user = event.getUser();
        if (user == null || user.getName() == null || user.getName().isEmpty()) {
            return;
        }
        String sessionId = StompHeaderAccessor.wrap(event.getMessage()).getSessionId();
        Set<String> sessions = userSessions.get(user.getName());
        if (sessions == null) {
            return;
        }
        if (sessionId != null) {
            sessions.remove(sessionId);
        }
        if (sessions.isEmpty()) {
            userSessions.remove(user.getName());
        }
    }

    public boolean isOnline(String userId) {
        if (userId == null || userId.isEmpty()) {
            return false;
        }
        Set<String> sessions = userSessions.get(userId);
        return sessions != null && !sessions.isEmpty();
    }
}
