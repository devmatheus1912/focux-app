import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/ux/fx_hub_freshness.dart';
import 'package:focux_app/core/widgets/fx_error_state.dart';
import 'package:focux_app/core/widgets/fx_empty_state.dart';
import 'package:focux_app/core/widgets/fx_hub_header.dart';
import 'package:focux_app/core/theme/brand_palette.dart';

void main() {
  group('FxHubFreshness', () {
    test('atualizadoHa bands', () {
      expect(FxHubFreshness.atualizadoHa(Duration.zero), 'Atualizado agora');
      expect(
        FxHubFreshness.atualizadoHa(const Duration(seconds: 40)),
        'Atualizado há 40s',
      );
      expect(
        FxHubFreshness.atualizadoHa(const Duration(minutes: 3)),
        'Atualizado há 3min',
      );
      expect(
        FxHubFreshness.atualizadoHa(const Duration(hours: 2)),
        'Atualizado há 2h',
      );
    });

    test('fromFetchedAt null', () {
      expect(FxHubFreshness.fromFetchedAt(null), isNull);
    });
  });

  testWidgets('FxErrorState shows retry', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FxErrorState(
            chromeOnDark: false,
            primary: BrandPalette.defaultPrimary,
            message: 'falhou',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    expect(find.text('falhou'), findsOneWidget);
    await tester.tap(find.text('Tentar novamente'));
    expect(retried, isTrue);
  });

  testWidgets('FxEmptyState shows CTA', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FxEmptyState(
            icon: 'users',
            title: 'Vazio',
            subtitle: 'Sub',
            action: FxEmptyAction(label: 'Ir', onTap: () => tapped = true),
          ),
        ),
      ),
    );
    expect(find.text('Vazio'), findsOneWidget);
    await tester.tap(find.text('Ir'));
    expect(tapped, isTrue);
  });

  testWidgets('FxHubHeader exposes freshness', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FxHubHeader(
            title: 'Alunos',
            freshnessLabel: 'Atualizado agora',
          ),
        ),
      ),
    );
    expect(find.text('Alunos'), findsOneWidget);
    expect(find.text('Atualizado agora'), findsOneWidget);
  });
}
