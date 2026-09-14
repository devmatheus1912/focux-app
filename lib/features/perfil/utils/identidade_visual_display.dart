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

String identidadeRestaurarCoresLabel() => 'Restaurar cores padrão';

String identidadeRestaurarConfirmTitle() => 'Restaurar cores padrão?';

String identidadeRestaurarConfirmMessage() =>
    'Aplica a paleta Focux e salva a marca agora.';

String identidadeLogoConfirmTitle() => 'Trocar o logo?';

String identidadeLogoConfirmMessage() =>
    'A imagem nova substitui o logo neste rascunho. Salve depois para publicar.';

String identidadeDiscardTitle() => 'Sair sem salvar?';

String identidadeDiscardMessage() =>
    'As alterações desta tela ainda não foram publicadas.';

String identidadeDiscardConfirm() => 'Sair';

String identidadeHelpTitle() => 'Identidade visual';

String identidadeHelpSubtitle() =>
    'Marca no app do aluno e no login. Bio e redes ficam em Editar perfil.';

String identidadeHelpMarcaBody() =>
    'Logo, slogan e paleta curada. Landing e bio profissional têm telas próprias.';

String identidadeHelpSalvarBody() =>
    'Confirme antes de gravar. Restaurar cores aplica o padrão Focux na hora.';

String identidadeLogoSloganSubtitle() =>
    'Logo no chrome do app. Slogan no login white-label e no home do aluno.';
