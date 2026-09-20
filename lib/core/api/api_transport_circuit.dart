import 'package:flutter/foundation.dart';

/// Circuit breaker leve para falhas de transporte (não auth).
///
/// Aberto → UI/banner deve frear stampede; fecha após [cooldown] ou sucesso.
abstract final class ApiTransportCircuit {
  ApiTransportCircuit._();

  static const int tripAfterFailures = 5;
  static const Duration cooldown = Duration(seconds: 20);

  static int _failures = 0;
  static DateTime? _openUntil;

  static bool get isOpen {
    final until = _openUntil;
    if (until == null) return false;
    if (DateTime.now().isBefore(until)) return true;
    _openUntil = null;
    _failures = 0;
    return false;
  }

  static DateTime? get openUntil => _openUntil;

  static void recordSuccess() {
    _failures = 0;
    _openUntil = null;
  }

  static void recordTransportFailure() {
    if (isOpen) return;
    _failures++;
    if (_failures >= tripAfterFailures) {
      _openUntil = DateTime.now().add(cooldown);
      _failures = 0;
      if (kDebugMode) {
        debugPrint('[ApiTransportCircuit] open until $_openUntil');
      }
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _failures = 0;
    _openUntil = null;
  }
}
