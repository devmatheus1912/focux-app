import '../../alunos/utils/satellite_screen_utils.dart';

enum FinanceiroHubView { resumo, mensalidades, metricas }

String financeiroHubViewLabel(FinanceiroHubView view) {
  switch (view) {
    case FinanceiroHubView.resumo:
      return 'Resumo';
    case FinanceiroHubView.mensalidades:
      return 'Mensalidades';
    case FinanceiroHubView.metricas:
      return 'Métricas';
  }
}

String financeiroHubSubtitle({
  required FinanceiroHubView view,
  String? freshness,
}) {
  final vista = financeiroHubViewLabel(view);
  final fresh = freshness?.trim();
  if (fresh == null || fresh.isEmpty) return vista;
  return '$vista · $fresh';
}

String financeiroAlunoContextLabel(String? nome) {
  final n = nome?.trim();
  if (n == null || n.isEmpty) return 'Mensalidades deste aluno';
  return 'Mensalidades de $n';
}

String financeiroMensalidadeMesPorExtenso(String mesReferencia) {
  final raw = mesReferencia.trim();
  final parts = raw.split('-');
  if (parts.length < 2) return raw.isEmpty ? 'Sem mês' : raw;
  final ano = int.tryParse(parts[0]);
  final mes = int.tryParse(parts[1]);
  if (ano == null || mes == null) return raw;
  return financeiroMesTitulo(mes, ano);
}

String financeiroContatoTipoLabel(String tipo) {
  switch (tipo.trim().toUpperCase()) {
    case 'WHATSAPP':
      return 'WhatsApp';
    case 'LIGACAO':
      return 'Ligação';
    case 'EMAIL':
      return 'E-mail';
    case 'PRESENCIAL':
      return 'Presencial';
    case 'OUTRO':
      return 'Outro';
    default:
      return tipo;
  }
}

String financeiroMensalidadeMesLabel(String mesReferencia) {
  final raw = mesReferencia.trim();
  if (raw.length >= 7) return raw.substring(0, 7);
  return raw.isEmpty ? 'Sem mês' : raw;
}

String financeiroMensalidadeSubtitle(String status, String mesReferencia) {
  return '${financeiroMensalidadeStatusLabel(status)} · '
      '${financeiroMensalidadeMesLabel(mesReferencia)}';
}

const _meses = [
  '',
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

String financeiroMesTitulo(int mes, int ano) {
  if (mes < 1 || mes > 12) return '$mes/$ano';
  return '${_meses[mes]} $ano';
}

class FinanceiroMesOpcao {
  const FinanceiroMesOpcao({required this.ano, required this.mes});

  final int ano;
  final int mes;

  String get key => '$ano-${mes.toString().padLeft(2, '0')}';
  String get label => financeiroMesTitulo(mes, ano);
}

/// Próximo mês, atual e 16 anteriores — o recorte que a tela de métricas opera.
List<FinanceiroMesOpcao> financeiroMesOpcoes({
  DateTime? agora,
  int quantidade = 18,
}) {
  final now = agora ?? DateTime.now();
  final out = <FinanceiroMesOpcao>[];
  for (var i = -1; i < quantidade - 1; i++) {
    final d = DateTime(now.year, now.month - i, 1);
    out.add(FinanceiroMesOpcao(ano: d.year, mes: d.month));
  }
  return out;
}
