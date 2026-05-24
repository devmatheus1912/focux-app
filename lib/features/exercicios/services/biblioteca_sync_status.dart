import 'package:flutter/foundation.dart';

/// Estado global leve para banner de sincronização da biblioteca.
class BibliotecaSyncStatus extends ChangeNotifier {
  BibliotecaSyncStatus._();

  static final instance = BibliotecaSyncStatus._();

  bool _syncing = false;
  String? _message;

  bool get syncing => _syncing;
  String? get message => _message;

  void start(String message) {
    _syncing = true;
    _message = message;
    notifyListeners();
  }

  void stop() {
    _syncing = false;
    _message = null;
    notifyListeners();
  }
}
