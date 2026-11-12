const ofertaGatilhoValues = ['MANUAL', 'CHECKIN', 'TRILHA_CONCLUIDA'];

/// "Quando mostrar" ao aluno, sem termo técnico.
String ofertaGatilhoLabel(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'CHECKIN':
      return 'Quando ele bater um recorde';
    case 'TRILHA':
    case 'TRILHA_CONCLUIDA':
      return 'Quando ele concluir uma trilha';
    default:
      return 'Só quando eu enviar';
  }
}

/// "Enviada 3 · Aceita 1"; sem envio, "Ainda não enviada".
String ofertaResultadoLabel({required int enviadas, required int aceitas}) {
  if (enviadas <= 0) return 'Ainda não enviada';
  final env = enviadas == 1 ? 'Enviada 1' : 'Enviadas $enviadas';
  if (aceitas <= 0) return env;
  return '$env · ${aceitas == 1 ? 'Aceita 1' : 'Aceitas $aceitas'}';
}

/// Linha da oferta em Vendas: quando mostrar e o resultado.
String ofertaLinha({
  required String tipoGatilho,
  required int enviadas,
  required int aceitas,
  required bool ativo,
}) => [
  if (!ativo) 'Pausada',
  ofertaGatilhoLabel(tipoGatilho),
  ofertaResultadoLabel(enviadas: enviadas, aceitas: aceitas),
].join(' · ');

String ofertaEnviarPickerTitle() => 'Enviar para qual aluno?';

String ofertaSemAlunos() => 'Cadastre um aluno antes de enviar ofertas.';

String ofertaEnviarConfirmTitle(String nome) => 'Enviar para $nome?';

String ofertaEnviarConfirmMessage(String titulo) =>
    '"$titulo" aparece no app do aluno até ele aceitar ou recusar.';

String ofertaEnviarSuccess({required bool pushEntregue}) =>
    pushEntregue
        ? 'Oferta enviada com notificação'
        : 'Oferta enviada. O aluno vê ao abrir o app (sem notificação no celular).';
