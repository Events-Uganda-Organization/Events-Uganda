import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  SpeechService._();

  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _lastWords = '';
  double _lastLevel = 0.0;

  final StreamController<double> _levelCtrl =
      StreamController<double>.broadcast();

  bool get isListening => _listening;
  bool get isAvailable => _available;
  String get lastWords => _lastWords;
  double get lastLevel => _lastLevel;

  /// Live microphone sound level (0.0 - 1.0) while listening.
  Stream<double> get soundLevels => _levelCtrl.stream;

  Future<bool> initialize() async {
    if (_available) return true;
    _available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _listening = false;
        }
      },
      onError: (error) {
        _listening = false;
      },
    );
    return _available;
  }

  Future<bool> start({
    required void Function(String partial) onPartial,
    required void Function(String finalText) onResult,
    Duration listenFor = const Duration(seconds: 30),
  }) async {
    if (!_available) {
      _available = await initialize();
      if (!_available) return false;
    }
    if (_listening) return true;
    _lastWords = '';
    final bool started = await _speech.listen(
      listenFor: listenFor,
      localeId: 'en_US',
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
      onSoundLevelChange: (level) {
        _lastLevel = level;
        _levelCtrl.add(level);
      },
      onResult: (SpeechRecognitionResult result) {
        _lastWords = result.recognizedWords;
        if (result.finalResult) {
          onResult(result.recognizedWords);
        } else {
          onPartial(result.recognizedWords);
        }
      },
    );
    _listening = started;
    return started;
  }

  Future<void> stop() async {
    await _speech.stop();
    _listening = false;
    _lastLevel = 0.0;
    _levelCtrl.add(0.0);
  }

  Future<void> cancel() async {
    await _speech.cancel();
    _listening = false;
    _lastWords = '';
    _lastLevel = 0.0;
    _levelCtrl.add(0.0);
  }
}

String structureSpokenText(String raw) {
  String text = raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  text = text.replaceAll(
    RegExp(r'\b(um+|uh+|er+|erm+|hmm+|mm+)\b', caseSensitive: false),
    ' ',
  );

  text = text.replaceAll(
    RegExp(r'\b(\w+)\s+\1\b', caseSensitive: false),
    r'$1',
  );

  text = text.replaceFirst(
    RegExp(r'^(like|you know|so|basically|i mean)\s+', caseSensitive: false),
    '',
  );

  text = text
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .replaceAll(RegExp(r'[.!?,]+$'), '')
      .trim();

  if (text.isEmpty) return '';

  return text[0].toUpperCase() + text.substring(1);
}
