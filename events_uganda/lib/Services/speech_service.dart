import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  SpeechService._();

  static final SpeechService instance = SpeechService._();

  final SpeechToText _speech = SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _lastWords = '';

  bool get isListening => _listening;
  bool get isAvailable => _available;
  String get lastWords => _lastWords;

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
      partialResults: true,
      listenOptions: const SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
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
  }

  Future<void> cancel() async {
    await _speech.cancel();
    _listening = false;
    _lastWords = '';
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
