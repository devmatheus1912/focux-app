import '../../alunos/data/aluno_repository.dart';
import '../../evolucao/data/evolucao_repository.dart';
import 'aluno_today_action.dart';

/// Pendências do aluno, em ordem de prioridade. `taskId` e `taskTitlePt`
/// seguem o contrato de `POST /api/aluno/autonomia/eventos` (vira ação do personal).
enum AlunoPendenciaTipo {
  perfil('perfil-base', 'Completar perfil base', '/aluno/perfil'),
  foto('foto-dados', 'Adicionar foto', '/aluno/perfil'),
  medida('medida-recente', 'Atualizar medida quinzenal', '/aluno/perfil'),
  chat('chat-contexto', 'Responder o personal', '/chat/aluno'),
  agenda('agenda-semana', 'Conferir agenda da semana', '/agenda/aluno');

  const AlunoPendenciaTipo(this.taskId, this.taskTitlePt, this.route);

  final String taskId;
  final String taskTitlePt;
  final String route;
}

class AlunoPendencia {
  final AlunoPendenciaTipo tipo;

  /// Medida: aluno nunca registrou (texto de primeira medida).
  final bool primeiraVez;

  const AlunoPendencia(this.tipo, {this.primeiraVez = false});
}

const alunoPendenciasMax = 3;
const alunoMedidaValidadeDias = 14;

/// Todas as pendências em aberto, em ordem de prioridade. A Home mostra as
/// [alunoPendenciasMax] primeiras; uma fora do top 3 continua aberta.
List<AlunoPendencia> listAlunoPendenciasAbertas({
  required Aluno aluno,
  required List<MedidaCorporal> medidas,
  required int naoLidasDoPersonal,
  required bool agendaReviewed,
  required AlunoTodayMode todayMode,
  DateTime? now,
}) {
  final hoje = _dateOnly(now ?? DateTime.now());
  final ultimaMedida = _ultimaMedida(medidas);
  final medidaVencida =
      ultimaMedida == null ||
      hoje.difference(ultimaMedida).inDays > alunoMedidaValidadeDias;

  return [
    if (todayMode != AlunoTodayMode.profileSetup &&
        alunoProfileCompletion(aluno) < 100)
      const AlunoPendencia(AlunoPendenciaTipo.perfil),
    if (!_filled(aluno.fotoUrl)) const AlunoPendencia(AlunoPendenciaTipo.foto),
    if (medidaVencida)
      AlunoPendencia(
        AlunoPendenciaTipo.medida,
        primeiraVez: ultimaMedida == null,
      ),
    if (naoLidasDoPersonal > 0) const AlunoPendencia(AlunoPendenciaTipo.chat),
    if (!agendaReviewed) const AlunoPendencia(AlunoPendenciaTipo.agenda),
  ];
}

/// Um aviso por vez abaixo do card de foco.
enum AlunoHomeAviso { anamnese, coach, nenhum }

AlunoHomeAviso resolveAlunoHomeAviso({
  required bool anamnesePendente,
  required int coachMensagens,
}) {
  if (anamnesePendente) return AlunoHomeAviso.anamnese;
  if (coachMensagens > 0) return AlunoHomeAviso.coach;
  return AlunoHomeAviso.nenhum;
}

DateTime? _ultimaMedida(List<MedidaCorporal> medidas) {
  DateTime? ultima;
  for (final m in medidas) {
    final data = DateTime.tryParse(m.data);
    if (data == null) continue;
    final d = _dateOnly(data);
    if (ultima == null || d.isAfter(ultima)) ultima = d;
  }
  return ultima;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _filled(String? value) => value != null && value.trim().isNotEmpty;
