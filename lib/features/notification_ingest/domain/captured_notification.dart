/// Structured notification fields forwarded from Android (in-memory only).
///
/// Raw title/text must never be persisted to Firestore — only parsed draft
/// fields (amount, merchant, bookingDate, accountId, …).
class CapturedNotification {
  const CapturedNotification({
    required this.packageName,
    required this.title,
    required this.text,
    required this.postTimeMs,
  });

  final String packageName;
  final String title;
  final String text;

  /// Notification post time (epoch millis).
  final int postTimeMs;

  /// Combined title + text for parsing (never stored).
  String get combinedText {
    final t = title.trim();
    final b = text.trim();
    if (t.isEmpty) return b;
    if (b.isEmpty) return t;
    return '$t\n$b';
  }

  factory CapturedNotification.fromMap(Map<dynamic, dynamic> map) {
    return CapturedNotification(
      packageName: (map['packageName'] as String?)?.trim() ?? '',
      title: (map['title'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      postTimeMs: (map['postTime'] as num?)?.toInt() ?? 0,
    );
  }
}
