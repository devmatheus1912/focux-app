import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../state/fx_value_notifier.dart';
import 'brand_palette.dart';
import 'design_tokens.dart';

const _themePrefKey = 'focux_appearance_mode';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

final primaryColorProvider = fxValueProvider<Color>(EagleTokens.brand);

final secondaryColorProvider = fxValueProvider<Color>(
  BrandPalette.defaultSecondary,
);

final logoUrlProvider = fxValueProvider<String?>(null);

final sloganProvider = fxValueProvider<String?>(null);

final personalNameProvider = fxValueProvider<String?>(null);

final hideFocuxBrandingProvider = fxValueProvider<bool>(false);

final appDisplayNameProvider = fxValueProvider<String?>(null);

/// Aparência do app. Padrão = modo do celular ([ThemeMode.system]).
class ThemeModeController extends Notifier<ThemeMode> {
  @visibleForTesting
  late Future<void> ready;

  @override
  ThemeMode build() {
    ready = _restore();
    return ThemeMode.system;
  }

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
