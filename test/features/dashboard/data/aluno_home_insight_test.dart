import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_insight.dart';

Map<String, dynamic> _ritmo() => {
  'tipo': 'RITMO_CAIU',
  'confianca': 'HIGH',
  'chave': 'insightRitmoCaiu',
  'params': {'media': 3},
  'titulo': 'Seu ritmo caiu',
  'mensagem': 'Nas 4 semanas anteriores, sua média era de 3 treinos por semana.',
};

void main() {
  test('lê o insight completo do BFF', () {
    final i = AlunoHomeInsight.tryParse(_ritmo())!;
    expect(i.tipo, AlunoInsightTipo.ritmoCaiu);
    expect(i.confianca, AlunoInsightConfianca.high);
    expect(i.chave, 'insightRitmoCaiu');
    expect(i.params, {'media': '3'});
  });

  test('mapeia todos os tipos do servidor', () {
    const wire = {
      'VOLUME_SUBINDO': AlunoInsightTipo.volumeSubindo,
      'RITMO_CAIU': AlunoInsightTipo.ritmoCaiu,
    };
    for (final e in wire.entries) {
      expect(
        AlunoHomeInsight.tryParse(_ritmo()..['tipo'] = e.key)?.tipo,
        e.value,
      );
    }
  });

  test('payload ausente, desconhecido ou malformado vira null', () {
    expect(AlunoHomeInsight.tryParse(null), isNull);
    expect(AlunoHomeInsight.tryParse('RITMO_CAIU'), isNull);
    expect(AlunoHomeInsight.tryParse(_ritmo()..['tipo'] = 'PR'), isNull);
    expect(AlunoHomeInsight.tryParse(_ritmo()..['confianca'] = 'ALTA'), isNull);
    expect(AlunoHomeInsight.tryParse(_ritmo()..remove('titulo')), isNull);
    expect(AlunoHomeInsight.tryParse(_ritmo()..['mensagem'] = 3), isNull);
  });

  test('campos opcionais malformados não derrubam o insight', () {
    final i = AlunoHomeInsight.tryParse(
      _ritmo()
        ..['params'] = 'x'
        ..['chave'] = null,
    )!;
    expect(i.params, isEmpty);
    expect(i.chave, '');
  });
}
