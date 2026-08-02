import 'package:flutter/material.dart';

enum AppNotificationCategory { members, bookings, reminders, general }

extension AppNotificationCategoryX on AppNotificationCategory {
  String get serverValue => name.toUpperCase();

  String get segmentLabel {
    switch (this) {
      case AppNotificationCategory.members:
        return 'Members';
      case AppNotificationCategory.bookings:
        return 'Bookings';
      case AppNotificationCategory.reminders:
        return 'Reminders';
      case AppNotificationCategory.general:
        return 'General';
    }
  }

  static AppNotificationCategory fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'MEMBERS':
        return AppNotificationCategory.members;
      case 'BOOKINGS':
      case 'BOOKING':
        return AppNotificationCategory.bookings;
      case 'REMINDERS':
      case 'REMINDER':
        return AppNotificationCategory.reminders;
      default:
        return AppNotificationCategory.general;
    }
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    required this.category,
    required this.createdAt,
    this.readAt,
    this.archivedAt,
  });

  final String id;
  final String type;
  final String title;
  final String? body;
  final AppNotificationCategory category;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? archivedAt;

  bool get isRead => readAt != null;
  bool get isArchived => archivedAt != null;

  String get bodyText => body == null || body!.trim().isEmpty ? title : body!;

  IconData get icon {
    switch (category) {
      case AppNotificationCategory.members:
        return Icons.message;
      case AppNotificationCategory.bookings:
        return Icons.monetization_on;
      case AppNotificationCategory.reminders:
        return Icons.notifications_active;
      case AppNotificationCategory.general:
        return Icons.notifications_none_rounded;
    }
  }

  Color get iconColor {
    switch (category) {
      case AppNotificationCategory.members:
        return const Color(0xFFE4351D);
      case AppNotificationCategory.bookings:
        return const Color(0xFF55FF27);
      case AppNotificationCategory.reminders:
        return const Color(0xFF96E8F4);
      case AppNotificationCategory.general:
        return const Color(0xFFF3CA9B);
    }
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final createdAtMs = (json['createdAt'] as num?)?.toInt() ?? 0;
    return AppNotification(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String?,
      category: AppNotificationCategoryX.fromString(json['category'] as String?),
      createdAt: createdAtMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
          : DateTime.now(),
      readAt: _parseMillis(json['readAt']),
      archivedAt: _parseMillis(json['archivedAt']),
    );
  }

  static DateTime? _parseMillis(dynamic value) {
    final ms = (value as num?)?.toInt();
    return (ms == null || ms <= 0) ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  AppNotification copyWith({
    DateTime? readAt,
    DateTime? archivedAt,
  }) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      category: category,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  static String relativeTime(DateTime time, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final difference = current.difference(time);
    if (difference.isNegative) return 'Just now';
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} sec${difference.inSeconds == 1 ? '' : 's'} ago';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min${difference.inMinutes == 1 ? '' : 's'} ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} hr${difference.inHours == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${time.day} ${months[time.month - 1]} ${time.year}';
  }
}
