import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_insight.dart';

Map<String, dynamic> _pr() => {
  'tipo': 'PR',
  'confianca': 'HIGH',
  'chave': 'insightPr',
  'params': {'exercicio': 'Supino', 'cargaKg': '82.5', 'dias': 2},
  'titulo': 'Novo recorde',
  'mensagem': 'Supino: 82,5 kg',
  'evidencia': 'Registrado há 2 dias',
  'acao': {'rota': '/checkin/historico', 'cta': 'Ver histórico'},
};

void main() {
  test('lê o insight completo do BFF', () {
    final i = AlunoHomeInsight.tryParse(_pr())!;
    expect(i.tipo, AlunoInsightTipo.pr);
    expect(i.confianca, AlunoInsightConfianca.high);
    expect(i.chave, 'insightPr');
    expect(i.params, {'exercicio': 'Supino', 'cargaKg': '82.5', 'dias': '2'});
    expect(i.evidencia, 'Registrado há 2 dias');
    expect(i.acao?.rota, '/checkin/historico');
  });

  test('mapeia todos os tipos do servidor', () {
    const wire = {
      'NOVO': AlunoInsightTipo.novo,
      'RECUPERACAO': AlunoInsightTipo.recuperacao,
      'PR': AlunoInsightTipo.pr,
      'RETORNO': AlunoInsightTipo.retorno,
      'META_ATINGIDA': AlunoInsightTipo.metaAtingida,
      'FORCA_SUBINDO': AlunoInsightTipo.forcaSubindo,
      'VOLUME_SUBINDO': AlunoInsightTipo.volumeSubindo,
      'CONSISTENTE': AlunoInsightTipo.consistente,
      'RITMO_CAIU': AlunoInsightTipo.ritmoCaiu,
      'DADOS_INSUFICIENTES': AlunoInsightTipo.dadosInsuficientes,
    };
    for (final e in wire.entries) {
      expect(AlunoHomeInsight.tryParse(_pr()..['tipo'] = e.key)?.tipo, e.value);
    }
  });

  test('payload ausente, desconhecido ou malformado vira null', () {
    expect(AlunoHomeInsight.tryParse(null), isNull);
    expect(AlunoHomeInsight.tryParse('PR'), isNull);
    expect(AlunoHomeInsight.tryParse(_pr()..['tipo'] = 'NOVO_TIPO_FUTURO'), isNull);
    expect(AlunoHomeInsight.tryParse(_pr()..['confianca'] = 'ALTA'), isNull);
    expect(AlunoHomeInsight.tryParse(_pr()..remove('titulo')), isNull);
    expect(AlunoHomeInsight.tryParse(_pr()..['mensagem'] = 3), isNull);
  });

  test('campos opcionais malformados não derrubam o insight', () {
    final i = AlunoHomeInsight.tryParse(
      _pr()
        ..['params'] = 'x'
        ..['evidencia'] = 7
        ..['chave'] = null
        ..['acao'] = null,
    )!;
    expect(i.params, isEmpty);
    expect(i.evidencia, isNull);
    expect(i.chave, '');
    expect(i.acao, isNull);
  });

  test('ação só aceita rota interna', () {
    for (final rota in ['https://evil.example', '//evil.example', 'saude', '']) {
      final i = AlunoHomeInsight.tryParse(
        _pr()..['acao'] = {'rota': rota, 'cta': 'Abrir'},
      )!;
      expect(i.acao, isNull, reason: rota);
    }
  });
}
