import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a Hoje do personal é uma tela só, com Agora por pessoa e layout seguro', () {
    const paths = [
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
      'lib/features/dashboard/screens/personal_dashboard_screen_build.part.dart',
      'lib/features/dashboard/screens/personal_dashboard_screen_state.part.dart',
      'lib/features/dashboard/widgets/dashboard_home_primary_slivers.dart',
      'lib/features/dashboard/widgets/hoje_agora_secao.dart',
      'lib/features/dashboard/widgets/hoje_base_secao.dart',
      'lib/features/dashboard/widgets/dashboard_agenda_hoje_strip.dart',
      'lib/features/dashboard/widgets/dashboard_shimmer_loading.dart',
      'lib/features/dashboard/widgets/dashboard_home_header.dart',
      'lib/features/dashboard/utils/hoje_agora.dart',
      'lib/features/dashboard/utils/dashboard_home_snapshot.dart',
      'lib/features/dashboard/data/dashboard_repository.dart',
      'lib/features/dashboard/data/dashboard_tool_shortcuts.dart',
      'lib/features/dashboard/utils/dashboard_unread.dart',
    ];
    final widget = paths.map((p) => File(p).readAsStringSync()).join('\n');

    // Uma tela: nada de painel nem catálogo em sheet.
    expect(widget, isNot(contains('showHojePersonalPainel')));
    expect(widget, isNot(contains('showDashboardToolsCatalogSheet')));
    expect(widget, isNot(contains('DashboardPrioritiesOverlay')));
    expect(widget, isNot(contains('DashboardDayPulseStrip')));
    expect(widget, isNot(contains('DashboardFinancialHeroSection')));

    // Agora por pessoa, com verbo; a regra mora numa função pura.
    expect(widget, contains('hojeAgora('));
    expect(widget, contains('FxActionRow'));
    expect(widget, contains('kHojeAgoraVisiveis'));
    expect(widget, contains("source: 'hoje_agora'"));
    expect(widget, contains('hojeVerTodas'));

    // Base, dinheiro e ferramentas.
    expect(widget, contains('FxMetricStrip'));
    expect(widget, contains('HojeDinheiroLinha'));
    expect(widget, contains("'/ferramentas'"));
    expect(widget, contains('mensagensNaoLidas'));
    expect(widget, contains('dashboardChatUnreadCount'));
    expect(widget, contains('riscoAlto'));
    expect(widget, contains('checkinsHoje'));

    // Layout seguro em tela estreita.
    expect(widget, contains('maxLines'));
    expect(widget, contains('TextOverflow.ellipsis'));
    expect(widget, contains('Shimmer.fromColors'));
    expect(widget, contains('SliverToBoxAdapter'));

    // Dados do servidor que a Hoje usa.
    expect(widget, contains('buildDashboardNextActions'));
    expect(widget, contains('DashboardHomeFocusRules'));
    expect(widget, contains('BILLING_PENDING'));
    expect(widget, contains('FICHA_VENCENDO_'));
  });
}
