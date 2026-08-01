import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

  @override
  void initState() {
    super.initState();
    final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
    _messages.addAll([
      {
        'text': 'Welcome! How can we help you today?',
        'time': '9:00 AM',
        'mine': false,
        'date': yesterday,
      },
      {
        'text': 'Feel free to type a message below.',
        'time': '9:00 AM',
        'mine': false,
        'date': yesterday,
      },
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messagesScroll.dispose();
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
      height: screenWidth * 0.34,
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
                cardFactor: 0.22,
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

  Widget _buildBubble(
    Map<String, Object> message,
    double screenWidth,
    double screenHeight,
  ) {
    final bool mine = message['mine'] as bool;
    final String time = message['time'] as String;
    final String text = message['text'] as String? ?? '';
    final List<Uint8List> images = message['images'] as List<Uint8List>? ?? const [];
    final bool hasImages = images.isNotEmpty;

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
    for (final message in _messages) {
      final DateTime date = message['date'] as DateTime;
      if (previousDate == null || !_isSameDay(previousDate, date)) {
        chatItems.add(_buildDateSeparator(_dateLabel(date), screenWidth));
      }
      chatItems.add(_buildBubble(message, screenWidth, screenHeight));
      previousDate = date;
    }

    final bool hasPreview = _selectedImages.isNotEmpty;
    final double previewHeight =
        hasPreview ? screenWidth * 0.34 + screenHeight * 0.01 : 0;

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
                  previewHeight,
              child: ListView(
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
                  Container(
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
                        Icons.mic,
                        color: Colors.black,
                        size: screenWidth * 0.07,
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
