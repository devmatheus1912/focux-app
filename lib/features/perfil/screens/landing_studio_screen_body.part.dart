part of 'landing_editor_screen.dart';

void _showLandingTip(
  BuildContext context, {
  required String title,
  required String body,
}) {
  LandingStudioGuidance.show(context, title: title, body: body);
}

class _LandingStudioEntrevistaBody extends StatelessWidget {
  const _LandingStudioEntrevistaBody({required this.state});

  final _LandingEditorScreenState state;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        TokensStrip.s4,
        TokensStrip.s2,
        TokensStrip.s4,
        TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      children: [
        Text(
          'Responda em linguagem simples. O Focux escreve a página premium.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: chrome.mute,
          ),
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxStaggerItem(
          index: 0,
          child: FxSettingsGroup(
            header: 'Marca',
            caption: 'Como você aparece na página pública.',
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
                      controller: state._nomeMarca,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      decoration: FxInputDeco.build(
                        context,
                        'Nome de marca',
                        hint: 'Ex.: Marina Costa',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    TextFormField(
                      controller: state._nicho,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FxInputDeco.build(
                        context,
                        'Nicho',
                        hint: 'Ex.: Hipertrofia online para iniciantes',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
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
            header: 'Promessa',
            caption: 'O que muda na vida do aluno — sem milagre.',
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
                      controller: state._promessa,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: FxInputDeco.build(
                        context,
                        'Promessa em 1 frase',
                        hint: 'Ganhe massa com método claro em 12 semanas',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    TextFormField(
                      controller: state._antiPersona,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FxInputDeco.build(
                        context,
                        'Pra quem NÃO é',
                        hint: 'Quem busca milagre sem treinar',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxStaggerItem(
          index: 2,
          child: FxSettingsGroup(
            header: 'Prova',
            caption: 'Resultado, depoimento ou histórico — não só CREF.',
            helpTooltip: 'Prova que convence',
            onHelpTap: () => _showLandingTip(
              context,
              title: LandingStudioGuidance.provaTitle,
              body: LandingStudioGuidance.provaBody,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensStrip.s3,
                  TokensStrip.s3,
                  TokensStrip.s3,
                  TokensStrip.s2,
                ),
                child: TextFormField(
                  controller: state._prova,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: FxInputDeco.build(
                    context,
                    'Prova social',
                    hint: 'CREF · anos · alunos · resultado',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxStaggerItem(
          index: 3,
          child: FxSettingsGroup(
            header: 'Oferta',
            caption: 'O plano principal da vitrine.',
            helpTooltip: 'Oferta clara',
            onHelpTap: () => _showLandingTip(
              context,
              title: LandingStudioGuidance.ofertaTitle,
              body: LandingStudioGuidance.ofertaBody,
            ),
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
                      controller: state._ofertaNome,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FxInputDeco.build(
                        context,
                        'Nome da oferta',
                        hint: 'Acompanhamento completo',
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    TextFormField(
                      controller: state._ofertaInclui,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      decoration: FxInputDeco.build(
                        context,
                        'O que inclui',
                        hint: 'Treino no app, check-ins e ajustes',
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    TextFormField(
                      controller: state._ofertaPreco,
                      textInputAction: TextInputAction.next,
                      decoration: FxInputDeco.build(
                        context,
                        'Preço',
                        hint: 'R\$ 297/mês',
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    TextFormField(
                      controller: state._cta,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FxInputDeco.build(
                        context,
                        'CTA',
                        hint: 'Quero minha avaliação',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxStaggerItem(
          index: 4,
          child: FxSettingsGroup(
            header: 'Dúvidas frequentes',
            caption: 'Até 3 perguntas que sempre te fazem.',
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
                      controller: state._duvida1,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FxInputDeco.build(
                        context,
                        'Dúvida 1',
                        hint: 'Serve para iniciante?',
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    TextFormField(
                      controller: state._duvida2,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FxInputDeco.build(
                        context,
                        'Dúvida 2',
                        hint: 'Como funciona online?',
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    TextFormField(
                      controller: state._duvida3,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FxInputDeco.build(
                        context,
                        'Dúvida 3',
                        hint: 'Preciso de academia completa?',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        FxStaggerItem(
          index: 5,
          child: FxSettingsGroup(
            header: 'Contato',
            caption: 'CTA da página e redes.',
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
                      controller: state._whatsapp,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [BrPhone.formatter()],
                      decoration: FxInputDeco.build(
                        context,
                        'WhatsApp',
                        hint: '(11) 99999-9999',
                        icon: Icons.chat_outlined,
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    TextFormField(
                      controller: state._instagram,
                      textInputAction: TextInputAction.done,
                      decoration: FxInputDeco.build(
                        context,
                        'Instagram',
                        hint: 'seu.usuario',
                        icon: Icons.camera_alt_outlined,
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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        TokensStrip.s4,
        TokensStrip.s2,
        TokensStrip.s4,
        TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
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
                      maxLines: 2,
                      decoration: FxInputDeco.build(context, 'Título'),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    TextFormField(
                      controller: state._heroSubtitle,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
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
                      maxLines: 4,
                      decoration: FxInputDeco.build(context, 'Bio'),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    TextFormField(
                      controller: state._fechamento,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 3,
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
                'Priorize a foto hero real. Sem ela o backend usa atmosfera — nunca stock humano.',
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
                                  fontSize: 12,
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
