import '../models/checkin_personal_home.dart';

const checkinComoCalculamos =
    'Hoje conta só treinos concluídos hoje, igual ao pulso da Home. Semana são os 6 dias anteriores. Pendentes são alunos ativos com treino e sem check-in concluído hoje. O catálogo pagina o recorte de 7 dias.';

class CheckinFocusAction {
  const CheckinFocusAction({required this.label, this.alunoId});

  final String label;
  final int? alunoId;
}

String checkinPrimeiroNome(String nome) {
  final trimmed = nome.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.split(RegExp(r'\s+')).first;
}

CheckinFocusAction checkinFocusAction(CheckinPersonalHomeBundle home) {
  final focus =
      home.hoje.isNotEmpty
          ? home.hoje.first
          : (home.semana.isNotEmpty ? home.semana.first : null);
  if (focus == null) {
    return const CheckinFocusAction(label: 'Ver alunos');
  }
  return CheckinFocusAction(
    label: 'Ver aluno',
    alunoId: focus.alunoId,
  );
}
