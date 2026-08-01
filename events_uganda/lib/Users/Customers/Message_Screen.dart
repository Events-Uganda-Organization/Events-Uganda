import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:events_uganda/Users/Customers/Empty_State_Art.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key, this.name, this.color, this.status});

  final String? name;
  final Color? color;
  final String? status;

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messagesScroll = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<Uint8List> _selectedImages = [];
  final List<Map<String, Object>> _messages = [];
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Stopwatch _recordingStopwatch = Stopwatch();
  final List<double> _waveSamples = [];
  final ValueNotifier<double> _voiceProgress = ValueNotifier<double>(0);
  Timer? _recordingTicker;
  StreamSubscription<Amplitude>? _amplitudeSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _playerStateSub;
  String? _recordingPath;
  bool _isRecording = false;
  bool _recordingLocked = false;
  double _cancelDragOffset = 0;
  double _lastAmplitude = 0.5;
  int? _playingVoiceIndex;
  bool _isPlayingVoice = false;

  @override
  void initState() {
    super.initState();
    _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _voiceProgress.value = 1;
        if (mounted) {
          setState(() {
            _isPlayingVoice = false;
            _playingVoiceIndex = null;
          });
        }
      }
    });
    _positionSub = _audioPlayer.positionStream.listen((position) {
      if (!_isPlayingVoice) return;
      final Duration? total = _audioPlayer.duration;
      if (total != null && total.inMilliseconds > 0) {
        _voiceProgress.value =
            (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
      }
    });
  }

  @override
  void dispose() {
    _recordingTicker?.cancel();
    _amplitudeSub?.cancel();
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _messageController.dispose();
    _messagesScroll.dispose();
    _voiceProgress.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  String _currentTime() {
    final now = TimeOfDay.now();
    final hour = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImages.isEmpty) return;
    setState(() {
      _messages.add({
        if (text.isNotEmpty) 'text': text,
        'time': _currentTime(),
        'mine': true,
        'date': DateTime.now(),
        if (_selectedImages.isNotEmpty) 'images': List<Uint8List>.of(_selectedImages),
      });
      _selectedImages.clear();
    });
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messagesScroll.hasClients) {
        _messagesScroll.animateTo(
          _messagesScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<String> _buildRecordingPath() async {
    if (kIsWeb) {
      return 'voice_${DateTime.now().millisecondsSinceEpoch}.webm';
    }
    final dir = await getTemporaryDirectory();
    return '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  void _onAmplitude(Amplitude amplitude) {
    _lastAmplitude = ((amplitude.current + 60) / 60).clamp(0.0, 1.0);
  }

  void _startRecordingTicker() {
    _recordingStopwatch..reset()..start();
    final math.Random random = math.Random();
    _recordingTicker = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted || !_isRecording) return;
      setState(() {
        final double base = _lastAmplitude + (random.nextDouble() - 0.5) * 0.12;
        _waveSamples.add(base.clamp(0.08, 1.0));
        if (_waveSamples.length > 44) _waveSamples.removeAt(0);
      });
    });
  }

  List<double> _recordingLevels() {
    const int count = 44;
    if (_waveSamples.length >= count) return _waveSamples;
    return [
      ...List<double>.filled(count - _waveSamples.length, 0.15),
      ..._waveSamples,
    ];
  }

  Future<bool> _startRecording() async {
    try {
      final bool permission = await _audioRecorder.hasPermission();
      if (!permission) {
        _showMicPermissionMessage();
        return false;
      }
      final String path = await _buildRecordingPath();
      final RecordConfig config = kIsWeb
          ? const RecordConfig(encoder: AudioEncoder.opus, bitRate: 64000)
          : const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000);
      await _audioRecorder.start(config, path: path);
      _amplitudeSub = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 120))
          .listen(_onAmplitude);
      if (!mounted) return false;
      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _recordingLocked = false;
        _cancelDragOffset = 0;
        _waveSamples.clear();
      });
      _startRecordingTicker();
      return true;
    } catch (_) {
      if (mounted) _showMicPermissionMessage();
      return false;
    }
  }

  Future<void> _stopRecording() async {
    _recordingTicker?.cancel();
    _recordingTicker = null;
    _recordingStopwatch.stop();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    try {
      final bool recording = await _audioRecorder.isRecording();
      if (recording) {
        final String? saved = await _audioRecorder.stop();
        if (saved != null && saved.isNotEmpty) _recordingPath = saved;
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordingLocked = false;
      _cancelDragOffset = 0;
    });
  }

  Future<void> _cancelRecording() async {
    _recordingTicker?.cancel();
    _recordingTicker = null;
    _recordingStopwatch.stop();
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    try {
      await _audioRecorder.cancel();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _recordingPath = null;
      _recordingLocked = false;
      _cancelDragOffset = 0;
      _waveSamples.clear();
    });
  }

  Future<void> _sendVoiceMessage() async {
    final Duration duration = _recordingStopwatch.elapsed;
    await _stopRecording();
    final String? path = _recordingPath;
    if (path == null || path.isEmpty || duration.inMilliseconds < 300) {
      await _cancelRecording();
      return;
    }
    if (!mounted) return;
    setState(() {
      _messages.add({
        'voice': path,
        'duration': duration,
        'time': _currentTime(),
        'mine': true,
        'date': DateTime.now(),
      });
      _recordingPath = null;
      _waveSamples.clear();
    });
    _scrollToBottom();
  }

  void _showMicPermissionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Microphone permission is required to record voice messages.',
        ),
      ),
    );
  }

  Future<void> _onMicTapped() async {
    if (_isRecording || _recordingPath != null) return;
    await _startRecording();
  }

  Future<void> _onMicLongPress() async {
    if (_isRecording || _recordingPath != null) return;
    await _startRecording();
  }

  void _onMicLongPressMove(LongPressMoveUpdateDetails details) {
    if (!_isRecording) return;
    final double dx = details.offsetFromOrigin.dx;
    final double dy = details.offsetFromOrigin.dy;
    setState(() {
      if (dy < -screenHeightUnit(context) * 0.08) {
        _recordingLocked = true;
        _cancelDragOffset = 0;
      } else {
        _cancelDragOffset = dx < -screenWidthUnit(context) * 0.25 ? dx : 0;
      }
    });
  }

  Future<void> _onMicLongPressEnd(LongPressEndDetails details) async {
    if (!_isRecording) return;
    if (_cancelDragOffset < -screenWidthUnit(context) * 0.25) {
      await _cancelRecording();
      return;
    }
    if (_recordingLocked) {
      setState(() => _cancelDragOffset = 0);
      return;
    }
    await _stopRecording();
  }

  void _onPanelPanUpdate(DragUpdateDetails details, double screenWidth) {
    if (!_isRecording) return;
    setState(() {
      if (_recordingLocked) {
        if (details.delta.dy > 0) {
          _cancelDragOffset += details.delta.dy;
          if (_cancelDragOffset > screenHeightUnit(context) * 0.03) {
            _recordingLocked = false;
            _cancelDragOffset = 0;
          }
        }
      } else {
        _cancelDragOffset = math.max(
          -screenWidth * 0.5,
          _cancelDragOffset + details.delta.dx,
        );
        if (details.delta.dy < -screenHeightUnit(context) * 0.04) {
          _recordingLocked = true;
          _cancelDragOffset = 0;
        }
      }
    });
  }

  Future<void> _onPanelPanEnd(DragEndDetails details) async {
    if (_cancelDragOffset < -screenWidthUnit(context) * 0.35) {
      await _cancelRecording();
    } else {
      setState(() => _cancelDragOffset = 0);
    }
  }

  void _toggleRecordingLock() {
    setState(() => _recordingLocked = !_recordingLocked);
  }

  Future<void> _playVoiceMessage(int index) async {
    final Map<String, Object> message = _messages[index];
    final String path = message['voice'] as String;
    try {
      if (_isPlayingVoice && _playingVoiceIndex == index) {
        await _audioPlayer.stop();
        if (!mounted) return;
        setState(() {
          _isPlayingVoice = false;
          _playingVoiceIndex = null;
        });
        _voiceProgress.value = 0;
        return;
      }
      await _audioPlayer.stop();
      if (kIsWeb) {
        await _audioPlayer.setUrl(path);
      } else {
        await _audioPlayer.setFilePath(path);
      }
      if (!mounted) return;
      setState(() {
        _isPlayingVoice = true;
        _playingVoiceIndex = index;
      });
      _voiceProgress.value = 0;
      await _audioPlayer.play();
    } catch (_) {}
  }

  List<double> _voiceBars(int index, Duration duration) {
    final math.Random random =
        math.Random(duration.inMilliseconds + index * 1000);
    return List<double>.generate(38, (_) => 0.25 + random.nextDouble() * 0.75);
  }

  Future<void> _showImageSourceSheet() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: screenHeightUnit(context) * 0.02),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Attach Photos',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidthUnit(context) * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenHeightUnit(context) * 0.015),
              _sheetOption(
                context,
                Icons.photo_camera,
                'Use Camera',
                ImageSource.camera,
              ),
              _sheetOption(
                context,
                Icons.photo_library,
                'Select from Gallery',
                ImageSource.gallery,
              ),
            ],
          ),
        ),
      ),
    );
    if (source == ImageSource.camera) {
      await _takePhoto();
    } else if (source == ImageSource.gallery) {
      await _pickFromGallery();
    }
  }

  Widget _sheetOption(
    BuildContext context,
    IconData icon,
    String label,
    ImageSource source,
  ) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFCD7C20), size: 30),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.black,
          fontSize: screenWidthUnit(context) * 0.04,
        ),
      ),
      onTap: () => Navigator.of(context).pop(source),
    );
  }

  Future<void> _takePhoto() async {
    final XFile? file = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedImages.add(bytes);
    });
  }

  Future<void> _pickFromGallery() async {
    final List<XFile> files = await _imagePicker.pickMultiImage(
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (files.isEmpty) return;
    final List<Uint8List> bytes = <Uint8List>[];
    for (final XFile file in files) {
      bytes.add(await file.readAsBytes());
    }
    if (!mounted) return;
    setState(() {
      _selectedImages.addAll(bytes);
    });
  }

  void _clearSelectedImages() {
    setState(() {
      _selectedImages.clear();
    });
  }

  void _openImageViewer(int initialIndex, List<Uint8List> images) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageViewerScreen(
          initialIndex: initialIndex,
          images: images,
        ),
      ),
    );
  }

  double screenWidthUnit(BuildContext context) =>
      MediaQuery.of(context).size.width;

  double screenHeightUnit(BuildContext context) =>
      MediaQuery.of(context).size.height;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateLabel(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime day = DateTime(date.year, date.month, date.day);
    final int difference = today.difference(day).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    final String dd = date.day.toString().padLeft(2, '0');
    final String mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  Widget _buildDateSeparator(String label, double screenWidth) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: screenWidth * 0.02,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenWidth * 0.01,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.7),
            fontSize: screenWidth * 0.028,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildImageFan(
    List<Uint8List> images,
    double screenWidth, {
    double cardFactor = 0.5,
  }) {
    final int shown = math.min(images.length, 4);
    final double cardWidth = screenWidth * cardFactor;
    final double cardHeight = screenWidth * cardFactor;
    final double step = cardHeight * 0.055;
    final double fanHeight = cardHeight + step * (shown - 1) + screenWidth * 0.08;
    return GestureDetector(
      onTap: () => _openImageViewer(0, images),
      child: SizedBox(
        width: cardWidth + screenWidth * 0.1,
        height: fanHeight,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            for (int i = shown - 1; i >= 0; i--)
              Positioned(
                top: (shown - 1 - i) * step,
                child: Transform.rotate(
                  angle: -0.04 - (shown - 1 - i) * 0.025,
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.memory(
                        images[i],
                        fit: BoxFit.cover,
                        width: cardWidth,
                        height: cardHeight,
                      ),
                    ),
                  ),
                ),
              ),
            if (images.length > shown)
              Positioned(
                right: screenWidth * 0.02,
                top: step * (shown - 1),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenWidth * 0.012,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '+${images.length - shown}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewStrip(double screenWidth, double screenHeight) {
    return Container(
      height: screenWidth * 0.36,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenWidth * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(2, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildImageFan(
                _selectedImages,
                screenWidth,
                cardFactor: 0.2,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearSelectedImages,
            child: Container(
              width: screenWidth * 0.09,
              height: screenWidth * 0.09,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: screenWidth * 0.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceBubble(
    Map<String, Object> message,
    int index,
    double screenWidth,
    double screenHeight,
  ) {
    final bool mine = message['mine'] as bool;
    final String time = message['time'] as String;
    final Duration duration = message['duration'] as Duration;
    final bool playing = _isPlayingVoice && _playingVoiceIndex == index;
    final Color accent = mine ? Colors.white : const Color(0xFFCD7C20);
    final List<double> bars = _voiceBars(index, duration);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.7),
        margin: EdgeInsets.only(
          top: screenHeight * 0.006,
          bottom: screenHeight * 0.006,
          left: mine ? screenWidth * 0.15 : 0,
          right: mine ? 0 : screenWidth * 0.15,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenHeight * 0.012,
        ),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFCD7C20) : Colors.white,
          borderRadius: mine
              ? const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(0),
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                )
              : const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(25),
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _playVoiceMessage(index),
              child: Container(
                width: screenWidth * 0.11,
                height: screenWidth * 0.11,
                decoration: BoxDecoration(
                  color: mine ? Colors.white : const Color(0xFFCD7C20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playing ? Icons.stop : Icons.play_arrow,
                  color: mine ? const Color(0xFFCD7C20) : Colors.white,
                  size: screenWidth * 0.06,
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: ValueListenableBuilder<double>(
                valueListenable: _voiceProgress,
                builder: (context, progress, _) {
                  final int played =
                      playing ? (progress * bars.length).round() : 0;
                  return SizedBox(
                    height: screenWidth * 0.06,
                    child: CustomPaint(
                      painter: _WaveformPainter(
                        levels: bars,
                        color: accent,
                        playedLevels: played,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    color: mine ? Colors.white : Colors.black,
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: screenHeight * 0.003),
                Text(
                  time,
                  style: TextStyle(
                    color: mine
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.black.withValues(alpha: 0.5),
                    fontSize: screenWidth * 0.024,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingPanel(double screenWidth, double screenHeight) {
    final bool cancelling = _cancelDragOffset < -screenWidth * 0.35;
    return GestureDetector(
      onPanUpdate: (details) => _onPanelPanUpdate(details, screenWidth),
      onPanEnd: _onPanelPanEnd,
      child: Transform.translate(
        offset: Offset(_cancelDragOffset, 0),
        child: Container(
          height: screenWidth * 0.128,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(2, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleRecordingLock,
                child: Container(
                  width: screenWidth * 0.09,
                  height: screenWidth * 0.09,
                  decoration: BoxDecoration(
                    color: _recordingLocked
                        ? const Color(0xFFCD7C20)
                        : Colors.black.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _recordingLocked ? Icons.lock : Icons.lock_open,
                    color: _recordingLocked ? Colors.white : Colors.black,
                    size: screenWidth * 0.05,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.015),
              Container(
                width: screenWidth * 0.09,
                height: screenWidth * 0.09,
                decoration: BoxDecoration(
                  color: cancelling
                      ? const Color(0xFFE53935)
                      : Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete,
                  color: cancelling ? Colors.white : const Color(0xFFE53935),
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: SizedBox(
                  height: screenWidth * 0.05,
                  child: CustomPaint(
                    painter: _WaveformPainter(
                      levels: _recordingLevels(),
                      color: const Color(0xFFCD7C20),
                      playedLevels: 0,
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                _formatDuration(_recordingStopwatch.elapsed),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              GestureDetector(
                onTap: _sendVoiceMessage,
                child: Container(
                  width: screenWidth * 0.095,
                  height: screenWidth * 0.095,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCD7C20),
                    shape: BoxShape.circle,
                  ),
                  child: Transform.rotate(
                    angle: math.pi * -45 / 180,
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: screenWidth * 0.045,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(
    Map<String, Object> message,
    int index,
    double screenWidth,
    double screenHeight,
  ) {
    final bool mine = message['mine'] as bool;
    final String time = message['time'] as String;
    final String text = message['text'] as String? ?? '';
    final List<Uint8List> images = message['images'] as List<Uint8List>? ?? const [];
    final bool hasImages = images.isNotEmpty;
    final String? voice = message['voice'] as String?;
    final bool hasVoice = voice != null && voice.isNotEmpty;

    if (hasVoice) {
      return _buildVoiceBubble(message, index, screenWidth, screenHeight);
    }

    if (hasImages) {
      return Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            top: screenHeight * 0.006,
            bottom: screenHeight * 0.006,
            left: mine ? screenWidth * 0.15 : 0,
            right: mine ? 0 : screenWidth * 0.15,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.01,
            vertical: screenHeight * 0.008,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildImageFan(images, screenWidth),
              if (text.isNotEmpty) ...[
                SizedBox(height: screenHeight * 0.006),
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ],
              SizedBox(height: screenHeight * 0.003),
              Text(
                time,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.5),
                  fontSize: screenWidth * 0.024,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: screenWidth * 0.7),
        margin: EdgeInsets.only(
          top: screenHeight * 0.006,
          bottom: screenHeight * 0.006,
          left: mine ? screenWidth * 0.15 : 0,
          right: mine ? 0 : screenWidth * 0.15,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenHeight * 0.012,
        ),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFCD7C20) : Colors.white,
          borderRadius: mine
              ? const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(0),
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                )
              : const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(25),
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                color: mine ? Colors.white : Colors.black,
                fontSize: screenWidth * 0.035,
              ),
            ),
            SizedBox(height: screenHeight * 0.003),
            Text(
              time,
              style: TextStyle(
                color: mine
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.5),
                fontSize: screenWidth * 0.024,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final List<Widget> chatItems = <Widget>[];
    DateTime? previousDate;
    for (int i = 0; i < _messages.length; i++) {
      final message = _messages[i];
      final DateTime date = message['date'] as DateTime;
      if (previousDate == null || !_isSameDay(previousDate, date)) {
        chatItems.add(_buildDateSeparator(_dateLabel(date), screenWidth));
      }
      chatItems.add(_buildBubble(message, i, screenWidth, screenHeight));
      previousDate = date;
    }

    final bool hasPreview = _selectedImages.isNotEmpty;
    final double previewHeight =
        hasPreview ? screenWidth * 0.36 + screenHeight * 0.01 : 0;
    final double recordingBarHeight = _recordingPath != null
        ? screenWidth * 0.128 + screenHeight * 0.01
        : 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: screenHeight * 0.0,
              bottom: screenHeight * 0.0,
              right: (screenWidth + screenWidth * 1) / 300,
              child: Image.asset(
                'assets/backgroundcolors/normalscreen.png',
                width: screenWidth * 1.08,
                height: screenHeight * 0.9,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: screenHeight * 0.035,
              left: screenWidth * 0.04,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: screenWidth * 0.128,
                  height: screenWidth * 0.128,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8C2B0),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.black,
                      size: screenWidth * 0.10,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top:
                  screenHeight * 0.035 +
                  (screenWidth * 0.128 - screenWidth * 0.146) / 2,
              left:
                  screenWidth * 0.04 + screenWidth * 0.128 + screenWidth * 0.03,
              child: Container(
                width: screenWidth * 0.146,
                height: screenWidth * 0.146,
                decoration: BoxDecoration(
                  color: widget.color ?? const Color(0xFF7EED27),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.name != null && widget.name!.isNotEmpty
                        ? widget.name![0]
                        : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top:
                  screenHeight * 0.035 +
                  (screenWidth * 0.128 - screenWidth * 0.146) / 2,
              left:
                  screenWidth * 0.04 +
                  screenWidth * 0.128 +
                  screenWidth * 0.03 +
                  screenWidth * 0.146 +
                  screenWidth * 0.03,
              right: screenWidth * 0.04,
              height: screenWidth * 0.146,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.003),
                        Text(
                          widget.status ?? 'Online',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                (widget.status ?? 'Online')
                                    .toLowerCase()
                                    .contains('online')
                                ? const Color(0xFF4CAF50)
                                : Colors.black.withValues(alpha: 0.5),
                            fontSize: screenWidth * 0.028,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Icon(
                    Icons.phone_outlined,
                    color: const Color(0xFFCD7C20),
                    size: screenWidth * 0.08,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Icon(
                    Icons.more_vert,
                    color: Colors.black,
                    size: screenWidth * 0.08,
                  ),
                ],
              ),
            ),
            Positioned(
              top:
                  screenHeight * 0.035 +
                  screenWidth * 0.146 +
                  screenHeight * 0.01,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              bottom:
                  screenHeight * 0.02 +
                  screenWidth * 0.128 +
                  screenHeight * 0.015 +
                  previewHeight +
                  recordingBarHeight,
              child: _messages.isEmpty
                  ? _MessageEmptyState(
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    )
                  : ListView(
                      controller: _messagesScroll,
                      padding: EdgeInsets.zero,
                      children: chatItems,
                    ),
            ),
            Positioned(
              bottom: screenHeight * 0.02,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hasPreview) ...[
                    _buildPreviewStrip(screenWidth, screenHeight),
                    SizedBox(height: screenHeight * 0.01),
                  ],
                  if (_recordingPath != null) ...[
                    _buildRecordingPanel(screenWidth, screenHeight),
                    SizedBox(height: screenHeight * 0.01),
                  ],
                  Row(
                children: [
                  GestureDetector(
                    onTap: _showImageSourceSheet,
                    child: Container(
                      width: screenWidth * 0.128,
                      height: screenWidth * 0.128,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: screenWidth * 0.07,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Expanded(
                    child: Container(
                      height: screenWidth * 0.128,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(2, 7),
                          ),
                        ],
                      ),
                      child: SizedBox.expand(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              onSubmitted: (_) => _sendMessage(),
                              textAlignVertical: TextAlignVertical.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.035,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Type Message Here...',
                                hintStyle: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  fontSize: screenWidth * 0.032,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: 0,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              width: screenWidth * 0.095,
                              height: screenWidth * 0.095,
                              margin: EdgeInsets.only(
                                right: screenWidth * 0.02,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0xFFCD7C20),
                                shape: BoxShape.circle,
                              ),
                              child: Transform.rotate(
                                angle: math.pi * -45 / 180,
                                child: Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: screenWidth * 0.045,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  GestureDetector(
                    onTap: _onMicTapped,
                    onLongPress: _onMicLongPress,
                    onLongPressMoveUpdate: _onMicLongPressMove,
                    onLongPressEnd: _onMicLongPressEnd,
                    child: Container(
                      width: screenWidth * 0.128,
                      height: screenWidth * 0.128,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFCD7C20),
                            Color(0xFFF4F4F4),
                            Color(0xFFF5F5F5),
                            Color(0xFFCD7C20),
                          ],
                          stops: [0.0, 0.13, 0.19, 0.83],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: _isRecording
                              ? const Color(0xFFE53935)
                              : Colors.black,
                          size: screenWidth * 0.07,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.levels,
    required this.color,
    required this.playedLevels,
  });

  final List<double> levels;
  final Color color;
  final int playedLevels;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty || size.width <= 0 || size.height <= 0) return;
    final double count = levels.length.toDouble();
    final double gap = size.width * 0.03;
    final double barWidth = (size.width - gap * (count - 1)) / count;
    if (barWidth <= 0) return;
    final Paint paint = Paint();
    for (int i = 0; i < levels.length; i++) {
      final double height = levels[i].clamp(0.06, 1.0) * size.height;
      final double x = i * (barWidth + gap);
      paint.color = i < playedLevels ? color : color.withValues(alpha: 0.4);
      final RRect rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - height) / 2, barWidth, height),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) {
    return oldDelegate.levels != levels ||
        oldDelegate.playedLevels != playedLevels ||
        oldDelegate.color != color;
  }
}

class _ImageViewerScreen extends StatefulWidget {
  const _ImageViewerScreen({required this.initialIndex, required this.images});

  final int initialIndex;
  final List<Uint8List> images;

  @override
  State<_ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<_ImageViewerScreen> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) => InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: Image.memory(
                  widget.images[index],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 26),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
