import '../../../core/money/fx_money.dart';

String recorrenciaAlunoLabel(String? alunoNome) {
  final nome = alunoNome?.trim();
  if (nome == null || nome.isEmpty) return 'Aluno';
  return nome;
}

String recorrenciaStatusLabel(String? status) {
  switch ((status ?? '').trim().toUpperCase()) {
    case 'PENDENTE':
      return 'Pendente';
    case 'ATIVA':
      return 'Ativa';
    case 'PAUSADA':
      return 'Pausada';
    case 'CANCELADA':
      return 'Cancelada';
    case '':
      return 'Sem status';
    default:
      return status!.trim();
  }
}

String recorrenciaSubtitle({
  required String status,
  String? proximaCobranca,
}) {
  final label = recorrenciaStatusLabel(status);
  final prox = proximaCobranca?.trim();
  if (prox == null || prox.isEmpty) return label;
  return '$label · Próx: $prox';
}

String recorrenciaValorLabel(FxMoney valor) => valor.format();

String recorrenciaFxIcon(String status) {
  switch (status.trim().toUpperCase()) {
    case 'ATIVA':
      return 'circle-check';
    case 'PAUSADA':
      return 'alert-triangle';
    case 'CANCELADA':
      return 'alert-triangle';
    default:
      return 'coin';
  }
}

bool recorrenciaDanger(String status) =>
    status.trim().toUpperCase() == 'CANCELADA';

bool recorrenciaPendente(String status) =>
    status.trim().toUpperCase() == 'PENDENTE';

bool recorrenciaTemLinkCheckout(String status, String? initPoint) {
  final link = initPoint?.trim();
  return recorrenciaPendente(status) && link != null && link.isNotEmpty;
}

String recorrenciaHubSubtitle(String? freshness) {
  const base = 'Assinaturas Mercado Pago';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

String recorrenciaAlunoHubSubtitle({
  String? proximaCobranca,
  String? freshness,
}) {
  final prox = proximaCobranca?.trim();
  final base =
      (prox == null || prox.isEmpty) ? 'Cobrança mensal' : 'Próxima: $prox';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

String recorrenciaAlunoEmptySubtitle(String? freshness) {
  const base = 'Ainda sem cobrança automática';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

enum RecorrenciaAlunoStickyKind { autorizar, pausar, retomar, chat }

RecorrenciaAlunoStickyKind recorrenciaAlunoStickyKind({
  required String? status,
  String? initPoint,
}) {
  if (recorrenciaTemLinkCheckout(status ?? '', initPoint)) {
    return RecorrenciaAlunoStickyKind.autorizar;
  }
  switch ((status ?? '').trim().toUpperCase()) {
    case 'ATIVA':
      return RecorrenciaAlunoStickyKind.pausar;
    case 'PAUSADA':
      return RecorrenciaAlunoStickyKind.retomar;
    default:
      return RecorrenciaAlunoStickyKind.chat;
  }
}

String recorrenciaAlunoStickyLabel(RecorrenciaAlunoStickyKind kind) {
  switch (kind) {
    case RecorrenciaAlunoStickyKind.autorizar:
      return 'Autorizar pagamento';
    case RecorrenciaAlunoStickyKind.pausar:
      return 'Pausar cobrança';
    case RecorrenciaAlunoStickyKind.retomar:
      return 'Retomar cobrança';
    case RecorrenciaAlunoStickyKind.chat:
      return 'Falar com o personal';
  }
}

String recorrenciaPausarConfirmTitle() => 'Pausar a cobrança automática?';

String recorrenciaPausarConfirmMessage() =>
    'As próximas mensalidades não são cobradas até você retomar.';

String recorrenciaRetomarConfirmTitle() => 'Retomar a cobrança automática?';

String recorrenciaRetomarConfirmMessage() =>
    'O Mercado Pago volta a cobrar todo mês.';

String recorrenciaProximaValue(String? proximaCobranca) {
  final prox = proximaCobranca?.trim();
  if (prox == null || prox.isEmpty) return '—';
  return prox;
}

String recorrenciaProximaHint(String? proximaCobranca) {
  final prox = proximaCobranca?.trim();
  if (prox == null || prox.isEmpty) return 'Sem data da próxima cobrança';
  return 'Cobrança automática';
}
