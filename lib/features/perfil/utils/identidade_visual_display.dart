bool identidadeHasWhiteLabel({
  required bool? featureWhiteLabel,
  required String plano,
}) {
  if (featureWhiteLabel != null) return featureWhiteLabel;
  final plan = plano.trim().toUpperCase();
  return plan == 'ENTERPRISE' || plan == 'ENTERPRISE_PRO';
}

String identidadeSalvarLabel({required bool isSetup}) =>
    isSetup ? 'Finalizar configuração' : 'Salvar marca';

String identidadeSalvandoLabel() => 'Salvando…';

String identidadeConfirmarLabel() => 'Confirmar';

String identidadeSalvarConfirmTitle() => 'Salvar identidade visual?';

String identidadeSalvarConfirmMessage() =>
    'Logo, cores e slogan passam a aparecer no app e no login dos alunos.';

String identidadeLandingEditorLabel() => 'Editor da landing';

String identidadeRestaurarCoresLabel() => 'Restaurar cores padrão';

String identidadeRestaurarConfirmTitle() => 'Restaurar cores padrão?';

String identidadeRestaurarConfirmMessage() =>
    'Aplica a paleta Focux e salva a marca agora.';

String identidadeLogoConfirmTitle() => 'Trocar o logo?';

String identidadeLogoConfirmMessage() =>
    'A imagem nova substitui o logo neste rascunho. Salve depois para publicar.';

String identidadeHelpTitle() => 'Identidade visual';

String identidadeHelpSubtitle() =>
    'Marca no app do aluno, no login e na landing.';

String identidadeHelpMarcaBody() =>
    'Logo, slogan e paleta curada. Só o plano com marca branca publica.';

String identidadeHelpSalvarBody() =>
    'Confirme antes de gravar. Restaurar cores aplica o padrão Focux na hora.';
