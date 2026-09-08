part of 'landing_editor_screen.dart';

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
                    const SizedBox(height: TokensStrip.s3),
                    TextFormField(
                      controller: state._prova,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: FxInputDeco.build(
                        context,
                        'Prova',
                        hint: 'CREF · anos · alunos · resultado',
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
            header: 'Oferta',
            caption: 'O plano principal da vitrine.',
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
                        'Preço (opcional)',
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
          index: 3,
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
          index: 4,
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
    final urlLabel = state._publicUrlLabel();

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        TokensStrip.s4,
        TokensStrip.s2,
        TokensStrip.s4,
        TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      children: [
        if (state._needsProof)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensStrip.s3),
            child: DecoratedBox(
              decoration: chrome.panel(radius: TokensStrip.rMd),
              child: Padding(
                padding: const EdgeInsets.all(TokensStrip.s3),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: EagleTokens.warn, size: 20),
                    const SizedBox(width: TokensStrip.s2),
                    Expanded(
                      child: Text(
                        'Prova fraca detectada. Reforce CREF, anos ou resultados na entrevista.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: chrome.mute,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        FxStaggerItem(
          index: 0,
          child: FxSettingsGroup(
            header: 'Link público',
            caption: state._publicado ? 'Landing publicada.' : 'Após publicar.',
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: TokensStrip.s3,
                ),
                title: Text(
                  urlLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                subtitle: Text(
                  state._publicado ? 'No ar' : 'Rascunho',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: chrome.mute,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Copiar link',
                      onPressed: state._copyLink,
                      icon: Icon(Icons.copy_outlined, color: primary),
                    ),
                    if (state._publicUrl() != null)
                      IconButton(
                        tooltip: 'Abrir página',
                        onPressed: state._openPublic,
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
            child: FxSettingsGroup(
              header: 'Serviços',
              children: [
                for (final item in state._servicos)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: TokensStrip.s3,
                    ),
                    title: Text(item.titulo),
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
            child: FxSettingsGroup(
              header: 'Método',
              caption: 'Gerado a partir da entrevista.',
              children: [
                for (var i = 0; i < state._metodo.length; i++)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: TokensStrip.s3,
                    ),
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
                    title: Text(state._metodo[i].titulo),
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
            child: FxSettingsGroup(
              header: 'FAQ',
              children: [
                for (final item in state._faq)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: TokensStrip.s3,
                      vertical: TokensStrip.s1,
                    ),
                    title: Text(item.pergunta),
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
            caption: 'Opcional — hero e bio.',
            children: [
              Padding(
                padding: const EdgeInsets.all(TokensStrip.s3),
                child: Row(
                  children: [
                    Expanded(
                      child: _LandingStudioImageSlot(
                        label: 'Hero',
                        url: state._heroImageUrl,
                        uploading: state._uploadingHero,
                        onTap: () => state._uploadImage(hero: true),
                      ),
                    ),
                    const SizedBox(width: TokensStrip.s3),
                    Expanded(
                      child: _LandingStudioImageSlot(
                        label: 'Bio',
                        url: state._bioImageUrl,
                        uploading: state._uploadingBio,
                        onTap: () => state._uploadImage(hero: false),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: uploading ? null : onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rMd),
        child: Ink(
          height: 120,
          decoration: chrome.panel(radius: TokensStrip.rMd),
          child: uploading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
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
                          child: Text(
                            'Trocar $label',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
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
                    Icon(Icons.add_photo_alternate_outlined, color: primary),
                    const SizedBox(height: TokensStrip.s1),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: chrome.mute,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
