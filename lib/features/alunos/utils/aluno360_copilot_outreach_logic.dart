import '../data/aluno_repository.dart';
import '../../health/data/health_repository.dart';
import 'aluno360_copilot_text_logic.dart';
import 'aluno_display_utils.dart';

String resolveOutreachMessage(
  Aluno aluno, {
  required String acao,
  String? backendMessage,
  bool wearableRelevant = true,
}) {
  final trimmed = backendMessage?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    if (!wearableRelevant && _mensagemMencionaWearable(trimmed)) {
      return copilotMensagemPronta(
        aluno,
        contactPriorityOutreachAcao(),
        wearableRelevant: false,
      );
    }
    return sanitizeOutreachGenderTerms(trimmed, genero: aluno.genero);
  }
  return copilotMensagemPronta(
    aluno,
    acao,
    wearableRelevant: wearableRelevant,
  );
}

String contactPriorityOutreachAcao() =>
    'Mandar mensagem curta para retomar o treino.';

bool alunoTemHistoricoWearable(RecoverySnapshot? recovery) => recovery != null;

bool _mensagemMencionaWearable(String text) => copilotAcaoMencionaWearable(text);

String copilotMensagemPronta(
  Aluno aluno,
  String acao, {
  bool wearableRelevant = true,
}) {
  final primeiroNome =
      aluno.nome.trim().isEmpty
          ? 'tudo bem'
          : aluno.nome.trim().split(' ').first;
  final lower = cleanCopilotText(acao).toLowerCase();
  if (lower.contains('financeir') || lower.contains('inadimpl')) {
    return 'Oi, $primeiroNome. Preciso alinhar uma pendência rápida para manter seu acesso sem bloqueio. Me responde por aqui?';
  }
  if (lower.contains('perfil') || lower.contains('medida')) {
    return 'Oi, $primeiroNome. Quero completar alguns dados seus para ajustar melhor o plano. Me responde por aqui?';
  }
  if (lower.contains('treino') || lower.contains('carga')) {
    return 'Oi, $primeiroNome. Quero ajustar seu treino para o próximo passo com segurança. Me responde por aqui?';
  }
  if (wearableRelevant &&
      (copilotAcaoMencionaWearable(acao) || lower.contains('sincroniz'))) {
    return 'Oi, $primeiroNome. Vi que seu wearable não sincronizou. Consegue abrir o app e me dar um ok por aqui?';
  }
  if (lower.contains('inativid') ||
      lower.contains('incentiv') ||
      lower.contains('contate') ||
      lower.contains('contatar')) {
    final junto = retomarTreinoJuntoTerm(aluno.genero);
    return 'Oi, $primeiroNome. Notei sua ausência nos treinos. Quer retomar $junto? Me responde por aqui que eu ajusto o plano.';
  }
  return 'Oi, $primeiroNome. Notei que você se afastou um pouco dos treinos. Quer retomar? Me responde por aqui que eu ajusto o plano.';
}
