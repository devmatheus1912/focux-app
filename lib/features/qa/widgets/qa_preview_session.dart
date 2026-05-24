import 'package:flutter/foundation.dart';

/// Captures [FlutterError] events during QA preview dialogs.
class QaPreviewSession {
  QaPreviewSession._();

  static final List<String> errors = [];
  static FlutterExceptionHandler? _previousHandler;

  static void begin() {
    errors.clear();
    _previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (!errors.contains(message)) {
        errors.add(message);
      }
      _previousHandler?.call(details);
    };
  }

  static void end() {
    if (_previousHandler != null) {
      FlutterError.onError = _previousHandler!;
      _previousHandler = null;
    }
  }

  static String? firstErrorOrNull() => errors.isEmpty ? null : errors.first;
}
