import '../data/chat_text_formatter.dart';
import 'chat_system_event.dart';

bool chatIsSistema(String? remetente, [String? tipoMidia]) {
  final r = (remetente ?? '').trim().toUpperCase();
  final tipo = (tipoMidia ?? '').trim().toUpperCase();
  return r == 'SISTEMA' || tipo == 'TREINO_RESUMO';
}

String chatRemetenteLabel({
  required String remetente,
  required bool isAlunoMode,
  String? tipoMidia,
}) {
  if (chatIsSistema(remetente, tipoMidia)) return 'Sistema';
  if (isAlunoMode) {
    return remetente == 'ALUNO' ? 'Você' : 'Personal';
  }
  return remetente == 'PERSONAL' ? 'Você' : 'Aluno';
}

String chatInboxPreview({
  required String remetente,
  required String mensagem,
  String? tipoMidia,
}) {
  if (chatIsSistema(remetente, tipoMidia)) {
    return formatChatSystemEvent(mensagem).threadLabel;
  }
  final display = formatChatTextForDisplay(mensagem);
  if (remetente.trim().toUpperCase() == 'PERSONAL') {
    return 'Você: $display';
  }
  return display;
}
