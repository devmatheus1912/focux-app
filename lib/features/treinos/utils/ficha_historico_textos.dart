import '../../../l10n/app_localizations.dart';
import '../models/ficha_historico.dart';
import 'ficha_vigencia.dart';
import 'semana_da_fila.dart';

/// "Recomeçada", "Trocada pelo modelo Hipertrofia 4 dias"…
String motivoDaFicha(S s, FichaHistorico ficha) {
  final modelo = ficha.nomeModelo;
  return switch (ficha.motivo) {
    MotivoTroca.recomecada => s.historicoMotivoRecomecada,
    MotivoTroca.modelo =>
      modelo == null ? s.historicoMotivoModeloSemNome : s.historicoMotivoModelo(modelo),
    MotivoTroca.duplicada => s.historicoMotivoDuplicada,
    MotivoTroca.copiadaDeOutro => s.historicoMotivoCopiada,
    MotivoTroca.historico => s.historicoMotivoHistorico,
  };
}

/// "12/08 a 14/10". Sem início usa "Até 14/10"; sem prazo, o dia em que saiu.
String periodoDaFicha(S s, FichaHistorico ficha) {
  final fim = dataCurta(ficha.vigenciaFim ?? ficha.encerradaEm);
  final inicio = ficha.vigenciaInicio;
  return inicio == null ? s.historicoAte(fim) : s.historicoPeriodo(dataCurta(inicio), fim);
}

/// A semana como estava, em modo leitura: sessão guardada sem treino não abre
/// nada, e a que foi excluída aparece como removida.
List<DiaDaSemana> semanaDaFichaAnterior(S s, FichaHistorico ficha) {
  final porDia = <int, List<SessaoDaSemana>>{};
  for (final item in ficha.sessoesDaSemana) {
    final dia = item.diaSemana;
    if (dia == null || dia < 1 || dia > 7) continue;
    porDia.putIfAbsent(dia, () => []).add(
      SessaoDaSemana(
        nome: item.disponivel ? item.nome : s.historicoSessaoRemovida(item.nome),
        exerciciosCount: item.exerciciosCount,
      ),
    );
  }
  return [
    for (var dia = 1; dia <= 7; dia++)
      DiaDaSemana(
        dia: dia,
        sessoes: porDia[dia] ?? const [],
        descanso: (porDia[dia] ?? const []).isEmpty,
      ),
  ];
}
