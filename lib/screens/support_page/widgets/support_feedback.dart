import 'package:flutter/material.dart';

enum SupportFeedbackType { success, error, warning }

void showSupportFeedback(
  BuildContext context, {
  required String message,
  required SupportFeedbackType type,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null || message.trim().isEmpty) return;

  final (background, icon, foreground) = switch (type) {
    SupportFeedbackType.success => (
        Colors.green.shade700,
        Icons.check_circle_outline,
        Colors.white,
      ),
    SupportFeedbackType.error => (
        Theme.of(context).colorScheme.error,
        Icons.error_outline,
        Theme.of(context).colorScheme.onError,
      ),
    SupportFeedbackType.warning => (
        Colors.orange.shade700,
        Icons.warning_amber_rounded,
        Colors.white,
      ),
  };

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        content: Row(
          children: [
            Icon(icon, color: foreground, size: 19),
            const SizedBox(width: 9),
            Expanded(child: Text(message, style: TextStyle(color: foreground))),
          ],
        ),
      ),
    );
}
