import '../data/chat_repository.dart';
import 'chat_remetente.dart';
import 'chat_system_event.dart';

/// Nome do aluno no topo da conversa: o da rota, e na falta dele (notificação,
/// link) o do cadastro. "Aluno" só enquanto carrega.
String chatNomeDoAluno({String? daRota, String? carregado}) {
  final rota = daRota?.trim() ?? '';
  if (rota.isNotEmpty && rota != 'Aluno') return rota;
  final cadastro = carregado?.trim() ?? '';
  return cadastro.isNotEmpty ? cadastro : 'Aluno';
}

String _hora(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Subtítulo do personal: quando foi o último treino registrado no fio.
/// Sem treino no fio, nulo (sem subtítulo).
String? chatUltimoTreinoLabel(List<ChatMsg> msgs, DateTime agora) {
  DateTime? ultimo;
  for (final m in msgs) {
    if (!chatIsSistema(m.remetente, m.tipoMidia)) continue;
    if (formatChatSystemEvent(m.conteudo).tipo != ChatEventoTipo.treino) {
      continue;
    }
    if (ultimo == null || m.enviadoEm.isAfter(ultimo)) ultimo = m.enviadoEm;
  }
  if (ultimo == null) return null;
  final hoje = DateTime(agora.year, agora.month, agora.day);
  final dia = DateTime(ultimo.year, ultimo.month, ultimo.day);
  final dias = hoje.difference(dia).inDays;
  if (dias <= 0) return 'Treinou hoje às ${_hora(ultimo)}';
  if (dias == 1) return 'Treinou ontem';
  return 'Último treino há $dias dias';
}
