import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// First paint Home: um BFF, sem sidecars redundantes (pareado BE #75).
void main() {
  test('aluno home first paint não dispara sidecars de histórico/coach/medidas/upsell', () {
    final screen = File(
      'lib/features/dashboard/screens/aluno_dashboard_screen.dart',
    ).readAsStringSync();
    final tools = File(
      'lib/features/dashboard/screens/aluno_dashboard_screen_tools.part.dart',
    ).readAsStringSync();
    final cards = File(
      'lib/features/dashboard/screens/aluno_dashboard_screen_cards.part.dart',
    ).readAsStringSync();
    final bundle = '$screen\n$tools\n$cards';

    expect(bundle, contains('alunoDashboardHomeProvider'));
    expect(bundle, contains('home.coachMensagens'));
    expect(bundle, contains('home.upsellPendentes'));
    expect(bundle, contains('home.medidas'));
    expect(bundle, contains('home.historico'));

    // Sidecars proibidos no first paint (quando BFF já trouxe o campo).
    expect(bundle, isNot(contains('/api/checkin/historico')));
    expect(bundle, isNot(contains('/api/coach-proativo/mensagens')));
    expect(bundle, isNot(contains('/api/aluno/medidas')));
    expect(bundle, isNot(contains('/api/upsell/me/pendentes')));
    expect(bundle, isNot(contains('coachMensagensProvider')));
    expect(bundle, isNot(contains('_alunoUpsellProvider')));
  });

  test('personal home first paint usa pulse.coachPendentes sem coachHome', () {
    final screen = File(
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    ).readAsStringSync();
    final build = File(
      'lib/features/dashboard/screens/personal_dashboard_screen_build.part.dart',
    ).readAsStringSync();
    final bundle = '$screen\n$build';

    expect(bundle, contains('dashboardHomeProvider'));
    expect(bundle, contains('coachPendentes'));
    expect(bundle, contains('seedFromHome'));
    expect(bundle, isNot(contains('coachHomeProvider')));
    expect(bundle, isNot(contains('/api/coach-proativo/home')));
    expect(bundle, isNot(contains('/api/planos/me')));
  });

  test('api client envia If-None-Match e aceita 304', () {
    final api = File('lib/core/api/api_client.dart').readAsStringSync();
    expect(api, contains('If-None-Match'));
    expect(api, contains('ApiEtagStore'));
    expect(api, contains('status >= 200 && status < 400'));
    expect(api, contains('etag'));
  });

  test('CONTRATO §9 documenta snappy UX pareado com backend #75', () {
    final contrato =
        File('docs/CONTRATO_APP_BACKEND.md').readAsStringSync();
    expect(contrato, contains('backend #75'));
    expect(contrato, contains('historicoResumo'));
    expect(contrato, contains('coachPendentes'));
    expect(contrato, contains('max-age=60'));
    expect(contrato, contains('max-age=90'));
    expect(contrato, contains('If-None-Match'));
  });
}
