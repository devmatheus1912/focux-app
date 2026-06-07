import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focux_app/features/alunos/data/aluno_operacao_focus_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AlunoOperacaoFocusStore', () {
    test('loadExplicit returns null when never saved', () async {
      expect(await AlunoOperacaoFocusStore.loadExplicit(99), isNull);
    });

    test('save and load round-trip', () async {
      await AlunoOperacaoFocusStore.saveExplicit(99, true);
      expect(await AlunoOperacaoFocusStore.loadExplicit(99), isTrue);

      await AlunoOperacaoFocusStore.saveExplicit(99, false);
      expect(await AlunoOperacaoFocusStore.loadExplicit(99), isFalse);
    });

    test('keys are isolated per aluno', () async {
      await AlunoOperacaoFocusStore.saveExplicit(1, true);
      await AlunoOperacaoFocusStore.saveExplicit(2, false);

      expect(await AlunoOperacaoFocusStore.loadExplicit(1), isTrue);
      expect(await AlunoOperacaoFocusStore.loadExplicit(2), isFalse);
      expect(await AlunoOperacaoFocusStore.loadExplicit(3), isNull);
    });
  });
}
