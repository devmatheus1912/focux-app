import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/versao/app_versao.dart';

void main() {
  group('comparação de versão', () {
    test('por número, não por texto', () {
      expect(compararVersoes('1.2.10', '1.2.9'), greaterThan(0));
      expect(compararVersoes('1.2.6', '1.2.6+242'), 0);
      expect(compararVersoes('1.2', '1.2.0'), 0);
      expect(compararVersoes('1.3.0', '1.10.0'), lessThan(0));
    });
  });

  group('decidir atualização', () {
    test('abaixo da mínima bloqueia', () {
      expect(
        decidirAtualizacao(
          atual: '1.2.5',
          minima: '1.2.6',
          recomendada: '1.2.7',
        ),
        AtualizacaoNecessaria.obrigatoria,
      );
    });

    test('abaixo só da recomendada oferece', () {
      expect(
        decidirAtualizacao(
          atual: '1.2.6',
          minima: '1.2.0',
          recomendada: '1.2.7',
        ),
        AtualizacaoNecessaria.recomendada,
      );
    });

    test('igual ou acima, ou servidor sem exigência, não faz nada', () {
      expect(
        decidirAtualizacao(
          atual: '1.2.7',
          minima: '1.2.0',
          recomendada: '1.2.7',
        ),
        AtualizacaoNecessaria.nenhuma,
      );
      expect(decidirAtualizacao(atual: '1.2.5'), AtualizacaoNecessaria.nenhuma);
      expect(
        decidirAtualizacao(atual: '1.2.5', minima: 'lixo', recomendada: ''),
        AtualizacaoNecessaria.nenhuma,
      );
    });
  });

  test('cabeçalhos só saem com versão e plataforma', () {
    AppInfo.versao = null;
    expect(AppInfo.cabecalhos, isEmpty);
  });
}
