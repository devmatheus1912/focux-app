import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ThemeMode> restoredMode() async {
    final container = ProviderContainer.test();
    await container.read(themeModeProvider.notifier).ready;
    return container.read(themeModeProvider);
  }

  test('aparência padrão segue o sistema do celular', () async {
    expect(await restoredMode(), ThemeMode.system);
  });

  test('restaura claro travado nas preferências', () async {
    SharedPreferences.setMockInitialValues({'focux_appearance_mode': 'light'});
    expect(await restoredMode(), ThemeMode.light);
  });
}
