import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/fx_utils.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_screen_helpers.dart';

void main() {
  group('dashboardPersonalDisplayName', () {
    test('usa nome completo do BFF (SSOT com perfil)', () {
      expect(dashboardPersonalDisplayName('matheus'), 'Matheus');
      expect(
        dashboardPersonalDisplayName('matheus ribeiro'),
        'Matheus Ribeiro',
      );
    });

    test('preserva nome composto (não corta no 1º token)', () {
      expect(
        dashboardPersonalDisplayName('ana clara silva'),
        'Ana Clara Silva',
      );
      expect(
        dashboardPersonalDisplayName('João Pedro da Costa'),
        'João Pedro Da Costa',
      );
    });

    test('nome extenso permanece completo (ellipsis é da UI)', () {
      const longo =
          'maria fernanda aparecida de souza oliveira santos';
      expect(dashboardPersonalDisplayName(longo), fxTitleCaseName(longo));
    });

    test('vazio → Personal', () {
      expect(dashboardPersonalDisplayName(null), 'Personal');
      expect(dashboardPersonalDisplayName('   '), 'Personal');
    });
  });

  group('fxInitials alinhado ao nome completo', () {
    test('primeiro + último', () {
      expect(fxInitials('Matheus Ribeiro'), 'MR');
      expect(fxInitials('Ana Clara Silva'), 'AS');
      expect(fxInitials('Bartholomeu'), 'BA');
    });
  });
}
