import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Saúde tem ícone próprio no dock e o atualizar não cai no fallback', () {
    final icon = File('lib/core/widgets/fx_icon.dart').readAsStringSync();
    final dock = File('lib/core/widgets/fx_dock.dart').readAsStringSync();

    expect(icon, contains("case 'heart-pulse':"));
    expect(icon, contains("case 'refresh-cw':"));
    expect(dock, contains("FxDockItem(icon: 'heart-pulse', label: 'Saúde')"));
    expect(dock, isNot(contains("FxDockItem(icon: 'trend', label: 'Saúde')")));
  });
}
