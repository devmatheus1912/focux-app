import '../data/aluno_repository.dart';
import 'aluno360_ferramentas_logic.dart';
import 'aluno360_medida_plausivel.dart';
import 'aluno360_resumo_agora.dart';
import 'aluno_display_utils.dart';

/// Os quatro grupos da aba Ferramentas, na ordem em que aparecem sem nada
/// pedindo atenção.
enum Aluno360FerramentasGrupo { treino, acompanhamento, relacao, dinheiro }

/// Módulos de cada grupo, na ordem fixa dentro dele.
const aluno360ModulosDoGrupo = <Aluno360FerramentasGrupo, List<Aluno360FerramentasModule>>{
  Aluno360FerramentasGrupo.treino: [
    Aluno360FerramentasModule.treinos,
    Aluno360FerramentasModule.equipamentos,
    Aluno360FerramentasModule.aderencia,
    Aluno360FerramentasModule.iaProgresso,
    Aluno360FerramentasModule.feedbackVideo,
  ],
  Aluno360FerramentasGrupo.acompanhamento: [
    Aluno360FerramentasModule.composicao,
    Aluno360FerramentasModule.planoSucesso,
    Aluno360FerramentasModule.trilhas,
    Aluno360FerramentasModule.engajamento,
    Aluno360FerramentasModule.anamnese,
  ],
  Aluno360FerramentasGrupo.relacao: [Aluno360FerramentasModule.chat],
  Aluno360FerramentasGrupo.dinheiro: [
    Aluno360FerramentasModule.mensalidades,
    Aluno360FerramentasModule.recorrencia,
  ],
};

class Aluno360FerramentasSecao {
  const Aluno360FerramentasSecao({
    required this.grupo,
    required this.modulos,
    required this.atencao,
  });

  final Aluno360FerramentasGrupo grupo;
  final List<Aluno360FerramentasModule> modulos;

  /// Algum módulo do grupo pede atenção de verdade: o grupo sobe.
  final bool atencao;
}

/// Composição fora da faixa de um adulto real (gordura 818 %, por exemplo).
bool composicaoSuspeita({String? bf, String? massaMagra}) {
  final gordura = lerNumeroDaMedida(bf);
  final massa = lerNumeroDaMedida(massaMagra);
  return (gordura != null && !medidaPlausivel(MedidaTipo.gorduraPct, gordura)) ||
      (massa != null && !medidaPlausivel(MedidaTipo.pesoKg, massa));
}

/// Este módulo mostra um selo de atenção? (inclui o "ainda não feito").
bool aluno360ModuloPedeAtencao(
  Aluno360FerramentasModule modulo, {
  required Aluno aluno,
  required String? bf,
  required String? massaMagra,
  required String? anamneseStatus,
  required List<Map<String, dynamic>>? aderenciaSemanal,
}) => switch (modulo) {
  Aluno360FerramentasModule.mensalidades =>
    aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente,
  Aluno360FerramentasModule.aderencia =>
    Aluno360FerramentasLogic.aderenciaNeedsAttention(
      aluno: aluno,
      aderenciaSemanal: aderenciaSemanal,
    ),
  Aluno360FerramentasModule.anamnese =>
    Aluno360FerramentasLogic.anamneseNeedsAttention(anamneseStatus),
  Aluno360FerramentasModule.composicao =>
    Aluno360FerramentasLogic.composicaoCorporalPending(
          bf: bf,
          massaMagra: massaMagra,
        ) ||
        composicaoSuspeita(bf: bf, massaMagra: massaMagra),
  _ => false,
};

/// O que faz o grupo subir: só o que é urgente, não o "ainda não iniciado"
/// (anamnese nunca pedida e composição sem registro ficam com o selo, no lugar).
bool _urgente(
  Aluno360FerramentasModule modulo, {
  required Aluno aluno,
  required String? bf,
  required String? massaMagra,
  required String? anamneseStatus,
  required List<Map<String, dynamic>>? aderenciaSemanal,
}) => switch (modulo) {
  Aluno360FerramentasModule.anamnese =>
    anamneseStatus == 'PREENCHIDA' || anamneseStatus == 'PRECISA_ATESTADO',
  Aluno360FerramentasModule.composicao =>
    composicaoSuspeita(bf: bf, massaMagra: massaMagra),
  _ => aluno360ModuloPedeAtencao(
    modulo,
    aluno: aluno,
    bf: bf,
    massaMagra: massaMagra,
    anamneseStatus: anamneseStatus,
    aderenciaSemanal: aderenciaSemanal,
  ),
};

/// Todos os módulos, agrupados. Grupos com algo urgente primeiro; no resto,
/// a ordem fixa. Nenhum módulo some.
List<Aluno360FerramentasSecao> secoesDeFerramentas({
  required Aluno aluno,
  required String? anamneseStatus,
  required String? bf,
  required String? massaMagra,
  required List<Map<String, dynamic>>? aderenciaSemanal,
}) {
  final secoes = [
    for (final e in aluno360ModulosDoGrupo.entries)
      Aluno360FerramentasSecao(
        grupo: e.key,
        modulos: e.value,
        atencao: e.value.any(
          (m) => _urgente(
            m,
            aluno: aluno,
            bf: bf,
            massaMagra: massaMagra,
            anamneseStatus: anamneseStatus,
            aderenciaSemanal: aderenciaSemanal,
          ),
        ),
      ),
  ];
  // Ordenação estável: urgentes primeiro, o resto na ordem de declaração.
  return [
    ...secoes.where((s) => s.atencao),
    ...secoes.where((s) => !s.atencao),
  ];
}

/// Uma linha de "Dados do aluno": o que é, o valor (ou nulo) e se está completo.
enum Aluno360DadoCampo { contato, objetivo, nascimento, altura }

class Aluno360DadoLinha {
  const Aluno360DadoLinha({required this.campo, this.valor});

  final Aluno360DadoCampo campo;

  /// Valor pronto para mostrar; nulo = falta preencher.
  final String? valor;

  bool get completo => valor != null;
}

/// Contato, objetivo, nascimento (com a idade) e altura, como o cadastro tem.
List<Aluno360DadoLinha> aluno360DadosDoAluno(Aluno aluno) {
  String? contato() {
    final t = (aluno.whatsapp ?? aluno.telefone ?? '').trim();
    return t.isEmpty ? null : t;
  }

  final idade = aluno.idade;
  final altura = aluno.altura;
  return [
    Aluno360DadoLinha(campo: Aluno360DadoCampo.contato, valor: contato()),
    Aluno360DadoLinha(
      campo: Aluno360DadoCampo.objetivo,
      valor: alunoObjectiveIsDefined(aluno.objetivo)
          ? prettyAlunoObjective(aluno.objetivo)
          : null,
    ),
    Aluno360DadoLinha(
      campo: Aluno360DadoCampo.nascimento,
      valor: idade == null ? null : '$idade anos',
    ),
    Aluno360DadoLinha(
      campo: Aluno360DadoCampo.altura,
      valor: altura == null ? null : '${(altura * 100).round()} cm',
    ),
  ];
}

/// Falta algum dado do cadastro: o grupo "Dados do aluno" vai para o topo.
bool aluno360DadosIncompletos(Aluno aluno) =>
    aluno360DadosDoAluno(aluno).any((l) => !l.completo);

/// Valor da linha de composição: o texto do módulo, ou o aviso de valor suspeito.
String aluno360ComposicaoValor({String? bf, String? massaMagra}) =>
    composicaoSuspeita(bf: bf, massaMagra: massaMagra)
        ? 'Confirme este valor'
        : Aluno360FerramentasLogic.composicaoCorporalValue(
            bf: bf,
            massaMagra: massaMagra,
          );

/// Aderência 0% sem histórico não é nota ruim: é "ainda sem dados".
String aluno360AderenciaValor(Aluno aluno) =>
    semHistoricoDeTreino(aluno) ? '—' : '${aluno.aderenciaPercent ?? 0}%';
