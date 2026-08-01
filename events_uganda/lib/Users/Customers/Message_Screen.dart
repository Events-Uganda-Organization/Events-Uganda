import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'text': text, 'time': _currentTime(), 'mine': true});
    });
    _messageController.clear();
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

  Widget _buildBubble(
    Map<String, Object> message,
    double screenWidth,
    double screenHeight,
  ) {
    final bool mine = message['mine'] as bool;
    final String text = message['text'] as String;
    final String time = message['time'] as String;
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
                  screenHeight * 0.015,
              child: ListView.builder(
                controller: _messagesScroll,
                padding: EdgeInsets.zero,
                itemCount: _messages.length,
                itemBuilder: (context, index) =>
                    _buildBubble(_messages[index], screenWidth, screenHeight),
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.02,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: Row(
                children: [
                  Container(
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
            ),
          ],
        ),
      ),
    );
  }
}
