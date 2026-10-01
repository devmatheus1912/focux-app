import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/pdf/focux_pdf_kit.dart';
import 'package:focux_app/features/anamnese/data/anamnese_repository.dart';
import 'package:focux_app/features/anamnese/utils/anamnese_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ficha de anamnese gera PDF com o kit', () async {
    final anamnese = Anamnese.fromJson({
      'id': 1,
      'alunoId': 2,
      'status': 'PREENCHIDA',
      'objetivo': 'Hipertrofia',
      'lesoes': 'Joelho direito',
      'alertas': ['Dor no peito em esforço'],
    });
    final bytes = await buildAnamnesePdf(
      AnamnesePdfSnapshot(anamnese: anamnese, alunoNome: 'Ana Souza'),
      assets: await FocuxPdfAssets.load(),
      agora: DateTime(2026, 10, 1, 9),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
