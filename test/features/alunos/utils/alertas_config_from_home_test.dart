import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/alertas_config_from_home.dart';

void main() {
  test('uses cached home limiar when alunos/home already loaded', () {
    expect(
      resolveDiasSemTreinoLimiteFromHome(
        alunosHomeInitialized: true,
        cachedDiasSemTreino: 10,
      ),
      10,
    );
  });

  test('does not invent a GET — fallback when home cache is absent', () {
    expect(
      resolveDiasSemTreinoLimiteFromHome(
        alunosHomeInitialized: false,
        cachedDiasSemTreino: null,
      ),
      AlunosHomeBundle.fallbackDiasSemTreino,
    );
    expect(
      resolveDiasSemTreinoLimiteFromHome(
        alunosHomeInitialized: true,
        cachedDiasSemTreino: null,
      ),
      AlunosHomeBundle.fallbackDiasSemTreino,
    );
  });
}
