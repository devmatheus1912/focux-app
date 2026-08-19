import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'design_tokens.dart';

const _themePrefKey = 'focux_appearance_mode';

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) => ThemeModeController(),
);

final primaryColorProvider = StateProvider<Color>((ref) => EagleTokens.brand);

final logoUrlProvider = StateProvider<String?>((ref) => null);

final personalNameProvider = StateProvider<String?>((ref) => null);

final hideFocuxBrandingProvider = StateProvider<bool>((ref) => false);

final appDisplayNameProvider = StateProvider<String?>((ref) => null);

/// Aparência do app. Padrão = modo do celular ([ThemeMode.system]).
class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.system) {
    ready = _restore();
  }

  @visibleForTesting
  late final Future<void> ready;

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_themePrefKey);
      if (raw == null) return;
      state = ThemeMode.values.firstWhere(
        (mode) => mode.name == raw,
        orElse: () => ThemeMode.system,
      );
    } catch (_) {}
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePrefKey, mode.name);
    } catch (_) {}
  }
}

/// Main-shell tabs render over [CinematicMeshBackground] — keep scaffolds transparent.
const shellScaffoldColor = Colors.transparent;
