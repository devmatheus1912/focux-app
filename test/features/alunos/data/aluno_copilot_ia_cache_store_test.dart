import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_copilot_ia_cache_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('save and loadIfFresh returns payload within ttl', () async {
    const payload = {'acao': 'Contate o aluno', 'tipoAcao': 'CONTATO'};
    await AlunoCopilotIaCacheStore.save(7, payload);
    final loaded = await AlunoCopilotIaCacheStore.loadIfFresh(7);
    expect(loaded, payload);
  });

  test('clear removes cached payload', () async {
    await AlunoCopilotIaCacheStore.save(8, {'acao': 'x'});
    await AlunoCopilotIaCacheStore.clear(8);
    expect(await AlunoCopilotIaCacheStore.loadIfFresh(8), isNull);
  });
}
