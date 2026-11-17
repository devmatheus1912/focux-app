import '../../../l10n/app_localizations.dart';
import '../../treinos/models/metodo_exercicio.dart';
import '../models/checkin_execucao_models.dart';
import 'serie_de_agora.dart';

/// Textos da série de agora (cabeçalho do cartão, meta, instrução, botão e
/// "Depois"). Saem só da [SerieDeAgora]; nada aqui decide regra.

String _kg(double v) =>
    v == v.roundToDouble() ? '${v.toInt()} kg' : '${v.toStringAsFixed(1).replaceAll('.', ',')} kg';

/// "Válida 1 de 4 · Pirâmide ↑ · Drop-set": o cabeçalho do cartão.
String checkinCabecalhoDaSerie(SerieDeAgora sa, MetodoExercicio metodo) => [
  sa.rotulo,
  if (metodo.combinado) rotuloDoCombinado(metodo.grupoRotulo, 2),
  if (sa.progressao != Progressao.fixa) rotuloDaProgressao(sa.progressao),
  if (sa.temTecnica) rotuloCurtoDaTecnica(sa.tecnica, metodo),
].join(' · ');

/// "Meta: 15 reps · 10 kg · descanso 45 s".
String checkinMetaDaSerie(S s, SerieDeAgora sa) {
  final reps = sa.metaReps?.trim() ?? '';
  final itens = [
    if (reps.isNotEmpty) s.checkinMetaReps(reps),
    if ((sa.metaCarga ?? 0) > 0) _kg(sa.metaCarga!),
    if ((sa.descanso ?? 0) > 0) s.checkinMetaDescanso(sa.descanso!),
  ];
  return itens.isEmpty ? '' : s.checkinMeta(itens.join(' · '));
}

/// O que fazer de diferente nesta série, antes de fazer; nulo = nada.
String? checkinInstrucaoDaSerie(S s, SerieDeAgora sa, MetodoExercicio m) => switch (sa.tecnica) {
  Tecnica.pico => s.checkinInstrucaoPico(m.segundos ?? 2),
  Tecnica.excentrica => s.checkinInstrucaoExcentrica(m.segundos ?? 4),
  Tecnica.isometria => s.checkinInstrucaoIsometria(m.segundos ?? 5),
  Tecnica.dropset => s.checkinInstrucaoDropset(m.quedas ?? 2, m.reducaoPct ?? 20),
  Tecnica.restpause => s.checkinInstrucaoRestpause(m.miniSeries ?? 2, m.pausaS ?? 15),
  Tecnica.parciais => s.checkinInstrucaoParciais(m.parciais ?? 8),
  Tecnica.normal => null,
};

/// "Registrar válida 1", "Registrar aquecimento 2"; sem grupos, "Registrar série 3".
String checkinBotaoDaSerie(S s, SerieDeAgora sa) => s.checkinRegistrarDaSerie(sa.rotuloCurto);

/// "Depois: Válida 2 · 13 reps · 11 kg · Drop-set" quando ainda há série no
/// exercício; senão o próximo exercício, com "(2ª vez)" se tiver o mesmo nome.
String checkinTextoDepois(S s, ExecucaoExercicio ee, String proximoNome) {
  final seguinte = serieSeguinte(ee);
  if (seguinte != null && seguinte.comGrupos) {
    final reps = seguinte.metaReps?.trim() ?? '';
    return s.checkinDepois([
      seguinte.rotulo.split(' de ').first,
      if (reps.isNotEmpty) s.checkinMetaReps(reps),
      if ((seguinte.metaCarga ?? 0) > 0) _kg(seguinte.metaCarga!),
      if (seguinte.temTecnica) rotuloCurtoDaTecnica(seguinte.tecnica, ee.metodo),
    ].join(' · '));
  }
  final mesmoNome = proximoNome.trim().toLowerCase() == ee.exercicioNome.trim().toLowerCase();
  return s.checkinDepois(mesmoNome ? '$proximoNome (2ª vez)' : proximoNome);
}
