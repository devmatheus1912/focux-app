import 'package:flutter/foundation.dart';

import '../storage/secure_storage.dart';

class SessionInvalidator {
  static final ValueNotifier<int> _notifier = ValueNotifier<int>(0);

  static Listenable get listenable => _notifier;

  static Future<void> invalidate({String? reason}) async {
    await SecureStorage.clearAll();
    _notifier.value++;
    if (kDebugMode && reason != null && reason.isNotEmpty) {
      debugPrint('[SessionInvalidator] $reason');
    }
  }
}
