import 'package:intl/intl.dart';

/// "just now", "5m ago", "3h ago", "Yesterday", or a short date.
String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  return DateFormat('MMM d').format(time);
}
