import '../../../core/theme/curated_brand_palettes.dart';
import '../../../core/ux/fx_hub_freshness.dart';

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
    'Logo, cores e slogan passam a aparecer no app do personal e do aluno.';

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
    'Marca no app após o login. Bio e redes ficam em Editar perfil.';

String identidadeHelpMarcaBody() =>
    'Logo, slogan e paleta curada. O login público continua Focux; a marca entra na sessão. Landing e bio têm telas próprias.';

String identidadeHelpSalvarBody() =>
    'Confirme antes de gravar. Restaurar cores aplica o padrão Focux na hora.';

String identidadeLogoSloganSubtitle() =>
    'Logo no chrome depois do login. Slogan no home do aluno.';

String identidadeAlunoVisibilityLabel() => 'Visível no app do aluno';

String identidadePaletteSubtitle() =>
    'Acento visível no claro e no escuro — o login é sempre escuro.';

String identidadeDarkPreviewLabel() => 'Assim no modo escuro e no login';

Duration identidadeHeroAnimDuration({required bool reduceMotion}) =>
    reduceMotion ? Duration.zero : const Duration(milliseconds: 320);

bool identidadeIsDirty({
  required bool perfilLoaded,
  required String slogan,
  required String baselineSlogan,
  required String? logoUrl,
  required String? baselineLogo,
  required CuratedBrandPalette palette,
  required CuratedBrandPalette? baselinePalette,
}) {
  if (!perfilLoaded) return false;
  return slogan != baselineSlogan ||
      logoUrl != baselineLogo ||
      palette != baselinePalette;
}

String identidadeAppBarSubtitle({
  required bool hasWhiteLabel,
  required DateTime? fetchedAt,
  DateTime? now,
}) {
  return FxHubFreshness.joinCount(
    hasWhiteLabel ? 'Sua marca no app' : 'Marca no app',
    FxHubFreshness.fromFetchedAt(fetchedAt, now: now),
  );
}
