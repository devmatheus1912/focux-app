import '../../../l10n/app_localizations.dart';
import '../../treinos/utils/treino_atribuicao_prazo.dart';
import '../data/aluno_home_anamnese.dart';
import 'aluno_home_week.dart';
import 'aluno_pendencias.dart';
import 'aluno_today_action.dart';

typedef AlunoTodayTexto =
    ({
      String eyebrow,
      String titulo,
      String descricao,
      String? prazo,
      String cta,
      bool ctaPrimario,
    });

AlunoTodayTexto alunoTodayTexto(
  S s,
  AlunoTodayAction a, {
  DateTime? hoje,
  bool prontidaoBaixa = false,

  /// Nome curto do próximo dia de treino ("Qua"), só quando hoje é descanso.
  String? proximoDia,
}) => switch (a.mode) {
  AlunoTodayMode.workoutDone => (
    eyebrow: s.treinosProntoHoje,
    titulo: _nomeOu(a.treinoNome, s.alunoHojeFeitoTitulo),
    descricao: switch ((a.proximoEhDescanso, a.proximoTreinoNome?.trim())) {
      (true, final String proximo) when proximo.isNotEmpty =>
        s.treinosAmanhaDescanso(proximo),
      (true, _) => s.treinosAmanhaDescansoSem,
      (_, final String proximo) when proximo.isNotEmpty => s.treinosQuandoQuiser(
        proximo,
      ),
      _ => s.alunoHojeFeitoDescanso,
    },
    prazo: null,
    cta:
        (a.proximoTreinoNome?.trim().isNotEmpty ?? false)
            ? s.treinosFazerMaisUm
            : s.alunoHojeFeitoCta,
    ctaPrimario: false,
  ),
  AlunoTodayMode.workoutReady => _treinoTexto(s, a, hoje, prontidaoBaixa),
  AlunoTodayMode.descansoHoje => (
    eyebrow: s.alunoHojeDescansoEyebrow,
    titulo: s.alunoHojeDescansoTitulo,
    descricao: switch ((a.treinoNome?.trim(), proximoDia?.trim())) {
      (final String treino, final String dia)
          when treino.isNotEmpty && dia.isNotEmpty =>
        s.alunoHojeProximoTreinoDia(treino, dia),
      (final String treino, _) when treino.isNotEmpty =>
        s.alunoHojeProximoTreino(treino),
      _ => s.treinosContinuaLa,
    },
    prazo: null,
    cta: s.treinosTreinarMesmoAssim,
    ctaPrimario: false,
  ),
  AlunoTodayMode.awaitingRelease => (
    eyebrow: s.alunoHojeAguardandoEyebrow,
    titulo: _nomeOu(a.treinoNome, s.alunoHojeAguardandoTitulo),
    descricao: s.alunoHojeAguardandoDescricao,
    prazo: null,
    cta: s.alunoHojeAguardandoCta,
    ctaPrimario: true,
  ),
  AlunoTodayMode.profileSetup => (
    eyebrow: s.alunoHojePerfilEyebrow,
    titulo: s.alunoHojePerfilTitulo,
    descricao: s.alunoHojePerfilDescricao,
    prazo: null,
    cta: s.alunoHojePerfilCta,
    ctaPrimario: true,
  ),
  AlunoTodayMode.noWorkout => (
    eyebrow: s.alunoHojeSemTreinoEyebrow,
    titulo: s.alunoHojeSemTreinoTitulo,
    descricao: s.alunoHojeSemTreinoDescricao,
    prazo: null,
    cta: s.alunoHojeSemTreinoCta,
    ctaPrimario: true,
  ),
};

/// Prontidão baixa troca a contagem de exercícios pelo pedido de ir mais leve.
/// O prazo vai em linha própria para não sumir no corte com fonte grande.
AlunoTodayTexto _treinoTexto(
  S s,
  AlunoTodayAction a,
  DateTime? hoje,
  bool prontidaoBaixa,
) {
  final nome = _nomeOu(a.treinoNome, s.alunoHojeTreinoEyebrow);
  if (a.continuar) {
    final total = a.exerciseCount;
    final feitos = a.exerciciosFeitos;
    final detalhe = feitos != null && total > 0
        ? s.treinosExerciciosProgresso(feitos.clamp(0, total), total)
        : total > 0
        ? s.treinosExercicios(total)
        : s.alunoHojeTreinoDescricaoSemExercicios;
    return (
      eyebrow: s.treinosContinuar,
      titulo: nome,
      descricao: detalhe,
      prazo: null,
      cta: s.treinosContinuar,
      ctaPrimario: true,
    );
  }
  final depois = a.depoisNome?.trim();
  final comOrdem =
      !prontidaoBaixa &&
      a.ordemTotal > 1 &&
      depois != null &&
      depois.isNotEmpty;
  final base =
      prontidaoBaixa
          ? s.alunoHojeProntidaoBaixa
          : comOrdem
          ? s.treinosOrdemDepois(a.ordem, a.ordemTotal, depois)
          : a.exerciseCount > 0
          ? s.alunoHojeTreinoDescricao(a.exerciseCount)
          : s.alunoHojeTreinoDescricaoSemExercicios;
  return (
    eyebrow: a.comeback ? s.alunoHojeRetomarEyebrow : s.treinosAgora,
    titulo: a.comeback ? s.alunoHojeRetomarTitulo(nome) : nome,
    descricao: base,
    prazo: alunoPrazoTexto(s, a.prazoFim, hoje: hoje),
    cta: a.comeback ? s.alunoHojeRetomarCta : s.treinosComecar,
    ctaPrimario: true,
  );
}

/// Linha do card de foco para horário de hoje ou amanhã (`alunoHorarioNoFoco`).
String alunoHorarioFocoTexto(S s, DateTime quando, {required DateTime hoje}) =>
    alunoDiasAte(quando, hoje) == 0
        ? s.alunoHojeHorarioHoje(quando)
        : s.alunoHojeHorarioAmanha(quando);

/// Prazo soft da atribuição: orienta, nunca bloqueia o check-in.
String? alunoPrazoTexto(S s, DateTime? prazoFim, {DateTime? hoje}) {
  if (prazoFim == null) return null;
  final fim = TreinoAtribuicaoPrazo.dateOnly(prazoFim);
  final t = TreinoAtribuicaoPrazo.dateOnly(hoje ?? DateTime.now());
  if (fim.isBefore(t)) return s.alunoHojePrazoAtrasado(fim);
  if (fim == t) return s.alunoHojePrazoHoje;
  return s.alunoHojePrazoAte(fim);
}

({String titulo, String detalhe}) alunoPendenciaTexto(
  S s,
  AlunoPendencia p, {
  DateTime? hoje,
}) => switch (p.tipo) {
  AlunoPendenciaTipo.perfil => (
    titulo: s.alunoPendenciaPerfilTitulo,
    detalhe: s.alunoPendenciaPerfilDetalhe,
  ),
  AlunoPendenciaTipo.foto => (
    titulo: s.alunoPendenciaFotoTitulo,
    detalhe: s.alunoPendenciaFotoDetalhe,
  ),
  AlunoPendenciaTipo.medida when p.primeiraVez => (
    titulo: s.alunoPendenciaMedidaPrimeiraTitulo,
    detalhe: s.alunoPendenciaMedidaPrimeiraDetalhe,
  ),
  AlunoPendenciaTipo.medida => (
    titulo: s.alunoPendenciaMedidaTitulo,
    detalhe: s.alunoPendenciaMedidaDetalhe,
  ),
  AlunoPendenciaTipo.chat => (
    titulo: s.alunoPendenciaChatTitulo,
    detalhe: s.alunoPendenciaChatNovas(p.quantidade),
  ),
  AlunoPendenciaTipo.agenda => (
    titulo: s.alunoPendenciaAgendaTitulo,
    detalhe: alunoAgendaQuandoTexto(s, p.quando, hoje: hoje),
  ),
};

/// Verbo curto do botão de cada próximo passo.
String alunoPendenciaVerbo(S s, AlunoPendencia p) => switch (p.tipo) {
  AlunoPendenciaTipo.perfil => s.alunoVerboCompletar,
  AlunoPendenciaTipo.foto => s.alunoVerboAdicionar,
  AlunoPendenciaTipo.medida => s.alunoVerboRegistrar,
  AlunoPendenciaTipo.chat => s.alunoVerboResponder,
  AlunoPendenciaTipo.agenda => s.alunoVerboConferir,
};

/// "Hoje às 18:00", "Amanhã às 7:30" ou "qua., 30 de set. às 18:00".
String alunoAgendaQuandoTexto(S s, DateTime? quando, {DateTime? hoje}) {
  if (quando == null) return s.alunoFerramentaAgendaDetalhe;
  return switch (alunoDiasAte(quando, hoje ?? DateTime.now())) {
    0 => s.alunoPendenciaAgendaHoje(quando),
    1 => s.alunoPendenciaAgendaAmanha(quando),
    _ => s.alunoPendenciaAgendaDia(quando, quando),
  };
}

String alunoTreinosSemanaValor(S s, AlunoWeekSummary w) {
  final feitos = w.feitos ?? 0;
  final meta = w.meta;
  if (meta == null) return '$feitos';
  if (w.metaAtingida) return s.alunoSemanaTreinosFeitos(feitos);
  return s.alunoSemanaTreinosValor(feitos, meta);
}

String alunoVolumeTexto(S s, double kg) => s.alunoVolumeKg(kg.round());

String alunoForcaDeltaTexto(S s, double pct) {
  final umaCasa = _umaCasa(pct);
  return umaCasa < 0
      ? s.alunoForcaDeltaNegativo(umaCasa)
      : s.alunoForcaDeltaPositivo(umaCasa);
}

String alunoInicialMaiuscula(String t) {
  final limpo = t.trim();
  return limpo.isEmpty ? limpo : limpo[0].toUpperCase() + limpo.substring(1);
}

/// "2026-09-24" → "24/09"; null se a data não for ISO.
String? alunoDiaMes(String? iso) {
  final d = iso == null ? null : DateTime.tryParse(iso);
  if (d == null) return null;
  String dois(int v) => v.toString().padLeft(2, '0');
  return '${dois(d.day)}/${dois(d.month)}';
}

/// Rodapé de recordes do card Evolução; null sem recorde.
String? alunoRecordesRodape(S s, {required int recordesMes, String? ultimaData}) {
  final dia = alunoDiaMes(ultimaData);
  if (dia == null) return null;
  return recordesMes > 0
      ? s.alunoEvolucaoRecordesMes(recordesMes, dia)
      : s.alunoEvolucaoUltimoRecordeEm(dia);
}

double _umaCasa(double v) => (v * 10).round() / 10;

({String titulo, String detalhe}) alunoAnamneseAvisoTexto(
  S s,
  AlunoAnamnesePendente pendente,
) => switch (pendente) {
  AlunoAnamnesePendente.solicitada => (
    titulo: s.alunoAvisoAnamneseTitulo,
    detalhe: s.alunoAvisoAnamneseDetalhe,
  ),
  AlunoAnamnesePendente.precisaAtestado => (
    titulo: s.alunoAvisoAtestadoTitulo,
    detalhe: s.alunoAvisoAtestadoDetalhe,
  ),
};

String alunoPrimeiroNome(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+'));
  return partes.first;
}

String _nomeOu(String? nome, String fallback) {
  final limpo = nome?.trim() ?? '';
  return limpo.isEmpty ? fallback : limpo;
}
