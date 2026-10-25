import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_metric_strip.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';

import '../../support/migracao_harness.dart';

void main() {
  group('etapa 1', () {
    testWidgets('texto: ajuda curta, sem OCR nem cota de foto', (tester) async {
      await abrirMigracao(tester, alunos: [], detalhes: []);

      await tester.tap(find.text('Colar texto').first);
      await assentarMigracao(tester);

      expect(find.textContaining('Cole os dados dos alunos'), findsOneWidget);
      expect(find.textContaining('leitura gratuita'), findsNothing);
      expect(find.textContaining('Fotos este mês'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Colar texto'), findsOneWidget);
    });

    testWidgets('foto: a leitura gratuita e a cota aparecem só aqui', (tester) async {
      await abrirMigracao(tester, alunos: [], detalhes: []);

      await tester.tap(find.text('Foto ou print').first);
      await assentarMigracao(tester);

      expect(find.textContaining('leitura gratuita'), findsOneWidget);
      expect(find.textContaining('Fotos este mês'), findsOneWidget);
    });
  });

  group('etapa 2', () {
    testWidgets('uma instrução, vagas sem "todos os 1", linhas ignoradas reais', (tester) async {
      await abrirMigracao(
        tester,
        alunos: [linhaMigracao('Ana Souza', email: 'ana@x.com')],
        ignorados: 2,
        amostras: ['|', 'Alunos Buscar'],
        detalhes: [],
      );
      await ateRevisaoMigracao(tester);

      expect(find.text('1 alunos encontrados').evaluate().isNotEmpty ||
          find.textContaining('encontrado').evaluate().isNotEmpty, isTrue);
      expect(find.textContaining('Toque para editar'), findsOneWidget);
      expect(find.textContaining('pode importar todos os'), findsNothing);
      expect(find.text('Plano ilimitado.'), findsNothing);
      // A linha "|" não aparece; a de verdade, sim.
      expect(find.text('1 linha ignorada'), findsOneWidget);
    });

    testWidgets('Voltar é um botão secundário ao lado do principal', (tester) async {
      await abrirMigracao(
        tester,
        alunos: [linhaMigracao('Ana Souza', email: 'ana@x.com')],
        detalhes: [],
      );
      await ateRevisaoMigracao(tester);

      expect(find.widgetWithText(OutlinedButton, 'Voltar'), findsOneWidget);
    });
  });

  group('etapa 3', () {
    testWidgets('números sem alarme: zero apagado e sem botão', (tester) async {
      await abrirMigracao(
        tester,
        alunos: [linhaMigracao('Ana Souza', email: 'ana@x.com')],
        detalhes: [detalheMigracao('Ana Souza', email: 'ana@x.com', emailEnviado: true, emailReal: true)],
      );
      await ateRevisaoMigracao(tester);
      await ateResultadoMigracao(tester, 'Importar 1 aluno');

      expect(find.byType(FxMetricStrip), findsOneWidget);
      expect(find.text('Importados'), findsOneWidget);
      expect(find.text('Duplicados'), findsOneWidget);
      expect(find.text('Erros'), findsOneWidget);
      final strip = tester.widget<FxMetricStrip>(find.byType(FxMetricStrip));
      expect(strip.metricas.every((m) => m.onTap == null), isTrue);
    });

    testWidgets('e-mail que não saiu não diz "sem e-mail"', (tester) async {
      await abrirMigracao(
        tester,
        alunos: [linhaMigracao('João Lima', email: 'joao@gmail.com')],
        detalhes: [detalheMigracao('João Lima', email: 'joao@gmail.com', emailReal: true)],
      );
      await ateRevisaoMigracao(tester);
      await ateResultadoMigracao(tester, 'Importar 1 aluno');

      expect(find.text('E-mail não saiu'), findsOneWidget);
      expect(find.textContaining('não têm telefone nem e-mail'), findsNothing);
      expect(find.textContaining('Envie manualmente'), findsNothing);
    });

    testWidgets('um primário só; WhatsApp e link como secundários', (tester) async {
      await abrirMigracao(
        tester,
        alunos: [linhaMigracao('Carlos Lima', telefone: '11988887777')],
        detalhes: [detalheMigracao('Carlos Lima', telefone: '11988887777')],
      );
      await ateRevisaoMigracao(tester);
      await ateResultadoMigracao(tester, 'Importar 1 aluno');

      expect(find.text('Só telefone'), findsOneWidget);
      expect(find.widgetWithText(FxLiquidPrimaryButton, 'Ir para lista'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Enviar no WhatsApp'), findsOneWidget);
      expect(find.widgetWithText(FxLiquidPrimaryButton, 'Enviar no WhatsApp'), findsNothing);
    });

    testWidgets('"Copiar os N convites" só com 2 ou mais no grupo', (tester) async {
      await abrirMigracao(
        tester,
        alunos: [linhaMigracao('Carlos Lima', telefone: '11988887777')],
        detalhes: [detalheMigracao('Carlos Lima', telefone: '11988887777')],
      );
      await ateRevisaoMigracao(tester);
      await ateResultadoMigracao(tester, 'Importar 1 aluno');

      expect(find.text('Copiar o convite'), findsNothing);
      expect(find.textContaining('Copiar os'), findsNothing);
    });

    testWidgets('grupos de quem recebeu, não recebeu e sem contato', (tester) async {
      await abrirMigracao(
        tester,
        alunos: [
          linhaMigracao('Ana', email: 'ana@x.com'),
          linhaMigracao('Bia', email: 'bia@x.com'),
          linhaMigracao('Caio', telefone: '11988887777'),
          linhaMigracao('Duda'),
        ],
        detalhes: [
          detalheMigracao('Ana', email: 'ana@x.com', emailEnviado: true, emailReal: true, id: 1),
          detalheMigracao('Bia', email: 'bia@x.com', emailReal: true, id: 2),
          detalheMigracao('Caio', telefone: '11988887777', id: 3),
          detalheMigracao('Duda', id: 4),
        ],
      );
      await ateRevisaoMigracao(tester);
      await ateResultadoMigracao(tester, 'Importar 4 alunos');

      expect(find.text('E-mail enviado'), findsWidgets);
      expect(find.text('E-mail não saiu'), findsOneWidget);
      expect(find.text('Só telefone'), findsOneWidget);
      expect(find.text('Sem contato'), findsOneWidget);
      expect(find.textContaining('Os links valem 7 dias'), findsOneWidget);
    });
  });
}
