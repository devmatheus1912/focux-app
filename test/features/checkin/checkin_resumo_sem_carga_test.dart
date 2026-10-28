import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/fx_tonal_button.dart';
import 'package:focux_app/features/checkin/utils/checkin_resumo.dart';
import 'package:focux_app/features/checkin/widgets/checkin_resumo_view.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(CheckinResumo resumo) => MaterialApp(
  locale: const Locale('pt'),
  supportedLocales: S.supportedLocales,
  localizationsDelegates: S.localizationsDelegates,
  home: CheckinResumoView(resumo: resumo),
);

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('avisa das séries sem peso, sem bloquear concluir', (tester) async {
    await tester.pumpWidget(
      _app(
        const CheckinResumo(
          treinoNome: 'Treino A',
          seriesFeitas: 8,
          seriesPlanejadas: 8,
          seriesSemCarga: 2,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('2 séries ficaram sem peso'), findsOneWidget);
    expect(find.text('Concluir'), findsOneWidget);
  });

  testWidgets('sem série sem peso, não mostra o aviso', (tester) async {
    await tester.pumpWidget(
      _app(
        const CheckinResumo(
          treinoNome: 'Treino A',
          seriesFeitas: 8,
          seriesPlanejadas: 8,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('sem peso'), findsNothing);
  });

  testWidgets('Concluir é botão primário e Ver detalhes é tonal, não texto', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const CheckinResumo(
          treinoNome: 'Treino A',
          seriesFeitas: 8,
          seriesPlanejadas: 8,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(FxLiquidPrimaryButton), findsOneWidget);
    expect(find.byType(FxTonalButton), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });
}
