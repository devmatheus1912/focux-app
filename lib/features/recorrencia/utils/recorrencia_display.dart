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
