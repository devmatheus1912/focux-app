import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_aneis_concentricos.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/utils/evolucao_aneis.dart';
import 'package:flutter/material.dart';

double _contraste(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  final maior = x > y ? x : y;
  final menor = x > y ? y : x;
  return (maior + 0.05) / (menor + 0.05);
}

void main() {
  final hoje = DateTime(2026, 11, 2);

  test('sempre três anéis, mesmo sem dado', () {
    final l = leiturasDosAneis(const EvolucaoAneis(), doPersonal: true, hoje: hoje);
    expect(l, hasLength(3));
    expect(l.every((x) => x.vazio), isTrue);
    expect(l[0].valor, 'Sem ficha');
    expect(l[1].valor, 'Definir meta');
    expect(l[2].valor, 'Registre a primeira');
  });

  test('aluno sem meta não vê ação do personal', () {
    final l = leiturasDosAneis(const EvolucaoAneis(), doPersonal: false, hoje: hoje);
    expect(l[1].valor, 'Sem meta');
  });

  test('com tudo preenchido', () {
    final l = leiturasDosAneis(
      const EvolucaoAneis(
        treinoFeitos: 3,
        treinoPrevistos: 5,
        metaProgresso: 40,
        ultimaMedida: '2026-10-23',
      ),
      doPersonal: true,
      hoje: hoje,
    );
    expect(l[0].fracao, closeTo(0.6, 0.001));
    expect(l[1].valor, '40%');
    expect(l[2].valor, '20 dias restantes');
  });

  test('medida fora do ciclo aparece vencida', () {
    final l = leiturasDosAneis(
      const EvolucaoAneis(ultimaMedida: '2026-09-01', cicloMedidasDias: 30),
      doPersonal: true,
      hoje: hoje,
    );
    expect(l[2].valor, 'Vencida');
  });

  test('cor dos anéis tem contraste em marca clara e escura', () {
    for (final fundo in const [
      Color(0xFF0B4F5C),
      Color(0xFFFFD400),
      Color(0xFFFFFFFF),
      Color(0xFF000000),
      Color(0xFFE53935),
      Color(0xFF7E57C2),
    ]) {
      for (final cor in fxCoresDeAnel(fundo)) {
        expect(_contraste(cor, fundo), greaterThanOrEqualTo(3));
      }
    }
  });
}
