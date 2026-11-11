import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_confirm_sheet.dart';
import 'package:focux_app/core/widgets/fx_tonal_button.dart';
import 'package:focux_app/features/feedback/data/feedback_video_repository.dart';
import 'package:focux_app/features/feedback/utils/feedback_video_display.dart';
import 'package:focux_app/features/grupos/utils/grupo_aula_display.dart';
import 'package:focux_app/features/trilhas/models/trilha.dart';
import 'package:focux_app/features/trilhas/utils/trilhas_display.dart';
import 'package:google_fonts/google_fonts.dart';

TrilhaModel _trilha(List<MarcoModel> marcos, {String? fim}) => TrilhaModel(
  id: 1,
  alunoId: 2,
  titulo: 'Barra fixa',
  metaTipo: 'CUSTOM',
  valorAtual: 0,
  percentualConclusao: 0,
  concluida: marcos.every((m) => m.concluido),
  marcos: marcos,
  dataFim: fim,
);

void main() {
  group('trilha concluída', () {
    test('resumo diz a data da última etapa e não mostra prazo', () {
      final t = _trilha([
        MarcoModel(id: 1, titulo: 'A', ordem: 0, concluido: true, concluidoEm: DateTime(2026, 11, 2)),
        MarcoModel(id: 2, titulo: 'B', ordem: 1, concluido: true, concluidoEm: DateTime(2026, 11, 10)),
      ], fim: '2026-12-10');
      expect(trilhaResumoLinha(t), 'Concluída em 10/11');
      expect(trilhaPrazoLabel(t, DateTime(2026, 11, 11)), isNull);
    });

    test('em andamento segue com etapa e prazo', () {
      final t = _trilha([
        const MarcoModel(id: 1, titulo: 'A', ordem: 0, concluido: true),
        const MarcoModel(id: 2, titulo: 'B', ordem: 1, concluido: false),
      ], fim: '2026-12-10');
      expect(trilhaResumoLinha(t), 'Etapa 2 de 2 · Próxima: B');
      expect(trilhaPrazoLabel(t, DateTime(2026, 11, 11)), 'até 10/12');
    });
  });

  group('aulas em grupo', () {
    test('rótulo da linha', () {
      expect(grupoAulaStatusLabel(inscrito: true, lotada: true), 'Inscrito');
      expect(grupoAulaStatusLabel(inscrito: false, lotada: false), 'Inscrever');
      expect(grupoAulaStatusLabel(inscrito: false, lotada: true), 'Lotada');
    });

    test('vagas só quando restam poucas', () {
      expect(grupoAulaPoucasVagas(inscritos: 5, capacidadeMax: 20), isNull);
      expect(grupoAulaPoucasVagas(inscritos: 17, capacidadeMax: 20), '3 vagas');
      expect(grupoAulaPoucasVagas(inscritos: 19, capacidadeMax: 20), '1 vaga');
      expect(grupoAulaPoucasVagas(inscritos: 20, capacidadeMax: 20), isNull);
    });

    test('duração: rótulos e duração gravada fora das quatro', () {
      expect(grupoAulaDuracaoLabel(45), '45 min');
      expect(grupoAulaDuracaoLabel(60), '1 h');
      expect(grupoAulaDuracaoLabel(90), '1 h 30');
      expect(grupoAulaDuracaoFora(60), isNull);
      expect(grupoAulaDuracaoFora(75), 75);
    });
  });

  group('feedback em vídeo', () {
    test('exercícios agrupados por treino, na ordem do servidor', () {
      final grupos = exerciciosPorTreino([
        ExercicioOpcao(id: 1, nome: 'Supino', treinoNome: 'A · Empurrar'),
        ExercicioOpcao(id: 2, nome: 'Remada', treinoNome: 'B · Puxar'),
        ExercicioOpcao(id: 3, nome: 'Tríceps', treinoNome: 'A · Empurrar'),
      ]);
      expect(grupos.map((g) => g.$1), ['A · Empurrar', 'B · Puxar']);
      expect(grupos.first.$2.map((e) => e.id), [1, 3]);
    });

    test('backend antigo (sem treinoNome): uma lista só', () {
      final grupos = exerciciosPorTreino([
        ExercicioOpcao(id: 1, nome: 'Supino'),
        ExercicioOpcao(id: 2, nome: 'Remada'),
      ]);
      expect(grupos, hasLength(1));
      expect(grupos.first.$1, isNull);
    });

    test('recado com dor vai em alerta', () {
      expect(feedbackRecadoFalaDeDor('Senti joelho no fim'), isTrue);
      expect(feedbackRecadoFalaDeDor('Deu dor no ombro'), isTrue);
      expect(feedbackRecadoFalaDeDor('Ficou pesado'), isFalse);
      expect(feedbackRecadoFalaDeDor('Fiz dorsal'), isFalse);
    });
  });

  test('showTimePicker só no fx_horario.dart', () {
    final achados = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final caminho = f.path.replaceAll(r'\', '/');
      if (caminho.endsWith('core/widgets/fx_horario.dart')) continue;
      if (f.readAsStringSync().contains('showTimePicker(')) achados.add(caminho);
    }
    expect(achados, isEmpty);
  });

  group('folha de confirmação', () {
    Future<void> abrir(WidgetTester tester, {bool discard = false}) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => TextButton(
                    onPressed:
                        () => showFxConfirmSheet(
                          context,
                          title: 'Aplicar no treino?',
                          message: 'Carga vai para o treino.',
                          confirmLabel: 'Aplicar',
                          discard: discard,
                        ),
                    child: const Text('abrir'),
                  ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('dois botões com a mesma largura e sem X', (tester) async {
      await abrir(tester);
      final aplicar = tester.getSize(find.text('Aplicar').hitTestable());
      expect(aplicar, isNotNull);
      final cancelar = find.ancestor(
        of: find.text('Cancelar'),
        matching: find.byType(FxTonalButton),
      );
      final largCancelar = tester.getSize(cancelar).width;
      final largAplicar =
          tester
              .getSize(
                find.ancestor(
                  of: find.text('Aplicar'),
                  matching: find.byType(ElevatedButton),
                ),
              )
              .width;
      expect(largCancelar, closeTo(largAplicar, 1));
      expect(find.byTooltip('Fechar'), findsNothing);
    });

    testWidgets('descartar: "Descartar" em vermelho', (tester) async {
      await abrir(tester, discard: true);
      final botao = tester.widget<FxTonalButton>(
        find.ancestor(
          of: find.text('Aplicar'),
          matching: find.byType(FxTonalButton),
        ),
      );
      expect(botao.danger, isTrue);
      expect(botao.compact, isFalse);
    });
  });
}
