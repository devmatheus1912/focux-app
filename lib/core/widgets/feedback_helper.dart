import 'package:flutter/material.dart';

class FeedbackHelper {
  static void showSuccess(BuildContext context, String message) {
    _showSnackbar(context, message, Colors.green.shade700, Icons.check_circle);
  }

  static void showError(BuildContext context, String message) {
    _showSnackbar(context, message, Colors.red.shade700, Icons.error);
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackbar(context, message, Theme.of(context).colorScheme.primary, Icons.info);
  }

  static void _showSnackbar(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        elevation: 6,
      ),
    );
  }
}
