import '../../subscription/models/subscription_plan.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/brand_style.dart';
import '../../../core/theme/curated_brand_palettes.dart';
import '../../../core/theme/focux_contrast.dart';
import '../../../core/ux/fx_hub_freshness.dart';

bool identidadeHasWhiteLabel({
  required bool? featureWhiteLabel,
  required String plano,
}) {
  if (featureWhiteLabel != null) return featureWhiteLabel;
  return subscriptionPlanFromApi(plano) == SubscriptionPlan.ENTERPRISE;
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
    'Logo no topo da home (sua e do aluno). Slogan na home do aluno.';

String identidadeAlunoVisibilityLabel() => 'Visível no app do aluno';

String identidadePaletteSubtitle() =>
    'Acento visível no claro e no escuro — o login é sempre escuro.';

String identidadeLightPreviewLabel() => 'Modo claro';

String identidadeDarkPreviewLabel() => 'Modo escuro · login';

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
  BrandStyle estilo = BrandStyle.classico,
  BrandStyle baselineEstilo = BrandStyle.classico,
  String? capaUrl,
  String? baselineCapa,
}) {
  if (!perfilLoaded) return false;
  return slogan != baselineSlogan ||
      logoUrl != baselineLogo ||
      palette != baselinePalette ||
      estilo != baselineEstilo ||
      capaUrl != baselineCapa;
}

String identidadeEstiloLabel(BrandStyle estilo) => switch (estilo) {
  BrandStyle.classico => 'Clássico',
  BrandStyle.cinematografico => 'Cinematográfico',
  BrandStyle.minimalista => 'Minimalista',
};

String identidadeEstiloDescricao(BrandStyle estilo) => switch (estilo) {
  BrandStyle.classico =>
    'A sua cor nos botões e destaques, como sempre foi.',
  BrandStyle.cinematografico =>
    'Card principal em tom da sua marca, fundo tingido e acento da cor secundária.',
  BrandStyle.minimalista =>
    'Só a cor primária, superfícies neutras e nenhum gradiente.',
};

String identidadeEstiloSubtitle() =>
    'O clima do app do seu aluno. Você vê o resultado na prévia.';

String identidadeImagensSubtitle() =>
    'Logo no topo e capa 16:9 na home do aluno. Slogan junto do seu nome.';

String identidadeCapaAdicionar() => 'Adicionar capa';

String identidadeCapaTrocar() => 'Trocar capa';

String identidadeCapaRemover() => 'Remover capa';

String identidadeCapaDica() =>
    'Foto horizontal (16:9). Um véu escuro suave mantém o texto legível.';

String identidadePreviaHomeClaro() => 'Home · claro';

String identidadePreviaHomeEscuro() => 'Home · escuro';

String identidadePreviaLogin() => 'Login';

/// Aviso quando a primária tem pouco contraste como destaque no escuro (ou no
/// claro). Nulo quando está tudo legível. O app ajusta o tom sozinho; o aviso
/// só deixa o personal ciente do que vai acontecer.
String? identidadeAvisoContraste(CuratedBrandPalette palette) {
  const fundoEscuro = BrandPalette.fundoEscuroReferencia;
  const fundoClaro = BrandPalette.fundoClaroReferencia;
  final escuro = palette.chromeFor(dark: true);
  final claro = palette.chromeFor(dark: false);
  if (!FocuxContrast.meetsWcagAa(escuro, fundoEscuro, largeText: true)) {
    return 'No modo escuro esta cor fica difícil de ler. O app clareia o tom automaticamente.';
  }
  if (!FocuxContrast.meetsWcagAa(claro, fundoClaro, largeText: true)) {
    return 'No modo claro esta cor fica difícil de ler. O app escurece o tom automaticamente.';
  }
  return null;
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
