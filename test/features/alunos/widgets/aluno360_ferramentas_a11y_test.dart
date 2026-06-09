import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_detail_ferramentas_tab.dart';

void main() {
  final aluno = Aluno(
    id: 42,
    nome: 'Beatriz Costa',
    email: 'beatriz@test.com',
    status: 'ATIVO',
    dataNascimento: '1998-04-12',
    altura: 1.65,
    aderenciaPercent: 0,
  );

  List<Map<String, dynamic>> aderenciaSemanaEndingToday() {
    final today = DateTime.now();
    final anchor = DateTime(today.year, today.month, today.day);
    return List.generate(7, (i) {
      final day = anchor.subtract(Duration(days: 6 - i));
      final iso =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      return {'data': iso, 'checkins': i.isEven ? 1 : 0};
    });
  }

  Widget harness(Widget child) {
    return ProviderScope(
      overrides: [
        alunoMedidasResumoProvider(42).overrideWith((ref) async => null),
        alunoAderenciaSemanalProvider(42).overrideWith(
          (ref) async => aderenciaSemanaEndingToday(),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 1200),
            textScaler: TextScaler.linear(1.3),
          ),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('ferramentas tab exposes section headers and registrar actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        Aluno360DetailFerramentasTab(
          aluno: aluno,
          alunoId: 42,
          isDark: false,
          primary: const Color(0xFF2563EB),
          perfilCompletion: 90,
          animateEntrance: false,
          onEntrancePlayed: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Medidas'), findsOneWidget);
    expect(find.text('Módulos'), findsOneWidget);
    expect(find.text('GORDURA'), findsOneWidget);
    expect(find.text('MASSA MAGRA'), findsOneWidget);
    expect(find.text('IA Progresso'), findsOneWidget);

    expect(
      find.bySemanticsLabel(RegExp(r'Toque para Registrar')),
      findsNWidgets(2),
    );

    expect(
      find.bySemanticsLabel(RegExp(r'Tendência semanal')),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });
}
