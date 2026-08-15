package com.eventsuganda.otp.controller;

import com.eventsuganda.otp.dto.request.CallSignalRequest;
import com.eventsuganda.otp.service.CallService;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Controller;

import java.security.Principal;

/**
 * STOMP endpoints for call signaling. Identity comes from the JWT-backed
 * STOMP principal (StompAuthChannelInterceptor); CallService validates that
 * every sender is a participant of the call.
 */
@Controller
public class CallWebSocketController {

    private final CallService callService;

    public CallWebSocketController(CallService callService) {
        this.callService = callService;
    }

    @MessageMapping("/call.dial")
    public void dial(@Payload CallSignalRequest request, Principal principal) {
        if (principal == null || request == null) {
            return;
        }
        callService.dial(principal.getName(), request.getCalleeId(), request.getCallerName());
    }

    @MessageMapping("/call.cancel")
    public void cancel(@Payload CallSignalRequest request, Principal principal) {
        if (principal == null || request == null) {
            return;
        }
        callService.cancel(principal.getName(), request.getCallId());
    }

    @MessageMapping("/call.accept")
    public void accept(@Payload CallSignalRequest request, Principal principal) {
        if (principal == null || request == null) {
            return;
        }
        callService.accept(principal.getName(), request.getCallId(), request.getSdp());
    }

    @MessageMapping("/call.reject")
    public void reject(@Payload CallSignalRequest request, Principal principal) {
        if (principal == null || request == null) {
            return;
        }
        callService.reject(principal.getName(), request.getCallId());
    }

    @MessageMapping("/call.end")
    public void end(@Payload CallSignalRequest request, Principal principal) {
        if (principal == null || request == null) {
            return;
        }
        callService.end(principal.getName(), request.getCallId());
    }

    @MessageMapping("/call.sdp")
    public void sdp(@Payload CallSignalRequest request, Principal principal) {
        if (principal == null || request == null) {
            return;
        }
        callService.relaySdp(principal.getName(), request.getCallId(), request.getSdp());
    }

    @MessageMapping("/call.ice")
    public void ice(@Payload CallSignalRequest request, Principal principal) {
        if (principal == null || request == null) {
            return;
        }
        callService.relayIce(principal.getName(), request.getCallId(), request.getCandidate());
    }
}
