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
  return '$label · Vence ${recorrenciaProximaValue(prox)}';
}

const recorrenciaAjudaSubtitulo =
    'Todo mês o app lança a mensalidade e avisa o aluno. Ele paga por PIX direto na sua chave.';

const recorrenciaAjudaTips = <(String, String)>[
  (
    'Como funciona',
    'Você escolhe o valor e o dia do vencimento. 5 dias antes, a mensalidade aparece para o aluno com o PIX.',
  ),
  (
    'E as mensalidades?',
    'A recorrência cria a mensalidade do mês. Se você já lançou uma manual naquele mês, ela não duplica.',
  ),
  (
    'Confirmar pagamento',
    'O dinheiro cai na sua conta, não passa pela Focux. O aluno avisa que pagou; você confere no banco e marca paga.',
  ),
  (
    'Precisa de',
    'Chave PIX cadastrada na carteira.',
  ),
];

const recorrenciaCriadaMensagem =
    'Recorrência criada. A mensalidade sai 5 dias antes de cada vencimento.';

const recorrenciaEmptyHubSubtitle =
    'Crie a primeira para lançar a mensalidade todo mês com PIX.';

const recorrenciaDiaMaximo = 28;

int recorrenciaDiaPadrao(DateTime now) =>
    now.day > recorrenciaDiaMaximo ? recorrenciaDiaMaximo : now.day;

String recorrenciaDiaLabel(int dia) => 'Todo dia $dia';

enum RecorrenciaAcao { pausar, retomar, cancelar }

List<RecorrenciaAcao> recorrenciaAcoesDisponiveis(String status) {
  switch (status.trim().toUpperCase()) {
    case 'ATIVA':
      return const [RecorrenciaAcao.pausar, RecorrenciaAcao.cancelar];
    case 'PAUSADA':
      return const [RecorrenciaAcao.retomar, RecorrenciaAcao.cancelar];
    case 'PENDENTE':
      return const [RecorrenciaAcao.cancelar];
    default:
      return const [];
  }
}

String recorrenciaAcaoLabel(RecorrenciaAcao acao) => switch (acao) {
  RecorrenciaAcao.pausar => 'Pausar',
  RecorrenciaAcao.retomar => 'Retomar',
  RecorrenciaAcao.cancelar => 'Encerrar recorrência',
};

String recorrenciaAcaoPath(RecorrenciaAcao acao) => switch (acao) {
  RecorrenciaAcao.pausar => 'pausar',
  RecorrenciaAcao.retomar => 'retomar',
  RecorrenciaAcao.cancelar => 'cancelar',
};

String recorrenciaAcaoFeito(RecorrenciaAcao acao) => switch (acao) {
  RecorrenciaAcao.pausar => 'Recorrência pausada.',
  RecorrenciaAcao.retomar => 'Recorrência retomada.',
  RecorrenciaAcao.cancelar => 'Recorrência encerrada.',
};

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
      return 'Ativa';
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
    return 'Abre o link de autorização';
  }
  switch ((status ?? '').trim().toUpperCase()) {
    case 'ATIVA':
      return 'Mensalidade todo mês';
    case 'PAUSADA':
      return 'Retome quando quiser';
    case 'CANCELADA':
      return 'Ciclo encerrado';
    default:
      return 'Aguardando o personal';
  }
}

String recorrenciaCicloValue() => 'Mensal';

String recorrenciaCicloHint() => 'PIX para o personal';

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
    'As próximas mensalidades não são lançadas até você retomar.';

String recorrenciaRetomarConfirmTitle() => 'Retomar a cobrança automática?';

String recorrenciaRetomarConfirmMessage() =>
    'A mensalidade volta a ser lançada todo mês.';

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
  return 'Próximo vencimento';
}
