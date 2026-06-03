import 'dart:async';

import 'package:flutter/services.dart';

/// Copies [text] to the clipboard and clears it after [clearAfter] if still present.
Future<void> copySensitiveToClipboard(
  String text, {
  Duration clearAfter = const Duration(seconds: 60),
}) async {
  await Clipboard.setData(ClipboardData(text: text));
  unawaited(_scheduleClipboardClear(text, clearAfter));
}

Future<void> _scheduleClipboardClear(String copied, Duration delay) async {
  await Future<void>.delayed(delay);
  final current = await Clipboard.getData('text/plain');
  if (current?.text == copied) {
    await Clipboard.setData(const ClipboardData(text: ''));
  }
}
