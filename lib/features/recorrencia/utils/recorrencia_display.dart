import '../../../core/money/fx_money.dart';
import '../../../core/utils/fx_utils.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/fx_icons.dart';

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
  // Cancelada não vence mais; pausada só volta a cobrar quando retomar.
  final s = status.trim().toUpperCase();
  if (s == 'CANCELADA' || s == 'PAUSADA') return label;
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

String recorrenciaAcaoDescricao(RecorrenciaAcao acao) => switch (acao) {
  RecorrenciaAcao.pausar => 'Para de cobrar até você retomar.',
  RecorrenciaAcao.retomar => 'Volta a lançar a cobrança todo mês.',
  RecorrenciaAcao.cancelar => 'Para de lançar; o que já foi lançado continua.',
};

IconData recorrenciaAcaoIcone(RecorrenciaAcao acao) => switch (acao) {
  RecorrenciaAcao.pausar => FxIcons.pausarCirculo,
  RecorrenciaAcao.retomar => FxIcons.playCirculo,
  RecorrenciaAcao.cancelar => FxIcons.pararCirculo,
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

/// Cancelada é decisão do personal, não problema: fica apagada, sem realce.
bool recorrenciaEncerrada(String status) =>
    status.trim().toUpperCase() == 'CANCELADA';

bool recorrenciaPendente(String status) =>
    status.trim().toUpperCase() == 'PENDENTE';

bool recorrenciaTemLinkCheckout(String status, String? initPoint) {
  final link = initPoint?.trim();
  return recorrenciaPendente(status) && link != null && link.isNotEmpty;
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

/// Status no cartão do Pagamento automático do aluno.
String recorrenciaAlunoStatusLabel({required String? status, String? initPoint}) {
  if (recorrenciaTemLinkCheckout(status ?? '', initPoint)) {
    return 'Aguardando sua autorização';
  }
  return switch ((status ?? '').trim().toUpperCase()) {
    'ATIVA' => 'Ativo',
    'PAUSADA' => 'Pausado',
    'CANCELADA' => 'Cancelado',
    _ => 'Pendente',
  };
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
      return 'Pausar pagamento automático';
    case RecorrenciaAlunoStickyKind.retomar:
      return 'Retomar pagamento automático';
    case RecorrenciaAlunoStickyKind.chat:
      return 'Falar com o personal';
  }
}

String recorrenciaPausarConfirmTitle() => 'Pausar pagamento automático?';

String recorrenciaPausarConfirmMessage() =>
    'As próximas mensalidades viram cobrança manual. Seu personal recebe um aviso.';

String recorrenciaRetomarConfirmTitle() => 'Retomar pagamento automático?';

String recorrenciaRetomarConfirmMessage() =>
    'A próxima mensalidade volta a ser cobrada sozinha. Seu personal recebe um aviso.';

String recorrenciaProximaValue(String? proximaCobranca) {
  final prox = proximaCobranca?.trim();
  if (prox == null || prox.isEmpty) return '—';
  final parsed = DateTime.tryParse(prox);
  if (parsed == null) return prox;
  return fxDateShort(parsed);
}


/// Status curto do Pagamento automático na linha das Mensalidades.
String recorrenciaAlunoStatusCurto({required String? status, String? initPoint}) {
  switch ((status ?? '').trim().toUpperCase()) {
    case 'ATIVA':
      return 'Ativo';
    case 'PAUSADA':
      return 'Pausado';
    case 'CANCELADA':
      return 'Cancelado';
    case 'PENDENTE':
      return (initPoint ?? '').trim().isEmpty ? 'Pendente' : 'Autorizar';
    default:
      return '';
  }
}

/// Forma do pagamento automático; sem o campo (backend antigo), nada.
String? recorrenciaFormaLabel(String? forma) =>
    switch ((forma ?? '').trim().toUpperCase()) {
      'PIX' => 'PIX todo mês',
      'CARTAO' => 'Cartão (Mercado Pago)',
      _ => null,
    };
