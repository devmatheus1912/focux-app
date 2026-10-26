import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno360_medida_plausivel.dart';
import 'package:focux_app/features/alunos/utils/aluno360_peso_fonte.dart';

void main() {
  group('pesoMostrado', () {
    test('a avaliação mais recente vence o cadastro', () {
      final p = pesoMostrado(historico: [70.0, 71.5, 72.0], cadastro: 60.0)!;
      expect(p.valor, 72.0);
      expect(p.origem, PesoOrigem.avaliacao);
    });

    test('sem avaliação, usa o cadastro e diz de onde veio', () {
      final p = pesoMostrado(historico: const [], cadastro: 68.5)!;
      expect(p.valor, 68.5);
      expect(p.origem, PesoOrigem.cadastro);
    });

    test('sem nada, nulo', () {
      expect(pesoMostrado(historico: const [], cadastro: null), isNull);
    });

    test('o caso do print: avaliação de 458 e cadastro vazio não some', () {
      expect(pesoMostrado(historico: [458.0], cadastro: null)!.valor, 458.0);
    });
  });

  group('serieDePeso', () {
    test('devolve as avaliações', () {
      expect(serieDePeso(historico: [70.0, 71.5], cadastro: 72.0), [70.0, 71.5]);
    });

    test('peso de cadastro sozinho é um ponto, nunca duas cópias', () {
      expect(serieDePeso(historico: const [], cadastro: 68.5), [68.5]);
    });

    test('sem dados, vazia', () {
      expect(serieDePeso(historico: const [], cadastro: null), isEmpty);
    });
  });

  group('medidaPlausivel', () {
    test('peso: 20 a 300 kg', () {
      expect(medidaPlausivel(MedidaTipo.pesoKg, 70), isTrue);
      expect(medidaPlausivel(MedidaTipo.pesoKg, 20), isTrue);
      expect(medidaPlausivel(MedidaTipo.pesoKg, 300), isTrue);
      expect(medidaPlausivel(MedidaTipo.pesoKg, 19.9), isFalse);
      expect(medidaPlausivel(MedidaTipo.pesoKg, 458), isFalse);
    });

    test('gordura: 3 a 60 %', () {
      expect(medidaPlausivel(MedidaTipo.gorduraPct, 18), isTrue);
      expect(medidaPlausivel(MedidaTipo.gorduraPct, 2.9), isFalse);
      expect(medidaPlausivel(MedidaTipo.gorduraPct, 818), isFalse);
    });

    test('altura: 0,5 a 2,5 m', () {
      expect(medidaPlausivel(MedidaTipo.alturaM, 1.68), isTrue);
      expect(medidaPlausivel(MedidaTipo.alturaM, 168), isFalse);
      expect(medidaPlausivel(MedidaTipo.alturaM, 0.4), isFalse);
    });
  });

  group('lerNumeroDaMedida', () {
    test('vírgula, ponto e unidade', () {
      expect(lerNumeroDaMedida('818,0%'), 818.0);
      expect(lerNumeroDaMedida('51.5 kg'), 51.5);
      expect(lerNumeroDaMedida('Registrar na evolução'), isNull);
      expect(lerNumeroDaMedida(null), isNull);
    });
  });

  group('medidasSuspeitas (formulário "Nova medida")', () {
    test('os números do print são apontados, já formatados', () {
      expect(
        medidasSuspeitas(peso: 458, gordura: 818),
        ['Peso 458,0 kg', 'Gordura 818,0%'],
      );
    });

    test('valores normais não geram aviso', () {
      expect(medidasSuspeitas(peso: 72.5, gordura: 18, massaMagra: 55), isEmpty);
    });

    test('campos vazios não geram aviso', () {
      expect(medidasSuspeitas(), isEmpty);
    });

    test('massa magra fora da faixa também', () {
      expect(medidasSuspeitas(massaMagra: 900), ['Massa magra 900,0 kg']);
    });
  });
}
