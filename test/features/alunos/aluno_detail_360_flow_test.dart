import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/aluno_detail_providers.dart';
import 'package:focux_app/features/alunos/widgets/aluno360_timeline_full_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

/// Flow Histórico 360 — sheet isolado (sem AlunoDetailScreen completo).
/// Mount full-screen + GoRouter + idle prefetch travava isolate (99% CPU / CI cancel).
const _alunoId = 42;

final _timelineFixture = List.generate(
  5,
  (i) => Timeline360Event(
    tipo: 'CHECKIN',
    titulo: 'Check-in ${i + 1}',
    corpo: 'Treino concluído',
    meta: 'Peito',
    ocorridoEm: '2026-06-0${i + 1}T10:00:00',
    deepLink: '',
    prioridade: 'P2',
  ),
);

final _alunoFixture = Aluno(
  id: _alunoId,
  nome: 'Ana Silva',
  email: 'ana@test.com',
  status: 'ATIVO',
  objetivo: 'Hipertrofia',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('histórico 360 sheet shows paged timeline fixture', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alunoTimeline360PagedProvider(_alunoId).overrideWith(
            (ref) => Timeline360PagedNotifier(ref, _alunoId)
              ..state = AsyncValue.data(
                Timeline360PagedState(
                  events: _timelineFixture,
                  hasMore: true,
                  nextOffset: 5,
                  totalCount: 12,
                ),
              ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Aluno360TimelineFullSheet(
              aluno: _alunoFixture,
              isDark: false,
              primary: const Color(0xFF2563EB),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Histórico 360'), findsOneWidget);
    expect(find.text('12 sinais'), findsOneWidget);
    // Label de lista para CHECKIN é canônico — não o título cru do fixture.
    expect(find.text('Check-in concluído'), findsWidgets);
    expect(find.text('Treino concluído'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
