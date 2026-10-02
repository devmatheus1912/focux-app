import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_settings_tile.dart';
import 'package:focux_app/features/dashboard/data/dashboard_tool_shortcuts.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_client_cache.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_tool_shortcut_group.dart';
import 'package:focux_app/features/ferramentas/data/ferramentas_catalogo_models.dart';
import 'package:focux_app/features/leads/data/lead_repository.dart';
import 'package:focux_app/features/leads/providers/leads_provider.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';

import '../../support/riverpod_seeds.dart';

const _leads = DashboardToolShortcut(
  icon: 'leads',
  label: 'Leads',
  entrada: CatalogoEntrada(id: 'leads', titulo: 'Leads'),
  route: '/leads',
  capability: 'leads',
);

Future<int> _pump(
  WidgetTester tester, {
  required String plano,
  LeadsContagem? contagem,
  void Function(DashboardToolShortcut)? onShortcut,
}) async {
  var chamadas = 0;
  final features = PlanoFeatures.fromJson({'plano': plano});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seededPlanoFeatures(features),
        leadsContagemTeaserProvider.overrideWith((ref) async {
          chamadas++;
          return contagem;
        }),
      ],
      child: MaterialApp(
        locale: const Locale('pt'),
        home: Scaffold(
          body: DashboardToolShortcutGroup(
            shortcuts: const [_leads],
            homePlanoFeatures: features,
            onShortcut: onShortcut ?? (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return chamadas;
}

void main() {
  setUp(DashboardHomeClientCache.clear);
  tearDown(DashboardHomeClientCache.clear);

  test('rótulo do teaser', () {
    expect(leadsTeaserLabel(null), isNull);
    expect(leadsTeaserLabel(const LeadsContagem(total: 0, novos: 0)), isNull);
    expect(
      leadsTeaserLabel(const LeadsContagem(total: 1, novos: 1)),
      '1 lead esperando',
    );
    expect(
      leadsTeaserLabel(const LeadsContagem(total: 4, novos: 2)),
      '4 leads esperando',
    );
  });

  test('contagem tolera campos ausentes', () {
    final c = LeadsContagem.fromJson(const {'total': 3});
    expect(c.total, 3);
    expect(c.novos, 0);
  });

  testWidgets('Free: leads trancado com "N leads esperando"', (tester) async {
    DashboardToolShortcut? tocado;
    final chamadas = await _pump(
      tester,
      plano: 'FREE',
      contagem: const LeadsContagem(total: 4, novos: 2),
      onShortcut: (s) => tocado = s,
    );

    expect(chamadas, 1);
    expect(find.text('4 leads esperando'), findsOneWidget);
    final tile = tester.widget<FxSettingsTile>(find.byType(FxSettingsTile));
    expect(tile.locked, isTrue);
    expect(tile.upgradeTierLabel, 'Pro');

    await tester.tap(find.text('Leads'));
    expect(tocado, _leads);
    expect(
      _leads.isUnlocked(PlanoFeatures.fromJson({'plano': 'FREE'})),
      isFalse,
    );
  });

  testWidgets('Free sem contagem (erro/zero): sem teaser', (tester) async {
    await _pump(tester, plano: 'FREE');
    expect(find.textContaining('esperando'), findsNothing);
  });

  testWidgets('Pro: não consulta a contagem', (tester) async {
    final chamadas = await _pump(
      tester,
      plano: 'PRO',
      contagem: const LeadsContagem(total: 4, novos: 2),
    );
    expect(chamadas, 0);
    expect(find.textContaining('esperando'), findsNothing);
  });
}
