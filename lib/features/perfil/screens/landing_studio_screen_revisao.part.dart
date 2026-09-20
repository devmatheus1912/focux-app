part of 'landing_editor_screen.dart';

class _LandingStudioRevisaoBody extends StatelessWidget {
  const _LandingStudioRevisaoBody({required this.state});

  final _LandingEditorScreenState state;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.softened(primary);
    final urlLabel = state._publicUrlLabel();
    final ready = state._isProfessionalReady;
    final missing = state._publishMissing;

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
        DecoratedBox(
          decoration: chrome.panel(radius: TokensStrip.rMd, accent: soft),
          child: Padding(
            padding: const EdgeInsets.all(TokensStrip.s3),
            child: Row(
              children: [
                Icon(
                  ready ? Icons.verified_outlined : Icons.timelapse_outlined,
                  color: ready ? EagleTokens.good : soft,
                  size: 22,
                ),
                const SizedBox(width: TokensStrip.s2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LandingStudioGuidance.readinessLabel(ready: ready),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        LandingStudioGuidance.readinessCaption(ready: ready),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: chrome.mute,
                        ),
                      ),
                    ],
                  ),
                ),
                FxHelpIconButton(
                  tooltip: 'Antes de publicar',
                  size: 28,
                  onTap: () => _showLandingTip(
                    context,
                    title: LandingStudioGuidance.publishTitle,
                    body: LandingStudioGuidance.publishHelpBody(
                      missing: missing,
                      podePublicar: state._podePublicar,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (state._needsProof) ...[
          const SizedBox(height: TokensStrip.s3),
          DecoratedBox(
            decoration: chrome.panel(radius: TokensStrip.rMd),
            child: Padding(
              padding: const EdgeInsets.all(TokensStrip.s3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: EagleTokens.warn, size: 20),
                  const SizedBox(width: TokensStrip.s2),
                  Expanded(
                    child: Text(
                      LandingStudioGuidance.needsProofBanner,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: chrome.mute,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (!state._podePublicar) ...[
          const SizedBox(height: TokensStrip.s3),
          Text(
            'Publicar desabilitado pelo servidor. Toque em “Antes de publicar” para ver o que falta.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: chrome.mute,
            ),
          ),
        ],
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxStaggerItem(
          index: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FxSettingsLayout.groupPadH,
                ),
                child: Text(
                  'Link público',
                  style: FxSettingsLayout.sectionHeader(color: chrome.mute),
                ),
              ),
              const SizedBox(height: FxSettingsLayout.captionAfterHeader),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FxSettingsLayout.groupPadH,
                ),
                child: Text(
                  state._publicado
                      ? 'No ar em focuxpersonal.com'
                      : 'Após publicar · white-label (sem “| Focux”).',
                  style: FxSettingsLayout.footer(color: chrome.mute),
                ),
              ),
              const SizedBox(height: FxSettingsLayout.headerToGroup),
              FxSatelliteListTile(
                title: urlLabel,
                titleCase: false,
                subtitle: Text(
                  state._publicado ? 'No ar' : 'Rascunho',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Copiar link',
                      onPressed: state._copyLink,
                      icon: Icon(Icons.copy_outlined, color: primary),
                    ),
                    IconButton(
                      tooltip: 'Abrir página / preview',
                      onPressed: state._openPublicOrPreview,
                      icon: Icon(Icons.open_in_new, color: primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxStaggerItem(
          index: 1,
          child: FxSettingsGroup(
            header: 'Textos gerados',
            caption:
                'Para reescrever do zero, volte à entrevista e gere de novo.',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensStrip.s3,
                  TokensStrip.s3,
                  TokensStrip.s3,
                  TokensStrip.s2,
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: state._heroTitle,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 2,
                      maxLines: 6,
                      decoration: FxInputDeco.build(context, 'Título'),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    TextFormField(
                      controller: state._heroSubtitle,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 2,
                      maxLines: 5,
                      decoration: FxInputDeco.build(context, 'Subtítulo'),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    TextFormField(
                      controller: state._primaryCta,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FxInputDeco.build(context, 'CTA'),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    TextFormField(
                      controller: state._bio,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 3,
                      maxLines: 10,
                      decoration: FxInputDeco.build(context, 'Bio'),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    TextFormField(
                      controller: state._fechamento,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 2,
                      maxLines: 8,
                      decoration: FxInputDeco.build(context, 'Fechamento'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (state._servicos.isNotEmpty) ...[
          const SizedBox(height: FxSettingsLayout.groupGap),
          FxStaggerItem(
            index: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FxSettingsLayout.groupPadH,
                  ),
                  child: Text(
                    'Serviços',
                    style: FxSettingsLayout.sectionHeader(color: chrome.mute),
                  ),
                ),
                const SizedBox(height: FxSettingsLayout.headerToGroup),
                for (final item in state._servicos)
                  FxSatelliteListTile(
                    title: item.titulo,
                    titleCase: false,
                    subtitle: Text(item.descricao),
                  ),
              ],
            ),
          ),
        ],
        if (state._metodo.isNotEmpty) ...[
          const SizedBox(height: FxSettingsLayout.groupGap),
          FxStaggerItem(
            index: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FxSettingsLayout.groupPadH,
                  ),
                  child: Text(
                    'Método',
                    style: FxSettingsLayout.sectionHeader(color: chrome.mute),
                  ),
                ),
                const SizedBox(height: FxSettingsLayout.captionAfterHeader),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FxSettingsLayout.groupPadH,
                  ),
                  child: Text(
                    'Gerado a partir da entrevista.',
                    style: FxSettingsLayout.footer(color: chrome.mute),
                  ),
                ),
                const SizedBox(height: FxSettingsLayout.headerToGroup),
                for (var i = 0; i < state._metodo.length; i++)
                  FxSatelliteListTile(
                    title: state._metodo[i].titulo,
                    titleCase: false,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: BrandPalette.softened(primary)
                          .withValues(alpha: 0.18),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: BrandPalette.softened(primary),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    subtitle: Text(state._metodo[i].descricao),
                  ),
              ],
            ),
          ),
        ],
        if (state._faq.isNotEmpty) ...[
          const SizedBox(height: FxSettingsLayout.groupGap),
          FxStaggerItem(
            index: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: FxSettingsLayout.groupPadH,
                  ),
                  child: Text(
                    'FAQ',
                    style: FxSettingsLayout.sectionHeader(color: chrome.mute),
                  ),
                ),
                const SizedBox(height: FxSettingsLayout.headerToGroup),
                for (final item in state._faq)
                  FxSatelliteListTile(
                    title: item.pergunta,
                    titleCase: false,
                    isThreeLine: true,
                    subtitle: Text(item.resposta),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxStaggerItem(
          index: 5,
          child: FxSettingsGroup(
            header: 'Fotos',
            caption:
                'Use uma foto real sua na capa. Sem ela, o site usa imagem de atmosfera — nunca foto de banco de pessoas.',
            children: [
              Padding(
                padding: const EdgeInsets.all(TokensStrip.s3),
                child: Row(
                  children: [
                    Expanded(
                      child: _LandingStudioImageSlot(
                        label: 'Capa (hero)',
                        url: state._heroImageUrl,
                        uploading: state._uploadingHero,
                        onTap: () => state._uploadImage(hero: true),
                        onHelp: () => _showLandingTip(
                          context,
                          title: LandingStudioGuidance.heroTitle,
                          body: LandingStudioGuidance.heroBody,
                        ),
                      ),
                    ),
                    const SizedBox(width: TokensStrip.s3),
                    Expanded(
                      child: _LandingStudioImageSlot(
                        label: 'Bio / prova',
                        url: state._bioImageUrl,
                        uploading: state._uploadingBio,
                        onTap: () => state._uploadImage(hero: false),
                        onHelp: () => _showLandingTip(
                          context,
                          title: LandingStudioGuidance.bioPhotoTitle,
                          body: LandingStudioGuidance.bioPhotoBody,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    this.onHelp,
  });

  final String label;
  final String? url;
  final bool uploading;
  final VoidCallback onTap;
  final VoidCallback? onHelp;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final hasImage = url != null && url!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            if (onHelp != null)
              FxHelpIconButton(
                tooltip: label,
                size: 28,
                onTap: onHelp!,
              ),
          ],
        ),
        const SizedBox(height: TokensStrip.s2),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: uploading ? null : onTap,
            borderRadius: BorderRadius.circular(TokensStrip.rMd),
            child: Ink(
              height: 120,
              decoration: chrome.panel(radius: TokensStrip.rMd),
              child: uploading
                  ? const Center(
                      child: FxLoading(strokeWidth: 2),
                    )
                  : hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(TokensStrip.rMd),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(url!, fit: BoxFit.cover),
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
                                  fontSize: 13,
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
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: primary,
                        ),
                        const SizedBox(height: TokensStrip.s1),
                        Text(
                          'Enviar',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: chrome.mute),
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
