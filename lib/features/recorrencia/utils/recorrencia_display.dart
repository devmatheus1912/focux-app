import '../../../core/money/fx_money.dart';
import '../../../core/utils/fx_utils.dart';

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

String recorrenciaCountLabel(int count) {
  if (count <= 0) return 'Nenhuma assinatura';
  if (count == 1) return '1 assinatura';
  return '$count assinaturas';
}

enum RecorrenciaHubFiltro { todos, pendente, ativa, pausada, cancelada }

String recorrenciaHubFiltroLabel(RecorrenciaHubFiltro filtro) => switch (filtro) {
  RecorrenciaHubFiltro.todos => 'Todas',
  RecorrenciaHubFiltro.pendente => 'Pendentes',
  RecorrenciaHubFiltro.ativa => 'Ativas',
  RecorrenciaHubFiltro.pausada => 'Pausadas',
  RecorrenciaHubFiltro.cancelada => 'Canceladas',
};

String? recorrenciaHubFiltroStatus(RecorrenciaHubFiltro filtro) => switch (filtro) {
  RecorrenciaHubFiltro.todos => null,
  RecorrenciaHubFiltro.pendente => 'PENDENTE',
  RecorrenciaHubFiltro.ativa => 'ATIVA',
  RecorrenciaHubFiltro.pausada => 'PAUSADA',
  RecorrenciaHubFiltro.cancelada => 'CANCELADA',
};

String recorrenciaAlunoHubSubtitle() => 'Cobrança mensal';

String recorrenciaAlunoEmptySubtitle() => 'Ainda sem cobrança automática';

String recorrenciaPagamentoValue({
  required String? status,
  String? initPoint,
}) {
  if (recorrenciaTemLinkCheckout(status ?? '', initPoint)) {
    return 'Autorizar';
  }
  switch ((status ?? '').trim().toUpperCase()) {
    case 'ATIVA':
      return 'Autorizado';
    case 'PAUSADA':
      return 'Pausado';
    case 'CANCELADA':
      return 'Encerrado';
    case 'PENDENTE':
      return 'Pendente';
    default:
      return '—';
  }
}

String recorrenciaPagamentoHint({
  required String? status,
  String? initPoint,
}) {
  if (recorrenciaTemLinkCheckout(status ?? '', initPoint)) {
    return 'Abre o Mercado Pago';
  }
  switch ((status ?? '').trim().toUpperCase()) {
    case 'ATIVA':
      return 'Cobrança autorizada';
    case 'PAUSADA':
      return 'Retome quando quiser';
    case 'CANCELADA':
      return 'Ciclo encerrado';
    default:
      return 'Sem autorização ainda';
  }
}

String recorrenciaCicloValue() => 'Mensal';

String recorrenciaCicloHint() => 'Mercado Pago';

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
  final parsed = DateTime.tryParse(prox);
  if (parsed == null) return prox;
  return fxDateShort(parsed);
}

String recorrenciaProximaHint(String? proximaCobranca) {
  final prox = proximaCobranca?.trim();
  if (prox == null || prox.isEmpty) return 'Sem data da próxima cobrança';
  return 'Cobrança automática';
}
