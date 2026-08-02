class NotificationPreferences {
  const NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.bookingUpdates = true,
    this.promotions = false,
    this.messages = true,
    this.reminders = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  });

  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool bookingUpdates;
  final bool promotions;
  final bool messages;
  final bool reminders;
  final bool soundEnabled;
  final bool vibrationEnabled;

  factory NotificationPreferences.defaults() => const NotificationPreferences();

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    bool read(String key, bool fallback) {
      final value = json[key];
      return value is bool ? value : fallback;
    }

    return NotificationPreferences(
      pushEnabled: read('pushEnabled', true),
      emailEnabled: read('emailEnabled', true),
      smsEnabled: read('smsEnabled', false),
      bookingUpdates: read('bookingUpdates', true),
      promotions: read('promotions', false),
      messages: read('messages', true),
      reminders: read('reminders', true),
      soundEnabled: read('soundEnabled', true),
      vibrationEnabled: read('vibrationEnabled', true),
    );
  }

  Map<String, dynamic> toJson() => {
        'pushEnabled': pushEnabled,
        'emailEnabled': emailEnabled,
        'smsEnabled': smsEnabled,
        'bookingUpdates': bookingUpdates,
        'promotions': promotions,
        'messages': messages,
        'reminders': reminders,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
      };
}
