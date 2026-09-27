import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/aluno_home_insight.dart';
import 'package:focux_app/features/dashboard/utils/aluno_insight_display.dart';
import 'package:focux_app/l10n/app_localizations.dart';

AlunoHomeInsight _insight(
  String chave,
  Map<String, String> params, {
  AlunoInsightTipo tipo = AlunoInsightTipo.pr,
  String? evidencia,
  AlunoInsightAcao? acao,
}) => AlunoHomeInsight(
  tipo: tipo,
  confianca: AlunoInsightConfianca.high,
  chave: chave,
  params: params,
  titulo: 'Título do servidor',
  mensagem: 'Mensagem do servidor',
  evidencia: evidencia,
  acao: acao,
);

void main() {
  final pt = lookupS(const Locale('pt'));
  final en = lookupS(const Locale('en'));

  test('PR em pt usa vírgula decimal e plural de dias', () {
    final t = alunoInsightTexto(
      pt,
      _insight('insightPr', {'exercicio': 'Supino', 'cargaKg': '82.5', 'dias': '2'}),
    );
    expect(t.titulo, 'Novo recorde');
    expect(t.detalhe, 'Supino: 82,5 kg · há 2 dias');
  });

  test('PR em en mantém ponto e diz today', () {
    final t = alunoInsightTexto(
      en,
      _insight('insightPr', {'exercicio': 'Bench', 'cargaKg': '82.5', 'dias': '0'}),
    );
    expect(t.detalhe, 'Bench: 82.5 kg · today');
  });

  test('cobre todas as chaves do servidor', () {
    final casos = <String, (Map<String, String>, String)>{
      'insightNovo': (const {}, 'Complete seu primeiro treino.'),
      'insightRecuperacao': (const {'score': '40'}, 'Prontidão 40/100. Alinhe o treino com seu personal.'),
      'insightRetorno': (const {'dias': '9'}, '9 dias sem treinar. Seu próximo treino está pronto.'),
      'insightMetaAtingida': (const {'feitos': '4', 'meta': '3'}, '4 de 3 treinos nesta semana'),
      'insightForcaSubindo': (const {'pct': '4.5', 'n': '3'}, '+4,5% vs semana passada (3 exercícios)'),
      'insightVolumeSubindo': (const {'pct': '12'}, '+12% vs média das 6 semanas anteriores'),
      'insightConsistente': (const {'feitos': '1'}, '1 treino nos últimos 7 dias'),
      'insightSequencia': (const {'semanas': '5'}, '5 semanas seguidas treinando'),
      'insightRitmoCaiu': (const {'feitos': '0'}, '0 treinos nos últimos 7 dias'),
      'insightDadosInsuficientes': (const {}, 'Continue treinando para construirmos seu histórico.'),
    };
    for (final e in casos.entries) {
      expect(alunoInsightTexto(pt, _insight(e.key, e.value.$1)).detalhe, e.value.$2, reason: e.key);
    }
  });

  test('chave desconhecida ou param faltando cai no texto do servidor', () {
    final semChave = alunoInsightTexto(pt, _insight('insightFuturo', const {}, evidencia: 'há 2 dias'));
    expect(semChave.titulo, 'Título do servidor');
    expect(semChave.detalhe, 'Mensagem do servidor · há 2 dias');

    final semParam = alunoInsightTexto(pt, _insight('insightRetorno', const {}));
    expect(semParam.detalhe, 'Mensagem do servidor');

    final paramRuim = alunoInsightTexto(pt, _insight('insightForcaSubindo', const {'pct': 'abc', 'n': '3'}));
    expect(paramRuim.titulo, 'Título do servidor');
  });

  test('força subindo em es usa vírgula decimal e título em espanhol', () {
    final es = lookupS(const Locale('es'));
    final t = alunoInsightTexto(
      es,
      _insight('insightForcaSubindo', const {'pct': '4.5', 'n': '3'}),
    );
    expect(t.titulo, 'Tu fuerza está subiendo');
    expect(t.detalhe, '+4,5% vs la semana pasada (3 ejercicios)');
  });

  test('CTA localizado pela rota; rota desconhecida usa o cta do servidor', () {
    String? cta(String rota) => alunoInsightTexto(
      en,
      _insight('insightNovo', const {}, acao: AlunoInsightAcao(rota: rota, cta: 'Abrir')),
    ).cta;
    expect(cta('/checkin/treinos'), 'See workouts');
    expect(cta('/checkin/historico'), 'See history');
    expect(cta('/saude'), 'See readiness');
    expect(cta('/outra'), 'Abrir');
    expect(alunoInsightTexto(en, _insight('insightNovo', const {})).cta, isNull);
  });
}
