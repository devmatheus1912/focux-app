import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/winback/data/winback_repository.dart';
import 'package:focux_app/features/winback/utils/winback_display.dart';

void main() {
  test('tipo do envio em português, sem "Inativo"', () {
    expect(winbackTipoLabel('ALUNO_INATIVO_7D'), '7 dias sem treino');
    expect(winbackTipoLabel('aluno_inativo_30d'), '30 dias sem treino');
    expect(winbackTipoLabel('ALUNO_INATIVO_60D'), '60 dias sem treino');
    expect(winbackTipoLabel(''), 'Aviso para quem parou');
    expect(winbackTipoLabel(null), 'Aviso para quem parou');
  });

  test('linha do envio mostra a falha de entrega', () {
    expect(winbackEntregaFalhaLabel('ENVIADO'), isNull);
    expect(winbackEntregaFalhaLabel('SEM_TOKEN'), contains('sem notificações'));
    expect(
      winbackSubtitle(tipo: 'ALUNO_INATIVO_60D', mensagem: '', status: 'FALHOU'),
      '60 dias sem treino · Não entregue: o envio falhou',
    );
  });

  test('subtítulo do item em Automações segue a configuração', () {
    const padrao = RetomadaConfig(ativo: true, padrao30: 'a', padrao60: 'b');
    expect(retomadaSubtituloDaLinha(padrao), 'Ligado · 30 e 60 dias sem treino');
    expect(
      retomadaSubtituloDaLinha(
        const RetomadaConfig(ativo: false, padrao30: 'a', padrao60: 'b'),
      ),
      'Desligado',
    );
    expect(
      retomadaSubtituloDaLinha(
        const RetomadaConfig(
          ativo: true,
          padrao30: 'a',
          padrao60: 'b',
          mensagem30: 'Oi {nome}',
        ),
      ),
      'Ligado · texto seu',
    );
    final c = RetomadaConfig.fromJson({
      'ativo': true,
      'mensagem30': null,
      'padrao30': 'Faz 30 dias',
      'padrao60': 'Ainda dá tempo',
    });
    expect(c.texto30, 'Faz 30 dias');
    expect(c.textoProprio, isFalse);
  });
}
