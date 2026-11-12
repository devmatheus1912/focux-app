part of 'landing_editor_screen.dart';

/// Hub do editor: o estado da página, o que falta e as seções na ordem em que
/// aparecem para o visitante. Cada seção abre a própria edição.
class _LandingStudioRevisaoBody extends StatelessWidget {
  const _LandingStudioRevisaoBody({required this.state});

  final _LandingEditorScreenState state;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final pendencias = state._pendencias;
    final capa = state._heroImageUrl?.trim() ?? '';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        TokensStrip.s4,
        TokensStrip.s2,
        TokensStrip.s4,
        96 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      children: [
        // "Sua página" (11/11): quem chegou por ela está em Interessados.
        const _QuemChegouPelaPagina(),
        Container(
          padding: const EdgeInsets.all(TokensStrip.s3),
          decoration: fxListCardDecoration(context, accent: primary),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(TokensStrip.rMd),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child:
                      capa.isEmpty
                          ? ColoredBox(
                            color: primary.withValues(alpha: 0.12),
                            child: Icon(FxIcons.site, color: primary),
                          )
                          : FxCachedNetworkImage(
                            imageUrl: capa,
                            fit: BoxFit.cover,
                            memCacheWidth: 200,
                          ),
                ),
              ),
              const SizedBox(width: TokensStrip.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state._publicado ? s.landingNoAr : s.landingRascunho,
                      style: FocuxHubTypography.cardTitle(color: chrome.ink),
                    ),
                    const SizedBox(height: 2),
                    Semantics(
                      label: state._publicUrlLabel(),
                      excludeSemantics: true,
                      child: Text(
                        state._publicUrlCurto(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Copiar link',
                onPressed: state._copyLink,
                icon: Icon(FxIcons.copiar, color: primary),
              ),
              IconButton(
                tooltip: 'Ver página',
                onPressed: state._openPublicOrPreview,
                icon: Icon(FxIcons.abrirFora, color: primary),
              ),
            ],
          ),
        ),
        if (state._codigoProvisorio) ...[
          const SizedBox(height: TokensStrip.s2),
          FxSatelliteListTile(
            title: s.landingEscolherCodigo,
            titleCase: false,
            subtitle: Text(s.landingEscolherCodigoTexto),
            onTap: () => context.push('/perfil/link-publico'),
          ),
        ],
        if (pendencias.isNotEmpty) ...[
          const SizedBox(height: FxSettingsLayout.groupGap),
          Text(
            s.landingOQueFalta,
            style: FxSettingsLayout.sectionHeader(color: chrome.mute),
          ),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          FxSettingsGroup(
            children: [
              for (final (i, p) in pendencias.indexed)
                FxSettingsTile(
                  icon: FxIcons.info,
                  label: p.texto,
                  value: '',
                  accent: EagleTokens.warn,
                  showDivider: i < pendencias.length - 1,
                  onTap: () => state._abrirSecao(context, p.secao),
                ),
            ],
          ),
        ],
        const SizedBox(height: FxSettingsLayout.groupGap),
        Text(
          s.landingSecoes,
          style: FxSettingsLayout.sectionHeader(color: chrome.mute),
        ),
        const SizedBox(height: FxSettingsLayout.headerToGroup),
        FxSettingsGroup(
          children: [
            for (final (i, secao) in LandingSecao.values.indexed)
              FxSettingsTile(
                label: landingSecaoTitulo(s, secao),
                subtitle: state._resumoDaSecao(s, secao),
                value: '',
                showDivider: i < LandingSecao.values.length - 1,
                onTap: () => state._abrirSecao(context, secao),
              ),
          ],
        ),
        const SizedBox(height: TokensStrip.s8),
      ],
    );
  }
}

class _LandingStudioImageSlot extends StatelessWidget {
  const _LandingStudioImageSlot({
    required this.label,
    required this.url,
    required this.uploading,
    required this.onTap,
  });

  final String label;
  final String? url;
  final bool uploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final hasImage = url != null && url!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: TokensStrip.s2),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: uploading ? null : onTap,
            borderRadius: BorderRadius.circular(TokensStrip.rMd),
            child: Ink(
              height: 140,
              decoration: chrome.panel(radius: TokensStrip.rMd),
              child:
                  uploading
                      ? const Center(child: FxLoading(strokeWidth: 2))
                      : hasImage
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(TokensStrip.rMd),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FxCachedNetworkImage(
                              imageUrl: url!,
                              fit: BoxFit.cover,
                              memCacheWidth: 480,
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                color: Colors.black54,
                                padding: const EdgeInsets.all(TokensStrip.s2),
                                child: const Text(
                                  'Trocar foto',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: TokensStrip.fontBodySm,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FxIcons.adicionarImagem, color: primary),
                          const SizedBox(height: TokensStrip.s1),
                          Text(
                            'Enviar',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: chrome.mute),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "4 pessoas chegaram pela página nos últimos 30 dias" → Interessados.
class _QuemChegouPelaPagina extends ConsumerWidget {
  const _QuemChegouPelaPagina();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leads = ref.watch(leadsHomeProvider).value?.leads;
    if (leads == null) return const SizedBox.shrink();
    final n = interessadosDaPagina30Dias(leads);
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
      child: FxSatelliteListTile(
        leading: Icon(
          FxIcons.pessoa,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: interessadosPaginaCartao(n),
        titleCase: false,
        onTap: () => context.push('/leads?origem=pagina'),
      ),
    );
  }
}
