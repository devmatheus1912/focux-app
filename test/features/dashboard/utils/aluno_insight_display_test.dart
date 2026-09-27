import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_insight.dart';
import 'package:focux_app/features/dashboard/utils/aluno_insight_display.dart';
import 'package:focux_app/l10n/app_localizations.dart';

AlunoHomeInsight _insight(
  String chave,
  Map<String, String> params, {
  AlunoInsightTipo tipo = AlunoInsightTipo.ritmoCaiu,
}) => AlunoHomeInsight(
  tipo: tipo,
  confianca: AlunoInsightConfianca.high,
  chave: chave,
  params: params,
  titulo: 'Título do servidor',
  mensagem: 'Mensagem do servidor',
);

void main() {
  final pt = lookupS(const Locale('pt'));
  final en = lookupS(const Locale('en'));
  final es = lookupS(const Locale('es'));

  test('ritmo caiu mostra a média anterior, não os treinos da semana', () {
    final t = alunoInsightTexto(pt, _insight('insightRitmoCaiu', const {'media': '3.5'}));
    expect(t.titulo, 'Seu ritmo caiu');
    expect(
      t.detalhe,
      'Nas 4 semanas anteriores, sua média era de 3,5 treinos por semana.',
    );
  });

  test('ritmo caiu em en mantém ponto decimal', () {
    final t = alunoInsightTexto(en, _insight('insightRitmoCaiu', const {'media': '3.5'}));
    expect(t.titulo, 'Your rhythm dropped');
    expect(t.detalhe, 'Over the previous 4 weeks, you averaged 3.5 workouts a week.');
  });

  test('volume subindo em pt e es', () {
    final insight = _insight(
      'insightVolumeSubindo',
      const {'pct': '12'},
      tipo: AlunoInsightTipo.volumeSubindo,
    );
    expect(
      alunoInsightTexto(pt, insight).detalhe,
      '+12% vs média das 6 semanas anteriores',
    );
    expect(alunoInsightTexto(es, insight).titulo, isNot('Título do servidor'));
  });

  test('chave desconhecida ou param inválido cai no texto do servidor', () {
    final semChave = alunoInsightTexto(pt, _insight('insightFuturo', const {}));
    expect(semChave.titulo, 'Título do servidor');
    expect(semChave.detalhe, 'Mensagem do servidor');

    final semParam = alunoInsightTexto(pt, _insight('insightRitmoCaiu', const {}));
    expect(semParam.detalhe, 'Mensagem do servidor');

    final paramRuim = alunoInsightTexto(
      pt,
      _insight('insightRitmoCaiu', const {'media': 'abc'}),
    );
    expect(paramRuim.titulo, 'Título do servidor');
  });

  test('cada tipo tem ícone', () {
    for (final tipo in AlunoInsightTipo.values) {
      expect(alunoInsightIcone(tipo), isNotNull);
    }
  });
}
