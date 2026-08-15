import 'package:events_uganda/Services/call_service.dart';
import 'package:events_uganda/Users/Customers/Call_Screen.dart';
import 'package:events_uganda/models/call_models.dart';
import 'package:flutter/material.dart';

/// Global overlay for the voice-call feature.
///
/// Mounted above every screen via MaterialApp.builder. Shows:
///  - an incoming-call card (accept / decline) when the app is not on the
///    CallScreen,
///  - a compact banner for outgoing ("Calling…") and active calls, tapping
///    which opens the full CallScreen.
/// Hidden while the CallScreen itself is on top.
class CallOverlay extends StatelessWidget {
  const CallOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final service = CallService.instance;
    return ValueListenableBuilder<CallStatus>(
      valueListenable: service.status,
      builder: (context, status, _) {
        if (status == CallStatus.idle) return const SizedBox.shrink();
        return ValueListenableBuilder<bool>(
          valueListenable: service.callScreenOpen,
          builder: (context, screenOpen, _) {
            if (screenOpen) return const SizedBox.shrink();
            if (status == CallStatus.ended ||
                status == CallStatus.rejected ||
                status == CallStatus.cancelled ||
                status == CallStatus.noAnswer ||
                status == CallStatus.busy ||
                status == CallStatus.unreachable) {
              return const SizedBox.shrink();
            }
            return Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: _Card(service: service, status: status),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.service, required this.status});

  final CallService service;
  final CallStatus status;

  void _openCallScreen(BuildContext context) {
    service.openCallScreen();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CallScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (status == CallStatus.incoming) {
      return _incomingCard(context);
    }
    if (status == CallStatus.connecting || status == CallStatus.outgoing) {
      return _banner(
        context,
        color: const Color(0xFFFFB74D),
        leading: const Icon(Icons.phone, color: Colors.white, size: 18),
        title: 'Calling ${service.peerName.value}…',
      );
    }
    return ValueListenableBuilder<Duration>(
      valueListenable: service.elapsed,
      builder: (context, elapsed, _) => _banner(
        context,
        color: const Color(0xFF25D366),
        leading: const Icon(Icons.phone, color: Colors.white, size: 18),
        title: '${service.peerName.value}',
        trailing: _formatElapsed(elapsed),
      ),
    );
  }

  Widget _banner(
    BuildContext context, {
    required Color color,
    required Widget leading,
    required String title,
    String? trailing,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      elevation: 6,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openCallScreen(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                Text(
                  trailing,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _incomingCard(BuildContext context) {
    return Material(
      color: const Color(0xFF1E2240),
      borderRadius: BorderRadius.circular(16),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFF3A3F63),
              child: const Icon(Icons.person, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    service.peerName.value ?? 'Unknown',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Incoming voice call…',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Decline',
              icon: const Icon(Icons.call_end, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
              ),
              onPressed: () => service.declineCall(),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Accept',
              icon: const Icon(Icons.call, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
              ),
              onPressed: () {
                service.acceptCall();
                _openCallScreen(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatElapsed(Duration d) {
    final two = (int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }
}
