import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/navigation/fx_abertura_unica.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('toque duplo dentro da janela é ignorado; depois dela abre de novo', () {
    var agora = DateTime(2026, 11, 16, 10);
    final abertura = FxAberturaUnica(agora: () => agora);
    var aberturas = 0;
    Future<void> navegar() async => aberturas++;

    expect(abertura.abrir(navegar), isNotNull);
    agora = agora.add(const Duration(milliseconds: 200));
    expect(abertura.abrir(navegar), isNull);
    agora = agora.add(const Duration(milliseconds: 500));
    expect(abertura.abrir(navegar), isNotNull);
    expect(aberturas, 2);
  });

  // Regressão do relato "a prévia não abriu": prévia → Iniciar (pushReplacement)
  // → concluir → voltar → tocar no dia de novo tem que abrir a prévia.
  testWidgets('depois de a prévia virar execução, o dia abre a prévia de novo', (t) async {
    final abertura = FxAberturaUnica(janela: Duration.zero);
    late BuildContext hub;
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (c, _) {
          hub = c;
          return const Text('hub');
        },
      ),
      GoRoute(
        path: '/previa',
        builder: (c, _) => TextButton(
          onPressed: () => c.pushReplacement('/exec'),
          child: const Text('iniciar'),
        ),
      ),
      GoRoute(
        path: '/exec',
        builder: (c, _) => TextButton(onPressed: () => c.pop(), child: const Text('concluir')),
      ),
    ]);
    await t.pumpWidget(MaterialApp.router(routerConfig: router));

    abertura.abrir(() => hub.push<bool>('/previa'));
    await t.pumpAndSettle();
    await t.tap(find.text('iniciar'));
    await t.pumpAndSettle();
    await t.tap(find.text('concluir'));
    await t.pumpAndSettle();
    expect(find.text('hub'), findsOneWidget);

    expect(abertura.abrir(() => hub.push<bool>('/previa')), isNotNull);
    await t.pumpAndSettle();
    expect(find.text('iniciar'), findsOneWidget);
  });

  test('contrato: quem abre prévia ou execução não trava esperando a tela fechar', () {
    final arquivos = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    final presos = <String>[];
    for (final f in arquivos) {
      final codigo = f.readAsStringSync();
      final abre = codigo.contains('treinoPreviaPath(') && codigo.contains('context.push') ||
          codigo.contains('checkinExecutarPath(') && codigo.contains('context.push');
      if (!abre) continue;
      // A trava antiga: um bool ligado antes do push e desligado depois do await.
      if (RegExp(r'_abrindo\s*=\s*false').hasMatch(codigo)) presos.add(f.path);
    }
    expect(presos, isEmpty, reason: 'use FxAberturaUnica (lib/core/navigation)');
  });
}
