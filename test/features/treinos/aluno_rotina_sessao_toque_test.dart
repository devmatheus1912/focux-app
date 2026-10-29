import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/models/ficha_volume.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_choice_chip.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/aluno_rotina_screen.dart';
import 'package:focux_app/features/treinos/utils/ficha_vigencia.dart';
import 'package:focux_app/features/treinos/utils/semana_da_fila.dart';
import 'package:focux_app/features/treinos/utils/treino_criacao_fluxo.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTreinoRepository extends TreinoRepository {
  _FakeTreinoRepository(this.fila) : super(ApiClient());

  final RotinaFila fila;
  var buscas = 0;
  var gravacoes = 0;
  List<DiaDaSemana>? ultimaSemana;
  final copias = <(int, int, bool)>[];
  final duplicados = <int>[];
  final renomeados = <(int, String)>[];

  @override
  Future<Treino> renomearTreino(int id, String nome) async {
    renomeados.add((id, nome));
    return Treino(id: id, nome: nome, exercicios: const []);
  }
  final vigencias = <(int, int)>[];
  final renovacoes = <(int, int)>[];
  var vigenciasRemovidas = 0;

  @override
  Future<FichaVolume> volumeDaFicha(int alunoId) async => FichaVolume.vazio;

  @override
  Future<RotinaFila> buscarRotina(int alunoId) async {
    buscas++;
    return fila;
  }

  @override
  Future<RotinaFila> gravarSemana(int alunoId, List<DiaDaSemana> dias) async {
    gravacoes++;
    ultimaSemana = dias;
    return fila;
  }

  @override
  Future<RotinaFila> copiarSemana(
    int alunoId,
    int destinoId, {
    bool manterCargas = true,
  }) async {
    copias.add((alunoId, destinoId, manterCargas));
    return fila;
  }

  @override
  Future<RotinaFila> definirVigenciaSemanas(int alunoId, int semanas) async {
    vigencias.add((alunoId, semanas));
    return fila;
  }

  @override
  Future<RotinaFila> renovarVigencia(int alunoId, int semanas) async {
    renovacoes.add((alunoId, semanas));
    return fila;
  }

  @override
  Future<RotinaFila> removerVigencia(int alunoId) async {
    vigenciasRemovidas++;
    return fila;
  }

  @override
  Future<Treino> duplicar(int id) async {
    duplicados.add(id);
    return Treino(id: 99, nome: 'Cópia de Peito', exercicios: const []);
  }
}

const _fila = RotinaFila(
  itens: [
    RotinaItem(
      id: 1,
      tipo: RotinaItemTipo.treino,
      treinoId: 7,
      nome: 'Peito',
      diaSemana: 1,
      exerciciosCount: 5,
    ),
    RotinaItem(
      id: 2,
      tipo: RotinaItemTipo.treino,
      nome: 'Costas',
      diaSemana: 2,
    ),
  ],
  diasAviso: {3, 4, 5, 6, 7},
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<(_FakeTreinoRepository, GoRouter)> _abrir(
  WidgetTester tester,
  List<Object?> aberturas, {
  RotinaFila fila = _fila,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repo = _FakeTreinoRepository(fila);
  final router = GoRouter(
    initialLocation: '/alunos/3/rotina',
    routes: [
      GoRoute(
        path: '/alunos/:id/rotina',
        builder: (context, state) =>
            const AlunoRotinaScreen(alunoId: 3, alunoNome: ' Ana '),
      ),
      GoRoute(
        path: '/treinos/:id',
        builder: (context, state) {
          aberturas.add((state.pathParameters['id'], state.extra));
          return Scaffold(appBar: AppBar(), body: const Text('montador'));
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [treinoRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
          useMaterial3: true,
        ),
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await _settle(tester);
  return (repo, router);
}

Future<void> _abrirMenuDaSessao(WidgetTester tester, {int indice = 0}) async {
  await tester.tap(find.byTooltip('Mais ações da sessão').at(indice));
  await _settle(tester);
}

Future<void> _abrirMenuDaFicha(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Opções da ficha'));
  await _settle(tester);
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('abrir o montador', () {
    testWidgets('tocar numa sessão abre o montador com o aluno', (tester) async {
      final aberturas = <Object?>[];
      await _abrir(tester, aberturas);

      await tester.tap(find.text('Peito'));
      await _settle(tester);

      expect(find.text('montador'), findsOneWidget);
      final (id, extra) = aberturas.single! as (String?, Object?);
      expect(id, '7');
      final lido = TreinoRouteExtra.parse(extra);
      expect(lido.alunoId, 3);
      expect(lido.alunoNome, 'Ana');
    });

    testWidgets('sessão sem treinoId não navega', (tester) async {
      final aberturas = <Object?>[];
      await _abrir(tester, aberturas);

      await tester.tap(find.text('Costas'));
      await _settle(tester);

      expect(find.text('montador'), findsNothing);
      expect(aberturas, isEmpty);
    });

    testWidgets('voltar do montador recarrega a semana', (tester) async {
      final (repo, router) = await _abrir(tester, <Object?>[]);
      final antes = repo.buscas;

      await tester.tap(find.text('Peito'));
      await _settle(tester);
      router.pop();
      await _settle(tester);

      expect(find.text('Peito'), findsOneWidget);
      expect(repo.buscas, greaterThan(antes));
    });
  });

  group('estado da ficha', () {
    testWidgets('cada sessão mostra quantos exercícios tem', (tester) async {
      await _abrir(
        tester,
        <Object?>[],
        fila: const RotinaFila(
          itens: [
            RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 7, nome: 'Peito', diaSemana: 1, exerciciosCount: 5),
            RotinaItem(id: 2, tipo: RotinaItemTipo.treino, treinoId: 8, nome: 'Costas', diaSemana: 2, exerciciosCount: 1),
            RotinaItem(id: 3, tipo: RotinaItemTipo.treino, treinoId: 9, nome: 'Pernas', diaSemana: 3, exerciciosCount: 0),
          ],
          diasAviso: {4, 5, 6, 7},
        ),
      );

      expect(find.text('5 exercícios'), findsOneWidget);
      expect(find.text('1 exercício'), findsOneWidget);
      expect(find.text('Vazio'), findsOneWidget);
      expect(find.text('Montar'), findsOneWidget);
      expect(find.text('3 dias · 2 de 3 prontas'), findsOneWidget);
      expect(find.text('1 treino incompleto'), findsOneWidget);
    });

    testWidgets('tudo pronto não mostra aviso de incompleto', (tester) async {
      await _abrir(tester, <Object?>[]);
      expect(find.text('2 dias · tudo pronto'), findsOneWidget);
      expect(find.textContaining('incompleto'), findsNothing);
    });

    testWidgets('um único botão preenchido: Pronto', (tester) async {
      await _abrir(tester, <Object?>[]);
      expect(find.byType(FxLiquidPrimaryButton), findsOneWidget);
      expect(find.text('Pronto'), findsOneWidget);
    });
  });

  group('ficha vazia', () {
    Future<void> criar(WidgetTester tester) async {
      await tester.tap(find.text('Criar ficha'));
      await _settle(tester);
    }

    String sessoes(List<DiaDaSemana> semana) => [
      for (final d in semana)
        if (d.sessoes.isNotEmpty)
          '${d.dia}:${d.sessoes.single.nome}'
        else if (d.segueSequencia)
          '${d.dia}:segue',
    ].join(' ');

    testWidgets('oferece 2 a 7 dias; 4 com ABCD cria Treino A a D', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[], fila: RotinaFila.vazia);

      expect(find.text('Quantos dias por semana?'), findsOneWidget);
      for (final n in [2, 3, 4, 5, 6, 7]) {
        expect(find.text('$n'), findsOneWidget);
      }

      await tester.tap(find.text('4'));
      await _settle(tester);
      expect(repo.gravacoes, 0, reason: 'escolher os dias só monta a prévia');
      await tester.tap(find.text('ABCD'));
      await _settle(tester);
      await criar(tester);

      expect(repo.gravacoes, 1);
      expect(sessoes(repo.ultimaSemana!), '1:Treino A 2:Treino B 4:Treino C 5:Treino D');
    });

    testWidgets('5 dias já vem com ABC: três sessões e dois dias seguindo a sequência', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[], fila: RotinaFila.vazia);

      await tester.tap(find.text('5'));
      await _settle(tester);
      expect(find.text('Recomendada: ABC'), findsOneWidget);
      expect(find.text('Segue a sequência'), findsNWidgets(2));
      await criar(tester);

      expect(
        sessoes(repo.ultimaSemana!),
        '1:A · Peito e tríceps 2:B · Costas e bíceps 3:C · Pernas e glúteo 4:segue 5:segue',
      );
    });

    testWidgets('na prévia, tocar num dia troca treino por descanso', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[], fila: RotinaFila.vazia);

      await tester.tap(find.text('5'));
      await _settle(tester);
      await tester.tap(find.widgetWithText(FxChoiceChip, 'Qua'));
      await _settle(tester);
      await tester.tap(find.widgetWithText(FxChoiceChip, 'Sáb'));
      await _settle(tester);
      await criar(tester);

      expect(
        sessoes(repo.ultimaSemana!),
        '1:A · Peito e tríceps 2:B · Costas e bíceps 4:C · Pernas e glúteo 5:segue 6:segue',
      );
    });

    testWidgets('outras divisões ficam recolhidas', (tester) async {
      await _abrir(tester, <Object?>[], fila: RotinaFila.vazia);

      await tester.tap(find.text('3'));
      await _settle(tester);
      expect(find.text('Glúteo e pernas'), findsNothing);
      await tester.tap(find.text('Outras divisões'));
      await _settle(tester);
      expect(find.text('Glúteo e pernas'), findsOneWidget);
    });

    testWidgets('sem escolher os dias, Criar ficha fica desligado', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[], fila: RotinaFila.vazia);
      await criar(tester);
      expect(repo.gravacoes, 0);
    });

    testWidgets('com sessões, a pergunta de frequência não aparece', (tester) async {
      await _abrir(tester, <Object?>[]);
      expect(find.text('Quantos dias por semana?'), findsNothing);
    });

    testWidgets('copiar de outro aluno aparece na ficha vazia', (tester) async {
      await _abrir(tester, <Object?>[], fila: RotinaFila.vazia);
      expect(find.text('Copiar a ficha de outro aluno'), findsOneWidget);
    });
  });

  group('renomear', () {
    testWidgets('o "…" da sessão renomeia e busca a semana de novo', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[]);
      final antes = repo.buscas;

      await _abrirMenuDaSessao(tester);
      await tester.tap(find.text('Renomear sessão'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'A · Peito e tríceps');
      await tester.tap(find.text('Pronto').last);
      await _settle(tester);

      expect(repo.renomeados, [(7, 'A · Peito e tríceps')]);
      expect(repo.buscas, greaterThan(antes));
    });

    testWidgets('sessão sem treino não oferece renomear', (tester) async {
      await _abrir(tester, <Object?>[]);
      await _abrirMenuDaSessao(tester, indice: 1);
      expect(find.text('Renomear sessão'), findsNothing);
    });
  });

  group('segue a sequência', () {
    const rodizio = RotinaFila(
      itens: [
        RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 7, nome: 'Treino A', diaSemana: 1, exerciciosCount: 3),
        RotinaItem(id: 2, tipo: RotinaItemTipo.treino, treinoId: 8, nome: 'Treino B', diaSemana: 2, exerciciosCount: 3),
      ],
      diasAviso: {5, 6, 7},
    );

    testWidgets('dia fora do aviso aparece como Segue a sequência', (tester) async {
      await _abrir(tester, <Object?>[], fila: rodizio);
      expect(find.text('Segue a sequência'), findsNWidgets(2));
      expect(find.text('4 dias · tudo pronto'), findsOneWidget);
    });

    testWidgets('o "…" de um dia que segue marca descanso', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[], fila: rodizio);

      await tester.tap(find.byTooltip('Mais ações da sessão').at(2));
      await _settle(tester);
      await tester.tap(find.text('Marcar descanso'));
      await _settle(tester);

      final quarta = repo.ultimaSemana!.firstWhere((d) => d.dia == 3);
      expect(quarta.descanso, isTrue);
      expect(quarta.segueSequencia, isFalse);
    });

    testWidgets('o "…" de um descanso oferece Treinar neste dia', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[], fila: rodizio);

      await tester.tap(find.byTooltip('Mais ações da sessão').last);
      await _settle(tester);
      await tester.tap(find.text('Treinar neste dia'));
      await _settle(tester);

      expect(repo.ultimaSemana!.firstWhere((d) => d.dia == 7).segueSequencia, isTrue);
    });
  });

  group('vigência', () {
    testWidgets('ficha vazia: "Vale por" começa em 8 semanas e grava junto com os dias', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[], fila: RotinaFila.vazia);

      await tester.tap(find.text('4'));
      await _settle(tester);
      expect(find.text('Vale por 8 semanas'), findsOneWidget);
      await tester.tap(find.text('Criar ficha'));
      await _settle(tester);

      expect(repo.gravacoes, 1);
      expect(repo.vigencias, [(3, 8)]);
    });

    testWidgets('escolher 12 semanas grava 12', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[], fila: RotinaFila.vazia);

      await tester.tap(find.text('3'));
      await _settle(tester);
      await tester.tap(find.text('Vale por 8 semanas'));
      await _settle(tester);
      await tester.tap(find.text('12 semanas'));
      await _settle(tester);
      await tester.tap(find.text('Criar ficha'));
      await _settle(tester);

      expect(repo.vigencias, [(3, 12)]);
    });

    testWidgets('sem prazo cria a ficha sem definir vigência', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[], fila: RotinaFila.vazia);

      await tester.tap(find.text('3'));
      await _settle(tester);
      await tester.tap(find.text('Vale por 8 semanas'));
      await _settle(tester);
      await tester.tap(find.text('Sem prazo'));
      await _settle(tester);
      await tester.tap(find.text('Criar ficha'));
      await _settle(tester);

      expect(repo.gravacoes, 1);
      expect(repo.vigencias, isEmpty);
    });

    testWidgets('ficha com sessões mostra a linha Vigência com o estado', (tester) async {
      final amanha = DateTime.now().add(const Duration(days: 3));
      await _abrir(
        tester,
        <Object?>[],
        fila: RotinaFila(
          itens: const [
            RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 7, nome: 'Peito', diaSemana: 1, exerciciosCount: 5),
          ],
          vigencia: VigenciaFicha(fim: amanha),
        ),
      );

      expect(find.text('Vigência'), findsOneWidget);
      expect(find.text('Vence em 3 dias'), findsOneWidget);
      expect(find.text('Vale por'), findsNothing);
    });

    testWidgets('sem prazo, a linha diz "Sem prazo"', (tester) async {
      await _abrir(tester, <Object?>[]);
      expect(find.text('Vigência'), findsOneWidget);
      expect(find.text('Sem prazo'), findsOneWidget);
    });

    testWidgets('o menu renova por 8 semanas e avisa até quando vale', (tester) async {
      final (repo, _) = await _abrir(
        tester,
        <Object?>[],
        fila: RotinaFila(
          itens: const [
            RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 7, nome: 'Peito', diaSemana: 1, exerciciosCount: 5),
          ],
          vigencia: VigenciaFicha(fim: DateTime.now().add(const Duration(days: 40))),
        ),
      );
      await tester.tap(find.text('Vigência'));
      await _settle(tester);
      await tester.tap(find.text('Renovar por 8 semanas'));
      await _settle(tester);

      expect(repo.renovacoes, [(3, 8)]);
      expect(find.textContaining('Ficha vale até'), findsOneWidget);
    });

    testWidgets('o menu tira o prazo', (tester) async {
      final (repo, _) = await _abrir(
        tester,
        <Object?>[],
        fila: RotinaFila(
          itens: const [
            RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 7, nome: 'Peito', diaSemana: 1, exerciciosCount: 5),
          ],
          vigencia: VigenciaFicha(fim: DateTime.now().add(const Duration(days: 40))),
        ),
      );
      await tester.tap(find.text('Vigência'));
      await _settle(tester);
      await tester.tap(find.text('Sem prazo').last);
      await _settle(tester);

      expect(repo.vigenciasRemovidas, 1);
    });
  });

  group('menu da sessão', () {
    testWidgets('lista as quatro ações de uma sessão salva', (tester) async {
      await _abrir(tester, <Object?>[]);
      await _abrirMenuDaSessao(tester);

      expect(find.text('Mais um neste dia'), findsOneWidget);
      expect(find.text('Mover para outro dia'), findsOneWidget);
      expect(find.text('Copiar para outro dia'), findsOneWidget);
      expect(find.text('Marcar descanso'), findsOneWidget);
    });

    testWidgets('sessão ainda sem treinoId não oferece copiar', (tester) async {
      await _abrir(tester, <Object?>[]);
      await _abrirMenuDaSessao(tester, indice: 1);

      expect(find.text('Copiar para outro dia'), findsNothing);
      expect(find.text('Mover para outro dia'), findsOneWidget);
    });

    testWidgets('marcar descanso pede confirmação e cancelar mantém', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[]);
      await _abrirMenuDaSessao(tester);
      await tester.tap(find.text('Marcar descanso'));
      await _settle(tester);

      expect(find.text('Marcar descanso?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await _settle(tester);
      expect(repo.gravacoes, 0);

      await _abrirMenuDaSessao(tester);
      await tester.tap(find.text('Marcar descanso'));
      await _settle(tester);
      await tester.tap(find.text('Marcar descanso').last);
      await _settle(tester);
      expect(repo.gravacoes, 1);
      expect(repo.ultimaSemana!.firstWhere((d) => d.dia == 1).sessoes, isEmpty);
    });

    testWidgets('mover leva a sessão para o dia escolhido', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[]);
      await _abrirMenuDaSessao(tester);
      await tester.tap(find.text('Mover para outro dia'));
      await _settle(tester);

      expect(find.text('Para qual dia?'), findsOneWidget);
      await tester.tap(find.text('Qua').last);
      await _settle(tester);

      final semana = repo.ultimaSemana!;
      expect(semana.firstWhere((d) => d.dia == 3).sessoes.single.nome, 'Peito');
      expect(semana.firstWhere((d) => d.dia == 1).sessoes, isEmpty);
    });

    testWidgets('copiar duplica o treino e põe a cópia no dia escolhido', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[]);
      await _abrirMenuDaSessao(tester);
      await tester.tap(find.text('Copiar para outro dia'));
      await _settle(tester);
      await tester.tap(find.text('Sex').last);
      await _settle(tester);

      expect(repo.duplicados, [7]);
      final sexta = repo.ultimaSemana!.firstWhere((d) => d.dia == 5);
      expect(sexta.sessoes.single.treinoId, 99);
      expect(sexta.sessoes.single.nome, 'Cópia de Peito');
    });
  });

  group('menu da ficha', () {
    testWidgets('recomeçar pede confirmação e zera a semana', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[]);
      await _abrirMenuDaFicha(tester);
      await tester.tap(find.text('Recomeçar ficha'));
      await _settle(tester);

      expect(find.text('Recomeçar a ficha?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await _settle(tester);
      expect(repo.gravacoes, 0);

      await _abrirMenuDaFicha(tester);
      await tester.tap(find.text('Recomeçar ficha'));
      await _settle(tester);
      await tester.tap(find.text('Recomeçar ficha').last);
      await _settle(tester);

      expect(repo.gravacoes, 1);
      expect(repo.ultimaSemana!.every((d) => d.sessoes.isEmpty), isTrue);
    });

    testWidgets('duplicar como base pergunta as cargas', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[]);
      await _abrirMenuDaFicha(tester);
      await tester.tap(find.text('Duplicar como base'));
      await _settle(tester);

      expect(find.text('Manter as cargas?'), findsOneWidget);
      await tester.tap(find.text('Começar do zero'));
      await _settle(tester);

      expect(repo.copias, [(3, 3, false)]);
    });

    testWidgets('fechar a pergunta de cargas não copia nada', (tester) async {
      final (repo, _) = await _abrir(tester, <Object?>[]);
      await _abrirMenuDaFicha(tester);
      await tester.tap(find.text('Duplicar como base'));
      await _settle(tester);
      await tester.tapAt(const Offset(10, 10));
      await _settle(tester);

      expect(repo.copias, isEmpty);
    });
  });

  group('sessão adiada', () {
    testWidgets('avisa que a troca vale quando o aluno terminar o treino', (tester) async {
      await _abrir(
        tester,
        <Object?>[],
        fila: const RotinaFila(
          itens: [
            RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 7, nome: 'Peito', diaSemana: 1, exerciciosCount: 5),
          ],
          sessoesAdiadas: ['Costas', 'Pernas'],
        ),
      );
      expect(
        find.text('A troca de Costas, Pernas vale quando Ana terminar o treino.'),
        findsOneWidget,
      );
    });

    testWidgets('sem sessão adiada, não mostra o aviso', (tester) async {
      await _abrir(tester, <Object?>[]);
      expect(find.textContaining('A troca de'), findsNothing);
    });

    test('sessoesAdiadas vem do JSON; ausente vira lista vazia', () {
      expect(
        RotinaFila.fromJson({'itens': [], 'sessoesAdiadas': ['Costas']}).sessoesAdiadas,
        ['Costas'],
      );
      expect(RotinaFila.fromJson({'itens': []}).sessoesAdiadas, isEmpty);
    });
  });

  test('exerciciosCount vem do JSON da rotina', () {
    final fila = RotinaFila.fromJson({
      'itens': [
        {
          'id': 1,
          'tipo': 'TREINO',
          'treinoId': 7,
          'nome': 'Peito',
          'diaSemana': 1,
          'exerciciosCount': 4,
        },
        {'id': 2, 'tipo': 'DESCANSO'},
      ],
    });
    expect(fila.itens.first.exerciciosCount, 4);
    expect(fila.itens.last.exerciciosCount, isNull);
    expect(semanaDaFila(fila).first.sessoes.single.exerciciosCount, 4);
  });

  test('tela da semana não tem texto fixo fora do arb', () {
    final fontes = [
      'lib/features/treinos/screens/aluno_rotina_screen.dart',
      'lib/features/treinos/widgets/ficha_semana.dart',
      'lib/features/treinos/widgets/ficha_acoes.dart',
    ].map((p) => File(p).readAsStringSync()).join('\n');
    for (final texto in [
      "'Nome da sessão'",
      "'Toque para nomear'",
      "'Mais um neste dia'",
      "'Pronto'",
      "'Usar em outro aluno'",
      "'Cancelar'",
      "'Recomeçar ficha'",
      "'Duplicar como base'",
    ]) {
      expect(fontes, isNot(contains(texto)));
    }
  });
}
