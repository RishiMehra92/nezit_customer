import 'package:flutter/widgets.dart';
import 'package:hyper_local/utils/extensions/translation_extension.dart';
import 'package:intl/intl.dart';

class DateFormatter {
  static DateTime? _parseDate(String dateString) {
    DateTime? dt = DateTime.tryParse(dateString);
    if (dt != null) return dt;

    try {
      // Trying to parse formats like "Sep 22, 2026 10:05 AM"
      return DateFormat("MMM dd, yyyy hh:mm a").parse(dateString);
    } catch (_) {}

    return null;
  }

  static String formatOrderPlaced(String backendDateTime) {
    final DateTime? dt = _parseDate(backendDateTime);
    if (dt == null) return backendDateTime;
    return DateFormat('EEE, dd MMM\'yy, hh:mm a').format(dt);
    // Output: Mon, 24 Nov'25, 09:13 AM
  }

  // Bonus: Other useful formats
  static String fullDate(String backendDateTime) {
    final DateTime? dt = _parseDate(backendDateTime);
    if (dt == null) return backendDateTime;
    return DateFormat('dd MMMM yyyy, hh:mm a').format(dt);
    // → 24 November 2025, 09:13 AM
  }

  static String relativeTime(String backendDateTime, [BuildContext? context]) {
    final DateTime? date = _parseDate(backendDateTime);
    if (date == null) return backendDateTime;

    final DateTime now = DateTime.now();
    final Duration diff = now.difference(date);

    if (diff.inDays >= 7) {
      return DateFormat('dd MMM yyyy').format(date); // 24 Nov 2025
    } else if (diff.inDays >= 1) {
      return context?.tr('daysAgo',
              positionalArgs: [diff.inDays],
              fallback: '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago') ??
          '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours >= 1) {
      return context?.tr('hoursAgo',
              positionalArgs: [diff.inHours],
              fallback: '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago') ??
          '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes >= 1) {
      return context?.tr('minAgo',
              positionalArgs: [diff.inMinutes],
              fallback: '${diff.inMinutes} min ago') ??
          '${diff.inMinutes} min ago';
    } else {
      return context?.tr('justNow', fallback: 'Just now') ?? 'Just now';
    }
  }
}