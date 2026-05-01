import 'package:flutter/services.dart';

/// Centralized haptic feedback for premium feel.
/// Usage: `Haptics.light()`, `Haptics.medium()`, `Haptics.success()`
class Haptics {
  Haptics._();

  /// Subtle tap feedback — tab switches, toggles, selections
  static void light() => HapticFeedback.selectionClick();

  /// Medium click — button presses, form submits
  static void medium() => HapticFeedback.mediumImpact();

  /// Heavy thud — destructive actions, errors
  static void heavy() => HapticFeedback.heavyImpact();

  /// Success pattern — completions, saves, achievements
  static void success() => HapticFeedback.lightImpact();

  /// Vibrate — critical alerts, warnings
  static void warning() => HapticFeedback.vibrate();
}
