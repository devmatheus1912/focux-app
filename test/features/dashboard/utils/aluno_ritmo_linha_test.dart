import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/aluno_destaque_exercicio.dart';
import 'package:focux_app/features/dashboard/utils/aluno_home_week.dart';
import 'package:focux_app/features/dashboard/utils/aluno_ritmo_linha.dart';
import 'package:focux_app/l10n/app_localizations.dart';

void main() {
  late S s;

  setUpAll(() async {
    s = await S.delegate.load(const Locale('pt'));
  });

  test('semana com meta vira número e frase', () {
    final linha = alunoSemanaLinha(
      s,
      const AlunoWeekSummary(
        feitos: 2,
        meta: 3,
        streakSemanas: 4,
        volumeKg: 1200,
      ),
    );

    expect(linha, isNotNull);
    expect(linha!.sobrancelha, 'Seu ritmo');
    expect(linha.titulo, '2 de 3');
    expect(linha.frase, contains('4 semanas'));
    expect(linha.frase, contains('kg'));
  });

  test('semana sem sessão não vira linha', () {
    expect(
      alunoSemanaLinha(
        s,
        const AlunoWeekSummary(
          feitos: null,
          meta: null,
          streakSemanas: 0,
          volumeKg: null,
        ),
      ),
      isNull,
    );
  });

  test('evolução com curva mostra a carga e a variação', () {
    final linha = alunoEvolucaoLinha(
      s,
      destaque: const AlunoDestaqueExercicio(
        nome: 'agachamento',
        serieSemanal: [40, 44, 48],
        inicialKg: 40,
        atualKg: 48,
        deltaPercent: 20,
        semanas: 3,
      ),
      recordesMes: 1,
      ultimaData: '2026-10-02',
    );

    expect(linha!.sobrancelha, 'Agachamento');
    expect(linha.titulo, contains('48'));
    expect(linha.frase, contains('20'));
  });
}
