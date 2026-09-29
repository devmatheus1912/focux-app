import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/motion_preferences.dart';

/// Celulares críticos: Android estreito / iPhone SE e iPhone 12–15.
const kDynamicTypeTelas = [Size(360, 690), Size(390, 844)];

/// Tela [size] com a fonte do sistema no teto do app ([kAppMaxTextScale]).
void usarDynamicTypeMaximo(WidgetTester tester, Size size) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = kAppMaxTextScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

String descreverTela(Size size) =>
    '${size.width.toInt()}×${size.height.toInt()} @ $kAppMaxTextScale';
