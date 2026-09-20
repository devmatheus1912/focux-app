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
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        TokensStrip.s4,
        TokensStrip.s2,
        TokensStrip.s4,
        100 + MediaQuery.viewInsetsOf(context).bottom,
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
                        hint: 'Ex.: quem busca milagre sem treinar',
                      ).copyWith(
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
                    hint: 'Ex.: CREF · anos · alunos · resultado',
                  ).copyWith(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        hint: 'Ex.: R\$ 297/mês',
                      ).copyWith(
                        floatingLabelBehavior: FloatingLabelBehavior.always,
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
            header: 'Contato da vitrine',
            caption:
                'Só na página pública. Telefone e Instagram do app ficam em Editar perfil.',
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
                        'WhatsApp do CTA',
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
                        'Instagram da página',
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

