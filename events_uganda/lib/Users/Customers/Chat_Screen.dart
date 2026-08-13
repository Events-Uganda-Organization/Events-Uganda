import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/Services/chat_service.dart';
import 'package:events_uganda/Services/chat_socket_service.dart';
import 'package:events_uganda/Services/speech_service.dart';
import 'package:events_uganda/Users/Customers/Customer_Home_Screen.dart';
import 'package:events_uganda/Users/Customers/Customer_Profile_Screen.dart';
import 'package:events_uganda/Users/Customers/Empty_State_Art.dart';
import 'package:events_uganda/Users/NotificationScreen.dart';
import 'package:events_uganda/Users/Customers/Message_Screen.dart';
import 'package:events_uganda/components/Bottom_Navbar.dart';
import 'package:events_uganda/components/snackbar_helper.dart';

enum _ChatMenuAction {
  newMessage,
  markAllRead,
  notifications,
  help,
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _currentNavIndex = 2;
  final FocusNode _searchFocus = FocusNode();
  bool _isSearchFocused = false;
  static const List<Color> _avatarPalette = [
    Color(0xFF7EED27),
    Color(0xFFFF6B6B),
    Color(0xFF4D96FF),
    Color(0xFFFFA94D),
    Color(0xFFB197FC),
    Color(0xFF63E6BE),
    Color(0xFFF783AC),
  ];

  static Color _colorFor(String name) {
    const colors = {'Gregory': Color(0xFF20C997), 'Sarah': Color(0xFFFFD43B)};
    final special = colors[name];
    if (special != null) return special;
    final index = name.codeUnits.fold<int>(
      0,
      (acc, c) => (acc + c) % _avatarPalette.length,
    );
    return _avatarPalette[index];
  }

  List<Map<String, String>> get _recentContacts {
    final contacts = <Map<String, String>>[];
    for (final conv in _conversations) {
      final name = _conversationNames[conv.id] ?? 'Vendor';
      contacts.add({'conversationId': conv.id, 'name': name});
      if (contacts.length >= 7) break;
    }
    return contacts;
  }

  final List<ChatConversation> _conversations = [];
  final Map<String, String> _conversationNames = {};
  bool _isLoadingConversations = false;
  StreamSubscription<ChatMessage>? _socketSub;
  final List<double> _waveSamples = [];
  StreamSubscription<double>? _levelSub;
  Timer? _waveTicker;
  double _lastWaveLevel = 0.15;
  bool _receivedWaveLevel = false;

  void _startWave() {
    _levelSub?.cancel();
    _waveTicker?.cancel();
    _waveSamples.clear();
    _lastWaveLevel = 0.15;
    _receivedWaveLevel = false;
    _levelSub = SpeechService.instance.soundLevels.listen((level) {
      _receivedWaveLevel = true;
      _lastWaveLevel = level.clamp(0.05, 1.0);
    });
    _waveTicker = Timer.periodic(const Duration(milliseconds: 110), (_) {
      if (!mounted || !_isListening) return;
      setState(() {
        final double jitter = (math.Random().nextDouble() - 0.5) * 0.1;
        final double base = _receivedWaveLevel
            ? _lastWaveLevel
            : 0.2 + math.Random().nextDouble() * 0.06;
        _waveSamples.add((base + jitter).clamp(0.08, 1.0));
        if (_waveSamples.length > 36) _waveSamples.removeAt(0);
      });
    });
  }

  void _stopWave() {
    _levelSub?.cancel();
    _levelSub = null;
    _waveTicker?.cancel();
    _waveTicker = null;
    _waveSamples.clear();
  }
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  ChatSearchResults? _searchResults;
  bool _isSearching = false;
  bool _isListening = false;
  bool _handledResult = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocus.hasFocus;
      });
    });
    _loadConversations();
    _initSocket();
  }

  void _initSocket() {
    final socket = ChatSocketService.instance;
    socket.ensureConnected();
    _socketSub = socket.messages.listen((_) {
      _loadConversations();
    });
  }

  Future<void> _loadConversations() async {
    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          _conversations.clear();
          _conversationNames.clear();
          _isLoadingConversations = false;
        });
      }
      return;
    }
    setState(() {
      _isLoadingConversations = true;
    });
    try {
      final myId = await ChatService.myUserId();
      final List<ChatConversation> list =
          await ChatService.getConversations();
      final names = <String, String>{};
      for (final conversation in list) {
        final otherId = conversation.otherParticipantId(myId);
        String name = otherId == null ? '' : await ChatService.nameFor(otherId);
        if (name.isEmpty) name = 'Vendor';
        names[conversation.id] = name;
      }
      if (!mounted) return;
      setState(() {
        _conversations
          ..clear()
          ..addAll(list);
        _conversationNames
          ..clear()
          ..addAll(names);
        _isLoadingConversations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingConversations = false;
      });
    }
  }

  String _conversationTime(DateTime? time) {
    if (time == null) return '';
    final TimeOfDay t = TimeOfDay.fromDateTime(time);
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() {});
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _searchQuery = '';
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query;
        _isSearching = true;
      });
      _runSearch(query);
    });
  }

  Future<void> _runSearch(String query) async {
    try {
      final results = await ChatService.searchChat(query);
      if (!mounted || _searchQuery != query) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted || _searchQuery != query) return;
      setState(() {
        _searchResults = const ChatSearchResults();
        _isSearching = false;
      });
    }
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = null;
      _isSearching = false;
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _handledResult = false;
      await SpeechService.instance.stop();
      _stopWave();
      if (!_handledResult) {
        _applyTranscript(SpeechService.instance.lastWords);
      }
      return;
    }

    final speech = SpeechService.instance;
    final bool available = await speech.initialize();
    if (!available) {
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        'Speech recognition is not available on this device',
        icon: Icons.mic_off,
      );
      return;
    }

    setState(() {
      _isListening = true;
    });
    _startWave();

    final bool started = await speech.start(
      onPartial: (partial) {
        if (!mounted) return;
        _searchController.text = partial;
        _searchController.selection =
            TextSelection.collapsed(offset: partial.length);
        setState(() {});
      },
      onResult: (finalText) {
        _handledResult = true;
        if (finalText.trim().isEmpty) {
          _stopWave();
          if (mounted) setState(() => _isListening = false);
          return;
        }
        _applyTranscript(finalText);
      },
    );

    if (!started && mounted) {
      _stopWave();
      setState(() => _isListening = false);
      SnackbarHelper.show(
        context,
        "Couldn't start listening. Try again.",
        icon: Icons.mic_off,
      );
    }
  }

  void _applyTranscript(String raw) {
    if (!mounted) return;
    final String cleaned = structureSpokenText(raw);
    _searchController.text = cleaned;
    _searchController.selection =
        TextSelection.collapsed(offset: cleaned.length);
    _stopWave();
    setState(() {
      _isListening = false;
    });
    if (cleaned.isNotEmpty) {
      _onSearchChanged(cleaned);
    } else {
      SnackbarHelper.show(
        context,
        "Didn't catch that. Try again.",
        icon: Icons.mic_off,
      );
    }
  }

  void _openBrowseServices() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerHomeScreen(),
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    final unread =
        _conversations.where((c) => c.unreadCount > 0).toList();
    if (unread.isEmpty) {
      SnackbarHelper.show(
        context,
        'You have no unread messages',
        icon: Icons.check_circle_outline,
      );
      return;
    }
    await Future.wait(unread.map((c) => ChatService.markRead(c.id)));
    if (!mounted) return;
    _loadConversations();
    SnackbarHelper.show(
      context,
      'All messages marked as read',
      icon: Icons.check_circle_outline,
    );
  }

  void _showChatHelpSheet() {
    final w = MediaQuery.of(context).size.width;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(w * 0.06, w * 0.04, w * 0.06, w * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: w * 0.12,
              height: w * 0.012,
              margin: EdgeInsets.only(bottom: w * 0.03),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(
              'Messages help',
              style: TextStyle(
                color: Colors.white,
                fontSize: w * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: w * 0.02),
            _chatHelpRow(
              Icons.search,
              'Use the search bar to find conversations or messages.',
            ),
            _chatHelpRow(
              Icons.message_outlined,
              'Tap any conversation to open it and send a message.',
            ),
            _chatHelpRow(
              Icons.check_circle_outline_rounded,
              'Mark all as read clears every unread badge at once.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatHelpRow(IconData icon, String text) {
    final w = MediaQuery.of(context).size.width;
    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.018),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: w * 0.09,
            height: w * 0.09,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFFF3CA9B), size: w * 0.048),
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: w * 0.033,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<_ChatMenuAction> _buildChatMenuItem({
    required IconData icon,
    required String label,
    required Color dotColor,
    required _ChatMenuAction value,
    required double screenWidth,
  }) {
    return PopupMenuItem<_ChatMenuAction>(
      value: value,
      height: screenWidth * 0.14,
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.028,
            height: screenWidth * 0.028,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Container(
            width: screenWidth * 0.09,
            height: screenWidth * 0.09,
            decoration: BoxDecoration(
              color: dotColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: dotColor, size: screenWidth * 0.048),
          ),
          SizedBox(width: screenWidth * 0.035),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _conversationTile(ChatConversation conv, double sw, double sh) {
    final String name = _conversationNames[conv.id] ?? 'Vendor';
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageScreen(
              conversationId: conv.id,
              name: name,
              color: _colorFor(name),
              status: 'Online',
            ),
          ),
        );
        _loadConversations();
      },
      child: Row(
        children: [
          Container(
            width: sw * 0.13,
            height: sw * 0.13,
            decoration: BoxDecoration(
              color: _colorFor(name),
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: sw * 0.055,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: sw * 0.036,
                    height: sw * 0.036,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: sw * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: sw * 0.038,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: sh * 0.004),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        conv.lastMessage ?? 'No messages yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.55),
                          fontSize: sw * 0.03,
                        ),
                      ),
                    ),
                    if (conv.unreadCount > 0) ...[
                      Container(
                        width: sw * 0.05,
                        height: sw * 0.05,
                        decoration: const BoxDecoration(
                          color: Color(0xFFCD7C20),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${conv.unreadCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: sw * 0.024,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: sw * 0.02),
                    ],
                    Text(
                      _conversationTime(conv.lastMessageAt),
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.4),
                        fontSize: sw * 0.026,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactCircle(Map<String, String> contact, double sw, double sh) {
    final String name = contact['name'] ?? 'Vendor';
    final String conversationId = contact['conversationId'] ?? '';
    return Container(
      width: sw * 0.146,
      margin: EdgeInsets.only(right: sw * 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessageScreen(
                    conversationId: conversationId,
                    name: name,
                    color: _colorFor(name),
                    status: 'Online',
                  ),
                ),
              );
            },
            child: Container(
              width: sw * 0.146,
              height: sw * 0.146,
              decoration: BoxDecoration(
                color: _colorFor(name),
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: sw * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: sw * 0.04,
                      height: sw * 0.04,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: sh * 0.006),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontSize: sw * 0.028,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageHitTile(ChatMessage message, double sw, double sh) {
    final String name =
        _conversationNames[message.conversationId] ?? 'Vendor';
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageScreen(
              conversationId: message.conversationId,
              name: name,
              color: _colorFor(name),
              status: 'Online',
              highlightMessageId: message.id,
            ),
          ),
        );
        _loadConversations();
      },
      child: Row(
        children: [
          Container(
            width: sw * 0.13,
            height: sw * 0.13,
            decoration: BoxDecoration(
              color: _colorFor(name),
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
                name.isNotEmpty ? name[0] : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: sw * 0.055,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: sw * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: sw * 0.038,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: sh * 0.004),
                Row(
                  children: [
                    Expanded(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: _highlightText(
                            message.text ?? '',
                            _searchQuery,
                            TextStyle(
                              color: Colors.black.withValues(alpha: 0.55),
                              fontSize: sw * 0.03,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      _conversationTime(message.createdAt),
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.4),
                        fontSize: sw * 0.026,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _highlightText(
    String text,
    String query,
    TextStyle baseStyle,
  ) {
    if (query.isEmpty || text.isEmpty) return [TextSpan(text: text, style: baseStyle)];
    final q = query.toLowerCase();
    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final index = lower.indexOf(q, start);
      if (index == -1) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        }
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: baseStyle));
      }
      spans.add(
        TextSpan(
          text: text.substring(index, index + q.length),
          style: baseStyle.copyWith(
            color: const Color(0xFFCC471B),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = index + q.length;
    }
    return spans;
  }

  Widget _searchHeader(String text, double sw) {
    return Padding(
      padding: EdgeInsets.only(bottom: sw * 0.02),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.5),
          fontSize: sw * 0.028,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildSearchResults(double sw, double sh) {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFCD7C20)),
      );
    }
    final q = _searchQuery.toLowerCase();
    final merged = <String, ChatConversation>{};
    for (final c in _conversations) {
      final name = _conversationNames[c.id] ?? '';
      if (name.toLowerCase().contains(q) ||
          (c.lastMessage?.toLowerCase().contains(q) ?? false)) {
        merged[c.id] = c;
      }
    }
    for (final c in _searchResults?.conversations ?? []) {
      merged[c.id] = c;
    }
    final convResults = merged.values.toList()
      ..sort((a, b) {
        final at = a.lastMessageAt?.millisecondsSinceEpoch ?? 0;
        final bt = b.lastMessageAt?.millisecondsSinceEpoch ?? 0;
        return bt.compareTo(at);
      });
    final messageHits = _searchResults?.messages ?? [];

    if (convResults.isEmpty && messageHits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: sw * 0.12,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            SizedBox(height: sh * 0.012),
            Text(
              'No results',
              style: TextStyle(
                color: Colors.black,
                fontSize: sw * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: sh * 0.006),
            Text(
              'Nothing matches "$_searchQuery".',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.5),
                fontSize: sw * 0.03,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (convResults.isNotEmpty) ...[
          _searchHeader('Conversations', sw),
          for (final c in convResults) _conversationTile(c, sw, sh),
          Divider(
            color: Colors.black.withValues(alpha: 0.08),
            height: sh * 0.03,
            thickness: 1,
          ),
        ],
        if (messageHits.isNotEmpty) ...[
          _searchHeader('Messages containing "$_searchQuery"', sw),
          for (final m in messageHits) _messageHitTile(m, sw, sh),
        ],
      ],
    );
  }

  @override
  void dispose() {
    if (SpeechService.instance.isListening) {
      SpeechService.instance.cancel();
    }
    _stopWave();
    _waveTicker?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _socketSub?.cancel();
    _searchFocus.dispose();
    super.dispose();
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
              top: MediaQuery.of(context).size.height * 0.0,
              bottom: MediaQuery.of(context).size.height * 0.0,
              right:
                  (MediaQuery.of(context).size.width +
                      MediaQuery.of(context).size.width * 1) /
                  300,
              child: Image.asset(
                'assets/backgroundcolors/normalscreen.png',
                width: MediaQuery.of(context).size.width * 1.08,
                height: MediaQuery.of(context).size.height * 0.9,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: screenHeight * 0.03,
              right: screenWidth * 0.04,
              child: PopupMenuButton<_ChatMenuAction>(
                onSelected: (action) {
                  switch (action) {
                    case _ChatMenuAction.newMessage:
                      _openBrowseServices();
                    case _ChatMenuAction.markAllRead:
                      _markAllAsRead();
                    case _ChatMenuAction.notifications:
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    case _ChatMenuAction.help:
                      _showChatHelpSheet();
                  }
                },
                offset: const Offset(0, 8),
                elevation: 16,
                color: const Color(0xFF1A1A2E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                itemBuilder: (ctx) => [
                  _buildChatMenuItem(
                    icon: Icons.edit_outlined,
                    label: 'New message',
                    dotColor: const Color(0xFF42A5F5),
                    value: _ChatMenuAction.newMessage,
                    screenWidth: screenWidth,
                  ),
                  _buildChatMenuItem(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Mark all as read',
                    dotColor: const Color(0xFF4CAF50),
                    value: _ChatMenuAction.markAllRead,
                    screenWidth: screenWidth,
                  ),
                  const PopupMenuDivider(height: 1),
                  _buildChatMenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    dotColor: const Color(0xFFF3CA9B),
                    value: _ChatMenuAction.notifications,
                    screenWidth: screenWidth,
                  ),
                  _buildChatMenuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help',
                    dotColor: const Color(0xFF90A4AE),
                    value: _ChatMenuAction.help,
                    screenWidth: screenWidth,
                  ),
                ],
                child: Container(
                  width: screenWidth * 0.128,
                  height: screenWidth * 0.128,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
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
                      Icons.more_vert,
                      color: Colors.black,
                      size: screenWidth * 0.07,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.035,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
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
              top: screenHeight * 0.13,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: Container(
                height: screenWidth * 0.12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _isSearchFocused
                        ? const Color(0xFFCC471B)
                        : Colors.transparent,
                    width: 2,
                  ),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: screenWidth * 0.04),
                      child: Icon(
                        Icons.search,
                        color: Colors.black.withValues(alpha: 0.5),
                        size: screenWidth * 0.06,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        onChanged: _onSearchChanged,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.04,
                        ),
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? 'Listening… tap to stop'
                              : 'Search for messages here...',
                          hintStyle: TextStyle(
                            color: Colors.black.withValues(alpha: 0.5),
                            fontSize: screenWidth * 0.035,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : GestureDetector(
                                  onTap: _clearSearch,
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.black.withValues(alpha: 0.5),
                                    size: screenWidth * 0.05,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: screenWidth * 0.055,
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.02,
                      ),
                      child: GestureDetector(
                        onTap: _toggleListening,
                        child: _isListening
                            ? _ListeningWaveform(
                                levels: List.unmodifiable(_waveSamples),
                                color: const Color(0xFFE53935),
                              )
                            : Icon(
                                Icons.mic,
                                color: Colors.black,
                                size: screenWidth * 0.055,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top:
                  screenHeight * 0.13 +
                  screenWidth * 0.12 +
                  screenHeight * 0.015,
              right: screenWidth * 0.04,
              child: GestureDetector(
                onTap: _loadConversations,
                child: Container(
                  width: screenWidth * 0.128,
                  height: screenWidth * 0.128,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8C2B0),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_right,
                      color: Colors.black,
                      size: screenWidth * 0.10,
                    ),
                  ),
                ),
              ),
            ),
            if (_recentContacts.isNotEmpty)
              Positioned(
                top: screenHeight * 0.16 + screenWidth * 0.248,
                left: screenWidth * 0.04,
                right: screenWidth * 0.04,
                child: SizedBox(
                  height: screenWidth * 0.146 + screenHeight * 0.04,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final contact in _recentContacts)
                          _contactCircle(
                            contact,
                            screenWidth,
                            screenHeight,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: screenHeight * 0.215 + screenWidth * 0.394,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              bottom:
                  screenHeight * 0.02 +
                  screenWidth * 0.168 +
                  screenHeight * 0.01,
              child: _searchQuery.isNotEmpty
                  ? _buildSearchResults(screenWidth, screenHeight)
                  : _isLoadingConversations && _conversations.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFCD7C20),
                          ),
                        )
                      : _conversations.isEmpty
                          ? _ChatEmptyState(
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                          onBrowseServices: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CustomerHomeScreen(),
                              ),
                            );
                          },
                        )
                      : ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: _conversations.length,
                          itemBuilder: (context, index) {
                            return Column(
                              children: [
                                _conversationTile(
                                  _conversations[index],
                                  screenWidth,
                                  screenHeight,
                                ),
                                if (index != _conversations.length - 1)
                                  Divider(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    height: screenHeight * 0.03,
                                    thickness: 1,
                                  ),
                              ],
                            );
                          },
                        ),
            ),
            Positioned(
              bottom: screenHeight * 0.02,
              left: 0,
              right: 0,
              child: Center(
                child: BottomNavbar(
                  activeIndex: _currentNavIndex,
                  onItemSelected: (index) {
                    setState(() {
                      _currentNavIndex = index;
                    });
                    if (index == 0) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomerHomeScreen(),
                        ),
                      );
                    }
                    if (index == 3) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerProfileScreen(),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatEmptyState extends StatefulWidget {
  const _ChatEmptyState({
    required this.screenWidth,
    required this.screenHeight,
    required this.onBrowseServices,
  });

  final double screenWidth;
  final double screenHeight;
  final VoidCallback onBrowseServices;

  @override
  State<_ChatEmptyState> createState() => _ChatEmptyStateState();
}

class _ChatEmptyStateState extends State<_ChatEmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double sw = widget.screenWidth;
    final double sh = widget.screenHeight;
    final Animation<double> fadeIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    return Center(
      child: FadeTransition(
        opacity: fadeIn,
        child: Transform.translate(
          offset: Offset(0, sw * 0.02 * (1 - fadeIn.value)),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ChatEmptyScene(
                  sw: sw,
                  controller: _controller,
                  entrance: _entrance,
                ),
            SizedBox(height: sh * 0.015),
            Text(
              'No conversations yet',
              style: TextStyle(
                color: Colors.black,
                fontSize: sw * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: sh * 0.008),
            Text(
              'Tap the yellow Message button on a service\u2019s details page '
              'to start a chat with a vendor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.55),
                fontSize: sw * 0.032,
              ),
            ),
            SizedBox(height: sh * 0.018),
            GestureDetector(
              onTap: widget.onBrowseServices,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.05,
                  vertical: sw * 0.028,
                ),
                decoration: BoxDecoration(
                  color: kEmptyAccent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: kEmptyAccent.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      color: Colors.white,
                      size: sw * 0.045,
                    ),
                    SizedBox(width: sw * 0.02),
                    Text(
                      'Browse services',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: sw * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    ),
  );
}
}

class _ChatEmptyScene extends StatelessWidget {
  const _ChatEmptyScene({
    required this.sw,
    required this.controller,
    required this.entrance,
  });

  final double sw;
  final Animation<double> controller;
  final Animation<double> entrance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: sw * 0.64,
      height: sw * 0.62,
      child: AnimatedBuilder(
        animation: Listenable.merge([controller, entrance]),
        builder: (context, _) {
          final double t = controller.value;
          final double et = entrance.value;
          final double bob = math.sin(t * math.pi * 2) * sw * 0.011 +
              math.sin(t * math.pi * 4) * sw * 0.004;
          final bool blinking = (t > 0.42 && t < 0.5) || (t > 0.9 && t < 0.98);
          final double tilt = math.sin(t * math.pi * 2 * 0.5) * 0.035;

          final double charScale =
              Curves.elasticOut.transform(Interval(0.02, 0.7).transform(et));
          final double phoneScale =
              Curves.easeOutBack.transform(Interval(0.22, 0.82).transform(et));
          final double phoneFade = Interval(0.22, 0.5).transform(et);
          final double dotsFade = Interval(0.4, 0.65).transform(et);
          final double fingerScale =
              Curves.elasticOut.transform(Interval(0.55, 0.95).transform(et));
          final double fingerFade = Interval(0.55, 0.75).transform(et);
          final double glow =
              (0.6 + 0.4 * math.sin(t * math.pi * 2)) * Interval(0, 0.4).transform(et);

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: glow,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          kEmptyYellow.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _TwinkleStar(
                sw: sw,
                t: t,
                phase: 0.1,
                size: sw * 0.035,
                left: sw * 0.015,
                top: sw * 0.015,
              ),
              _TwinkleStar(
                sw: sw,
                t: t,
                phase: 0.45,
                size: sw * 0.045,
                left: sw * 0.56,
                top: sw * 0.04,
              ),
              _TwinkleStar(
                sw: sw,
                t: t,
                phase: 0.7,
                size: sw * 0.028,
                left: sw * 0.02,
                top: sw * 0.47,
              ),
              _TwinkleStar(
                sw: sw,
                t: t,
                phase: 0.3,
                size: sw * 0.038,
                left: sw * 0.57,
                top: sw * 0.42,
              ),
              _TwinkleStar(
                sw: sw,
                t: t,
                phase: 0.85,
                size: sw * 0.04,
                left: sw * 0.28,
                top: 0,
              ),
              Positioned(
                left: 0,
                top: sw * 0.02 + bob,
                child: Opacity(
                  opacity: dotsFade,
                  child: TypingDotsBubble(sw: sw, t: t, phase: 0.2),
                ),
              ),
              Positioned(
                right: sw * 0.02,
                top: sw * 0.18 - bob,
                child: Opacity(
                  opacity: dotsFade,
                  child: TypingDotsBubble(sw: sw, t: t, phase: 0.7),
                ),
              ),
              Transform.scale(
                scale: charScale,
                child: Transform.translate(
                  offset: Offset(0, bob + (1 - charScale) * sw * 0.03),
                  child: Transform.rotate(
                    angle: tilt,
                    child: ChatCharacterBubble(
                      sw: sw,
                      blinking: blinking,
                      lookDown: true,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Opacity(
                  opacity: phoneFade,
                  child: Transform.translate(
                    offset: Offset(0, (1 - phoneScale) * sw * 0.06),
                    child: Transform.scale(
                      scale: phoneScale,
                      child: Transform.translate(
                        offset: Offset(0, -bob * 0.5),
                        child: _PhoneCard(sw: sw, pulse: t),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: sw * 0.08,
                right: 0,
                child: Opacity(
                  opacity: fingerFade,
                  child: Transform.scale(
                    scale: fingerScale,
                    child: _PointingFinger(sw: sw, t: t),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TwinkleStar extends StatelessWidget {
  const _TwinkleStar({
    required this.sw,
    required this.t,
    required this.phase,
    required this.size,
    required this.left,
    required this.top,
  });

  final double sw;
  final double t;
  final double phase;
  final double size;
  final double left;
  final double top;

  @override
  Widget build(BuildContext context) {
    final double float = math.sin((t + phase) * math.pi * 2) * sw * 0.01;
    final double twinkle =
        0.3 + 0.7 * (0.5 + 0.5 * math.sin((t * 2 + phase) * math.pi * 2));
    return Positioned(
      left: left,
      top: top + float,
      child: Opacity(
        opacity: twinkle,
        child: Transform.rotate(
          angle: (t + phase) * math.pi * 0.5,
          child: CustomPaint(
            size: Size(size, size),
            painter: StarPainter(color: const Color(0xFFF6B93B)),
          ),
        ),
      ),
    );
  }
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.sw, required this.pulse});

  final double sw;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final double ripple = 0.06 * sw + 0.09 * sw * pulse;
    return Container(
      width: sw * 0.22,
      height: sw * 0.36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw * 0.05),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: sw * 0.03),
          Container(
            width: sw * 0.08,
            height: sw * 0.012,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: sw * 0.02),
          Container(
            margin: EdgeInsets.symmetric(horizontal: sw * 0.03),
            height: sw * 0.03,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: sw * 0.008),
          Container(
            margin: EdgeInsets.symmetric(horizontal: sw * 0.05),
            height: sw * 0.022,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: sw * 0.02),
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: ripple,
                height: ripple,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kEmptyYellow.withValues(alpha: 1 - pulse),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: sw * 0.16,
                height: sw * 0.05,
                decoration: BoxDecoration(
                  color: kEmptyYellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.message,
                      color: kEmptyYellowText,
                      size: sw * 0.026,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Message',
                      style: TextStyle(
                        color: kEmptyYellowText,
                        fontWeight: FontWeight.bold,
                        fontSize: sw * 0.023,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _PointingFinger extends StatelessWidget {
  const _PointingFinger({required this.sw, required this.t});

  final double sw;
  final double t;

  @override
  Widget build(BuildContext context) {
    final double press = math.sin(t * math.pi * 2);
    final double dy = press * sw * 0.02;
    final Color skin = kEmptyCream;
    final Color outline = Colors.black.withValues(alpha: 0.15);
    return Transform.translate(
      offset: Offset(0, dy),
      child: Transform.rotate(
        angle: -0.62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: sw * 0.05,
              height: sw * 0.05,
              decoration: BoxDecoration(
                color: skin,
                shape: BoxShape.circle,
                border: Border.all(color: outline, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            Container(
              width: sw * 0.045,
              height: sw * 0.1,
              decoration: BoxDecoration(
                color: skin,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: outline, width: 2),
              ),
            ),
            Container(
              width: sw * 0.09,
              height: sw * 0.08,
              decoration: BoxDecoration(
                color: skin,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: outline, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListeningWaveform extends StatelessWidget {
  const _ListeningWaveform({required this.levels, required this.color});

  final List<double> levels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 26,
      child: CustomPaint(
        painter: _ListeningWaveformPainter(levels: levels, color: color),
      ),
    );
  }
}

class _ListeningWaveformPainter extends CustomPainter {
  _ListeningWaveformPainter({required this.levels, required this.color});

  final List<double> levels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final List<double> bars =
        levels.isEmpty ? List<double>.filled(9, 0.22) : levels;
    final int count = bars.length;
    final double gap = size.width * 0.035;
    final double barWidth = (size.width - gap * (count - 1)) / count;
    if (barWidth <= 0) return;
    final Paint paint = Paint();
    for (int i = 0; i < bars.length; i++) {
      final double height = bars[i].clamp(0.08, 1.0) * size.height;
      final double x = i * (barWidth + gap);
      paint.color =
          color.withValues(alpha: 0.35 + 0.65 * (i / math.max(bars.length - 1, 1)));
      final RRect rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, (size.height - height) / 2, barWidth, height),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_ListeningWaveformPainter oldDelegate) {
    return oldDelegate.levels != levels || oldDelegate.color != color;
  }
}
