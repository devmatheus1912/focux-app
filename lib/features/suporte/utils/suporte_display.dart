const suporteSeveridadeValues = ['BAIXA', 'MEDIA', 'ALTA', 'CRITICA'];
const suporteTituloMax = 200;
const suporteDescricaoMax = 4000;
const suporteClasseMax = 200;
const suporteChatMax = 4000;

String suporteEnviarTicketLabel() => 'Enviar ticket';

String suporteEnviarTicketConfirmTitle() => 'Abrir ticket?';

String suporteEnviarTicketConfirmMessage() =>
    'O suporte Focux recebe este chamado.';

String suporteEnviarTicketConfirmLabel() => 'Enviar';

String suporteSeveridadeLabel(String? value) {
  switch ((value ?? '').trim().toUpperCase()) {
    case 'BAIXA':
      return 'Baixa';
    case 'MEDIA':
      return 'Média';
    case 'ALTA':
      return 'Alta';
    case 'CRITICA':
      return 'Crítica';
    case '':
      return 'Média';
    default:
      return value!.trim();
  }
}
