import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_copilot_ia_cache_store.dart';
import 'package:focux_app/features/ia/models/ia_copilot_proxima_acao.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('save and loadIfFresh returns payload within ttl', () async {
    const payload = IaCopilotProximaAcao(
      acao: 'Contate o aluno',
      motivo: 'Sem treino',
      status: 'ABERTO',
      tipoAcao: 'CONTATO',
    );
    await AlunoCopilotIaCacheStore.save(7, payload);
    final loaded = await AlunoCopilotIaCacheStore.loadIfFresh(7);
    expect(loaded?.acao, payload.acao);
    expect(loaded?.tipoAcao, payload.tipoAcao);
  });

  test('clear removes cached payload', () async {
    await AlunoCopilotIaCacheStore.save(
      8,
      const IaCopilotProximaAcao(acao: 'x', motivo: '', status: 'ABERTO'),
    );
    await AlunoCopilotIaCacheStore.clear(8);
    expect(await AlunoCopilotIaCacheStore.loadIfFresh(8), isNull);
  });
}
