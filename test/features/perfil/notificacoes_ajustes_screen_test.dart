import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/notificacoes/aviso_fim_descanso.dart';
import 'package:focux_app/features/perfil/data/notificacoes_preferencias_repository.dart';
import 'package:focux_app/features/perfil/screens/notificacoes_ajustes_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RepoFalso extends NotificacoesPreferenciasRepository {
  _RepoFalso() : super(Dio());

  final salvos = <String, bool>{};
  var testes = 0;
  ResultadoDoTeste resultado = ResultadoDoTeste.enviado;

  List<PreferenciaDeNotificacao> _itens() => [
    PreferenciaDeNotificacao(
      tipo: 'DESCANSO',
      rotulo: 'Fim do descanso',
      descricao: 'Aviso quando o descanso acaba',
      ligado: salvos['DESCANSO'] ?? true,
    ),
    PreferenciaDeNotificacao(
      tipo: 'CHAT',
      rotulo: 'Mensagens',
      descricao: 'Mensagens do chat',
      ligado: salvos['CHAT'] ?? true,
    ),
    PreferenciaDeNotificacao(
      tipo: 'OFERTAS',
      rotulo: 'Ofertas e dicas do Focux',
      descricao: '',
      ligado: salvos['OFERTAS'] ?? false,
    ),
  ];

  @override
  Future<List<PreferenciaDeNotificacao>> listar() async => _itens();

  @override
  Future<List<PreferenciaDeNotificacao>> salvar(
    PreferenciaDeNotificacao item,
  ) async {
    salvos[item.tipo] = item.ligado;
    return _itens();
  }

  @override
  Future<ResultadoDoTeste> testar() async {
    testes++;
    return resultado;
  }
}

Future<void> _abrir(WidgetTester tester, _RepoFalso repo) async {
  tester.view.physicalSize = const Size(1170, 2600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: NotificacoesAjustesScreen(repositorio: repo),
      ),
    ),
  );
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('mostra os tipos com o padrão: ofertas desligado', (
    tester,
  ) async {
    await _abrir(tester, _RepoFalso());
    expect(find.text('Notificações'), findsWidgets);
    expect(find.text('Mensagens'), findsOneWidget);
    expect(find.text('Ofertas e dicas do Focux'), findsOneWidget);
    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    // Descanso, Mensagens, Ofertas e o som do descanso.
    expect(switches.map((s) => s.value), [true, true, false, true]);
    expect(find.text('Som no fim do descanso'), findsOneWidget);
  });

  testWidgets('desligar um tipo salva no servidor', (tester) async {
    final repo = _RepoFalso();
    await _abrir(tester, repo);
    await tester.tap(find.byType(Switch).at(1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(repo.salvos['CHAT'], isFalse);
  });

  testWidgets('fim do descanso também vale no aparelho (aviso local)', (
    tester,
  ) async {
    final repo = _RepoFalso();
    await _abrir(tester, repo);
    await tester.tap(find.byType(Switch).first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(repo.salvos['DESCANSO'], isFalse);
    expect(await PreferenciasDoDescanso.avisoLigado(), isFalse);
  });

  testWidgets('notificação de teste diz o resultado', (tester) async {
    final repo = _RepoFalso()..resultado = ResultadoDoTeste.semAparelho;
    await _abrir(tester, repo);
    await tester.ensureVisible(find.text('Enviar notificação de teste'));
    await tester.tap(find.text('Enviar notificação de teste'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.testes, 1);
    expect(find.textContaining('não tem notificações ativas'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
