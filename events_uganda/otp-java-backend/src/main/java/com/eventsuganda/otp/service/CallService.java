package com.eventsuganda.otp.service;

import com.eventsuganda.otp.dto.response.CallSignalResponse;
import com.eventsuganda.otp.model.Call;
import com.eventsuganda.otp.repository.CallRepository;
import jakarta.annotation.PreDestroy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;

/**
 * Call lifecycle + WebRTC signaling relay.
 *
 * Keeps an in-memory registry of live calls (mirroring {@link PresenceService})
 * and routes every signal over the user STOMP queue {@code /queue/calls}.
 * Calls left ringing are auto-terminated as NO_ANSWER after 30s. Terminated
 * calls are persisted for history.
 */
@Service
public class CallService {

    private static final Logger log = LoggerFactory.getLogger(CallService.class);
    private static final String CALLS_QUEUE = "/queue/calls";
    private static final long RING_TIMEOUT_MS = 30_000;

    private final SimpMessagingTemplate messagingTemplate;
    private final PresenceService presenceService;
    private final CallRepository callRepository;

    private final Map<String, Call> calls = new ConcurrentHashMap<>();
    private final Map<String, String> activeByUser = new ConcurrentHashMap<>();
    private final Map<String, ScheduledFuture<?>> ringTimers = new ConcurrentHashMap<>();
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);

    public CallService(SimpMessagingTemplate messagingTemplate,
                       PresenceService presenceService,
                       CallRepository callRepository) {
        this.messagingTemplate = messagingTemplate;
        this.presenceService = presenceService;
        this.callRepository = callRepository;
    }

    @PreDestroy
    void shutdown() {
        scheduler.shutdownNow();
    }

    /**
     * Caller requests a call to {@code calleeId}. Rings the callee if they are
     * online and free, otherwise replies UNREACHABLE / BUSY immediately.
     */
    public void dial(String callerId, String calleeId, String callerName, String sdp) {
        if (callerId == null || callerId.isEmpty()
                || calleeId == null || calleeId.isEmpty()) {
            return;
        }
        if (callerId.equals(calleeId)) {
            return;
        }

        if (!presenceService.isOnline(calleeId)) {
            notifyUser(callerId, CallSignalResponse.of("call.unreachable", null)
                .callerId(callerId).calleeId(calleeId)
                .message("User is offline"));
            log.info("Call dial unreachable caller={} callee={}", callerId, calleeId);
            return;
        }
        if (activeByUser.containsKey(callerId) || activeByUser.containsKey(calleeId)) {
            notifyUser(callerId, CallSignalResponse.of("call.busy", null)
                .callerId(callerId).calleeId(calleeId)
                .message("User is on another call"));
            log.info("Call dial busy caller={} callee={}", callerId, calleeId);
            return;
        }

        Call call = new Call(UUID.randomUUID().toString(), callerId, calleeId);
        calls.put(call.getId(), call);
        activeByUser.put(callerId, call.getId());
        activeByUser.put(calleeId, call.getId());

        notifyUser(calleeId, CallSignalResponse.of("call.incoming", call.getId())
            .callerId(callerId).calleeId(calleeId).callerName(callerName).sdp(sdp));
        notifyUser(callerId, CallSignalResponse.of("call.ringing", call.getId())
            .callerId(callerId).calleeId(calleeId));

        ringTimers.put(call.getId(), scheduler.schedule(
            () -> handleRingTimeout(call.getId()), RING_TIMEOUT_MS, TimeUnit.MILLISECONDS));

        log.info("Call {} started caller={} callee={}", call.getId(), callerId, calleeId);
    }

    /** Callee accepts an incoming call; replies to the caller with their answer SDP. */
    public void accept(String userId, String callId, String sdp) {
        Call call = byId(callId);
        if (call == null || !call.getCalleeId().equals(userId)) {
            return;
        }
        synchronized (call) {
            if (!Call.Status.RINGING.name().equals(call.getStatus())) {
                return;
            }
            call.setStatus(Call.Status.CONNECTED.name());
            call.setStartedAt(System.currentTimeMillis());
        }
        cancelRingTimer(callId);
        notifyUser(call.getCallerId(), CallSignalResponse.of("call.accepted", callId)
            .callerId(call.getCallerId()).calleeId(call.getCalleeId())
            .sdp(sdp).startedAt(call.getStartedAt()));
        notifyUser(call.getCalleeId(), CallSignalResponse.of("call.accepted", callId)
            .callerId(call.getCallerId()).calleeId(call.getCalleeId())
            .sdp(sdp).startedAt(call.getStartedAt()));
        log.info("Call {} accepted by {}", callId, userId);
    }

    /** Callee declines an incoming call. */
    public void reject(String userId, String callId) {
        Call call = byId(callId);
        if (call == null || !call.getCalleeId().equals(userId)) {
            return;
        }
        synchronized (call) {
            if (!Call.Status.RINGING.name().equals(call.getStatus())) {
                return;
            }
            call.setStatus(Call.Status.REJECTED.name());
            call.setEndedAt(System.currentTimeMillis());
            call.setDurationMs(0L);
        }
        finish(call);
        notifyUser(call.getCallerId(), CallSignalResponse.of("call.rejected", callId)
            .callerId(call.getCallerId()).calleeId(call.getCalleeId()));
        log.info("Call {} rejected by {}", callId, userId);
    }

    /** Caller cancels while still ringing. */
    public void cancel(String userId, String callId) {
        Call call = byId(callId);
        if (call == null || !call.getCallerId().equals(userId)) {
            return;
        }
        synchronized (call) {
            if (!Call.Status.RINGING.name().equals(call.getStatus())) {
                return;
            }
            call.setStatus(Call.Status.CANCELLED.name());
            call.setEndedAt(System.currentTimeMillis());
            call.setDurationMs(0L);
        }
        finish(call);
        notifyUser(call.getCalleeId(), CallSignalResponse.of("call.cancelled", callId)
            .callerId(call.getCallerId()).calleeId(call.getCalleeId()));
        log.info("Call {} cancelled by {}", callId, userId);
    }

    /** Either party ends the call (connected, ringing, or any live state). */
    public void end(String userId, String callId) {
        Call call = byId(callId);
        if (call == null || !isParticipant(call, userId)) {
            return;
        }
        synchronized (call) {
            String status = call.getStatus();
            if (isTerminal(status)) {
                return;
            }
            if (Call.Status.CONNECTED.name().equals(status)) {
                long now = System.currentTimeMillis();
                call.setDurationMs(call.getStartedAt() == null ? 0L : now - call.getStartedAt());
                call.setEndedAt(now);
                call.setStatus(Call.Status.ENDED.name());
            } else if (call.getCallerId().equals(userId)) {
                call.setStatus(Call.Status.CANCELLED.name());
                call.setEndedAt(System.currentTimeMillis());
                call.setDurationMs(0L);
            } else {
                call.setStatus(Call.Status.REJECTED.name());
                call.setEndedAt(System.currentTimeMillis());
                call.setDurationMs(0L);
            }
        }
        finish(call);
        notifyUser(call.getCallerId(), CallSignalResponse.of("call.ended", callId)
            .callerId(call.getCallerId()).calleeId(call.getCalleeId()).durationMs(call.getDurationMs()));
        notifyUser(call.getCalleeId(), CallSignalResponse.of("call.ended", callId)
            .callerId(call.getCallerId()).calleeId(call.getCalleeId()).durationMs(call.getDurationMs()));
        log.info("Call {} ended by {} status={} durationMs={}",
            callId, userId, call.getStatus(), call.getDurationMs());
    }

    /** Relays a renegotiation SDP (e.g. video later) to the other party. */
    public void relaySdp(String userId, String callId, String sdp) {
        Call call = byId(callId);
        if (call == null || sdp == null) {
            return;
        }
        String other = otherParty(call, userId);
        if (other == null) {
            return;
        }
        notifyUser(other, CallSignalResponse.of("call.sdp", callId)
            .callerId(call.getCallerId()).calleeId(call.getCalleeId()).sdp(sdp));
    }

    /** Relays an ICE candidate to the other party. */
    public void relayIce(String userId, String callId, String candidate) {
        Call call = byId(callId);
        if (call == null || candidate == null) {
            return;
        }
        String other = otherParty(call, userId);
        if (other == null) {
            return;
        }
        notifyUser(other, CallSignalResponse.of("call.ice", callId)
            .callerId(call.getCallerId()).calleeId(call.getCalleeId()).candidate(candidate));
    }

    private void handleRingTimeout(String callId) {
        Call call = calls.get(callId);
        if (call == null) {
            return;
        }
        synchronized (call) {
            if (!Call.Status.RINGING.name().equals(call.getStatus())) {
                return;
            }
            call.setStatus(Call.Status.NO_ANSWER.name());
            call.setEndedAt(System.currentTimeMillis());
            call.setDurationMs(0L);
        }
        finish(call);
        notifyUser(call.getCallerId(), CallSignalResponse.of("call.noanswer", callId)
            .callerId(call.getCallerId()).calleeId(call.getCalleeId()));
        notifyUser(call.getCalleeId(), CallSignalResponse.of("call.noanswer", callId)
            .callerId(call.getCallerId()).calleeId(call.getCalleeId()));
        log.info("Call {} no answer", callId);
    }

    private void finish(Call call) {
        cancelRingTimer(call.getId());
        calls.remove(call.getId());
        activeByUser.remove(call.getCallerId(), call.getId());
        activeByUser.remove(call.getCalleeId(), call.getId());
        try {
            callRepository.save(call);
        } catch (Exception e) {
            log.error("Failed to persist call {}", call.getId(), e);
        }
    }

    private void cancelRingTimer(String callId) {
        ScheduledFuture<?> timer = ringTimers.remove(callId);
        if (timer != null) {
            timer.cancel(false);
        }
    }

    private Call byId(String callId) {
        if (callId == null) {
            return null;
        }
        return calls.get(callId);
    }

    private boolean isParticipant(Call call, String userId) {
        return call.getCallerId().equals(userId) || call.getCalleeId().equals(userId);
    }

    private String otherParty(Call call, String userId) {
        if (call.getCallerId().equals(userId)) {
            return call.getCalleeId();
        }
        if (call.getCalleeId().equals(userId)) {
            return call.getCallerId();
        }
        return null;
    }

    private boolean isTerminal(String status) {
        return Call.Status.ENDED.name().equals(status)
            || Call.Status.REJECTED.name().equals(status)
            || Call.Status.CANCELLED.name().equals(status)
            || Call.Status.NO_ANSWER.name().equals(status);
    }

    private void notifyUser(String userId, CallSignalResponse signal) {
        if (userId == null || userId.isEmpty()) {
            return;
        }
        messagingTemplate.convertAndSendToUser(userId, CALLS_QUEUE, signal);
    }
}
