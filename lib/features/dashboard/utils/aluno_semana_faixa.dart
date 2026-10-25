import '../../checkin/data/checkin_repository.dart';
import '../../checkin/utils/treino_ficha_status.dart';
import '../../treinos/models/rotina_fila.dart';
import '../../treinos/utils/semana_da_fila.dart';

enum AlunoDiaEstado { treino, descanso, concluido }

/// Um dia da faixa "Esta semana" da Hoje.
class AlunoDiaFaixa {
  const AlunoDiaFaixa({
    required this.dia,
    required this.estado,
    this.hoje = false,
    this.proximo = false,
  });

  /// 1 = segunda … 7 = domingo.
  final int dia;
  final AlunoDiaEstado estado;
  final bool hoje;

  /// Próximo dia de treino, só quando hoje não é dia de treino.
  final bool proximo;
}

/// Sete dias da semana de [hoje]. Vazia quando a ficha não tem dia de treino.
List<AlunoDiaFaixa> faixaDaSemana(
  RotinaFila rotina,
  List<ExecucaoTreino> historico,
  DateTime hoje,
) {
  final dias = semanaDaFila(rotina);
  bool temTreino(DiaDaSemana d) =>
      !d.descanso && d.sessoes.any((s) => s.nome.trim().isNotEmpty);
  if (!dias.any(temTreino)) return const [];

  final segunda = DateTime(hoje.year, hoje.month, hoje.day - (hoje.weekday - 1));
  final feitos = <DateTime>{
    for (final h in historico)
      if (normalizeTreinoStatus(h.status) == treinoStatusConcluido)
        if (_dia(h.concluidoEm) case final d?) d,
  };

  final hojeTreina = temTreino(dias[hoje.weekday - 1]);
  int? proximo;
  if (!hojeTreina) {
    for (var i = hoje.weekday; i < 7; i++) {
      if (temTreino(dias[i])) {
        proximo = i + 1;
        break;
      }
    }
  }

  return [
    for (final (i, d) in dias.indexed)
      AlunoDiaFaixa(
        dia: i + 1,
        estado: feitos.contains(DateTime(segunda.year, segunda.month, segunda.day + i))
            ? AlunoDiaEstado.concluido
            : temTreino(d)
            ? AlunoDiaEstado.treino
            : AlunoDiaEstado.descanso,
        hoje: i + 1 == hoje.weekday,
        proximo: proximo == i + 1,
      ),
  ];
}

DateTime? _dia(String? iso) {
  final t = iso?.trim() ?? '';
  final d = t.isEmpty ? null : DateTime.tryParse(t)?.toLocal();
  return d == null ? null : DateTime(d.year, d.month, d.day);
}
