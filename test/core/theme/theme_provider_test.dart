import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('aparência padrão segue o sistema do celular', () async {
    final controller = ThemeModeController();
    await controller.ready;
    expect(controller.state, ThemeMode.system);
  });

  test('restaura claro travado nas preferências', () async {
    SharedPreferences.setMockInitialValues({'focux_appearance_mode': 'light'});
    final controller = ThemeModeController();
    await controller.ready;
    expect(controller.state, ThemeMode.light);
  });
}
