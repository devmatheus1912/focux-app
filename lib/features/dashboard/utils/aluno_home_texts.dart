import '../../../l10n/app_localizations.dart';
import '../../treinos/utils/treino_atribuicao_prazo.dart';
import '../data/aluno_home_anamnese.dart';
import 'aluno_home_week.dart';
import 'aluno_pendencias.dart';
import 'aluno_today_action.dart';

typedef AlunoTodayTexto =
    ({String eyebrow, String titulo, String descricao, String cta});

AlunoTodayTexto alunoTodayTexto(S s, AlunoTodayAction a, {DateTime? hoje}) =>
    switch (a.mode) {
      AlunoTodayMode.financialHold => (
        eyebrow: s.alunoHojeFinanceiroEyebrow,
        titulo: s.alunoHojeFinanceiroTitulo,
        descricao: s.alunoHojeFinanceiroDescricao,
        cta: s.alunoHojeFinanceiroCta,
      ),
      AlunoTodayMode.workoutReady => _treinoTexto(s, a, hoje),
      AlunoTodayMode.awaitingRelease => (
        eyebrow: s.alunoHojeAguardandoEyebrow,
        titulo: _nomeOu(a.treinoNome, s.alunoHojeAguardandoTitulo),
        descricao: s.alunoHojeAguardandoDescricao,
        cta: s.alunoHojeAguardandoCta,
      ),
      AlunoTodayMode.profileSetup => (
        eyebrow: s.alunoHojePerfilEyebrow,
        titulo: s.alunoHojePerfilTitulo,
        descricao: s.alunoHojePerfilDescricao,
        cta: s.alunoHojePerfilCta,
      ),
      AlunoTodayMode.noWorkout => (
        eyebrow: s.alunoHojeSemTreinoEyebrow,
        titulo: s.alunoHojeSemTreinoTitulo,
        descricao: s.alunoHojeSemTreinoDescricao,
        cta: s.alunoHojeSemTreinoCta,
      ),
    };

AlunoTodayTexto _treinoTexto(S s, AlunoTodayAction a, DateTime? hoje) {
  final nome = _nomeOu(a.treinoNome, s.alunoHojeTreinoEyebrow);
  final exercicios =
      a.exerciseCount > 0
          ? s.alunoHojeTreinoDescricao(a.exerciseCount)
          : s.alunoHojeTreinoDescricaoSemExercicios;
  final prazo = alunoPrazoTexto(s, a.prazoFim, hoje: hoje);
  return (
    eyebrow: a.comeback ? s.alunoHojeRetomarEyebrow : s.alunoHojeTreinoEyebrow,
    titulo: a.comeback ? s.alunoHojeRetomarTitulo(nome) : nome,
    descricao: prazo == null ? exercicios : '$exercicios · $prazo',
    cta: a.comeback ? s.alunoHojeRetomarCta : s.alunoHojeTreinoCta,
  );
}

/// Prazo soft da atribuição: orienta, nunca bloqueia o check-in.
String? alunoPrazoTexto(S s, DateTime? prazoFim, {DateTime? hoje}) {
  if (prazoFim == null) return null;
  final fim = TreinoAtribuicaoPrazo.dateOnly(prazoFim);
  final t = TreinoAtribuicaoPrazo.dateOnly(hoje ?? DateTime.now());
  if (fim.isBefore(t)) return s.alunoHojePrazoAtrasado(fim);
  if (fim == t) return s.alunoHojePrazoHoje;
  return s.alunoHojePrazoAte(fim);
}

({String titulo, String detalhe}) alunoPendenciaTexto(S s, AlunoPendencia p) =>
    switch (p.tipo) {
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
        detalhe: s.alunoPendenciaChatDetalhe,
      ),
      AlunoPendenciaTipo.agenda => (
        titulo: s.alunoPendenciaAgendaTitulo,
        detalhe: s.alunoPendenciaAgendaDetalhe,
      ),
    };

String alunoTreinosSemanaValor(S s, AlunoWeekSummary w) {
  final feitos = w.feitos ?? 0;
  final meta = w.meta;
  return meta == null ? '$feitos' : s.alunoSemanaTreinosValor(feitos, meta);
}

/// "Sua semana" lida como uma frase pelo leitor de tela.
String alunoWeekSemantics(S s, AlunoWeekSummary w) {
  final feitos = w.feitos;
  final meta = w.meta;
  final volume = w.volumeKg;
  final partes = [
    if (feitos != null)
      meta == null
          ? s.alunoSemanaFraseTreinos(feitos)
          : s.alunoSemanaFraseTreinosMeta(feitos, meta),
    s.alunoSemanaFraseSequencia(w.streakSemanas),
    if (volume != null) s.alunoSemanaFraseVolume(alunoVolumeTexto(s, volume)),
  ];
  final frase = partes.join(', ');
  return frase[0].toUpperCase() + frase.substring(1);
}

String alunoVolumeTexto(S s, double kg) => s.alunoVolumeKg(kg.round());

String alunoForcaDeltaTexto(S s, double pct) {
  final umaCasa = _umaCasa(pct);
  return umaCasa < 0
      ? s.alunoForcaDeltaNegativo(umaCasa)
      : s.alunoForcaDeltaPositivo(umaCasa);
}

String alunoRecordeTexto(S s, String exercicio, double? cargaKg) {
  if (cargaKg == null || cargaKg <= 0) return exercicio;
  return s.alunoEvolucaoRecordeValor(exercicio, _umaCasa(cargaKg));
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
