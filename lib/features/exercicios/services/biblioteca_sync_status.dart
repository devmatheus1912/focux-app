import 'package:flutter/foundation.dart';

import 'biblioteca_media_config.dart';

/// Estado global leve para banner de sincronização da biblioteca.
class BibliotecaSyncStatus extends ChangeNotifier {
  BibliotecaSyncStatus._();

  static final instance = BibliotecaSyncStatus._();

  bool _syncing = false;
  String? _message;
  int _pendingMediaCount = 0;
  String? _warningMessage;

  bool get syncing => _syncing;
  String? get message => _message;
  int get pendingMediaCount => _pendingMediaCount;
  String? get warningMessage => _warningMessage;

  bool get showPendingHint =>
      !kBibliotecaLibraryVideosStandby && !_syncing && _pendingMediaCount > 0;

  void start(String message) {
    _syncing = true;
    _message = message;
    _warningMessage = null;
    notifyListeners();
  }

  void updatePendingMedia(int count) {
    _pendingMediaCount = count;
    notifyListeners();
  }

  void warn(String message) {
    _warningMessage = message;
    notifyListeners();
  }

  void stop({int? pendingMediaCount, String? warningMessage}) {
    _syncing = false;
    _message = null;
    if (pendingMediaCount != null) {
      _pendingMediaCount = pendingMediaCount;
    }
    if (warningMessage != null) {
      _warningMessage = warningMessage;
    } else if (warningMessage == null && pendingMediaCount == 0) {
      _warningMessage = null;
    }
    notifyListeners();
  }

  void clearWarnings() {
    _warningMessage = null;
    _pendingMediaCount = 0;
    notifyListeners();
  }
}
