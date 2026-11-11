import '../data/winback_repository.dart';
import '../../../core/utils/fx_utils.dart';

String winbackAlunoLabel(String? nome) {
  final value = nome?.trim();
  if (value == null || value.isEmpty) return 'Aluno';
  return value;
}

String winbackTipoLabel(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'ALUNO_INATIVO_7D':
      return '7 dias sem treino';
    case 'ALUNO_INATIVO_30D':
      return '30 dias sem treino';
    case 'ALUNO_INATIVO_60D':
      return '60 dias sem treino';
    case '':
      return 'Aviso para quem parou';
    default:
      return tipo!.trim().replaceAll('_', ' ');
  }
}

String winbackWhenLabel(String enviadoEm, {DateTime? now}) {
  final label = fxDateTimeLabelFromIso(enviadoEm, now: now);
  return label.isEmpty ? '—' : label;
}

/// `null` quando o push chegou ao provedor (ou log antigo sem status).
String? winbackEntregaFalhaLabel(String? status) => switch ((status ?? '')
    .trim()
    .toUpperCase()) {
  'SEM_TOKEN' => 'Não entregue: aluno sem notificações ativas',
  'FALHOU' => 'Não entregue: o envio falhou',
  'DESLIGADO' => 'Não entregue: push desligado no servidor',
  _ => null,
};

String winbackSubtitle({
  required String? tipo,
  required String mensagem,
  String? status,
}) {
  final tipoLabel = winbackTipoLabel(tipo);
  final falha = winbackEntregaFalhaLabel(status);
  if (falha != null) return '$tipoLabel · $falha';
  final msg = mensagem.trim();
  if (msg.isEmpty) return tipoLabel;
  return '$tipoLabel · $msg';
}

const retomadaTitulo = 'Aviso para quem parou';

const retomadaVazio =
    'Nenhum aviso enviado. Quando um aluno passar 30 dias sem treinar, o aviso sai às 10h.';

/// "Ligado · 30 e 60 dias sem treino", "Desligado", "Ligado · texto seu".
String retomadaSubtituloDaLinha(RetomadaConfig? config) {
  if (config == null) return '30 e 60 dias sem treino · Push do Focux';
  if (!config.ativo) return 'Desligado';
  return config.textoProprio
      ? 'Ligado · texto seu'
      : 'Ligado · 30 e 60 dias sem treino';
}
