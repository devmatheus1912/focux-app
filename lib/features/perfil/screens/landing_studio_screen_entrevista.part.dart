part of 'landing_editor_screen.dart';

void _showLandingTip(
  BuildContext context, {
  required String title,
  required String body,
}) {
  LandingStudioGuidance.show(context, title: title, body: body);
}

const _etapasEntrevista = 4;

String? _obrigatorio(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;

/// Quatro etapas, como a Anamnese: `Form` só valida o que está na tela.
class _LandingStudioEntrevistaBody extends StatelessWidget {
  const _LandingStudioEntrevistaBody({required this.state});

  final _LandingEditorScreenState state;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final etapa = state._etapa;
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
        ClipRRect(
          borderRadius: BorderRadius.circular(TokensStrip.s1),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: (etapa + 1) / _etapasEntrevista,
            color: primary,
            backgroundColor: primary.withValues(alpha: 0.12),
          ),
        ),
        const SizedBox(height: TokensStrip.s3),
        Text(
          'Responda em linguagem simples. O Focux escreve a página.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: chrome.mute,
          ),
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        KeyedSubtree(
          key: ValueKey(etapa),
          child: FxStaggerItem(index: 0, child: _etapaAtual(context, etapa)),
        ),
        const SizedBox(height: TokensStrip.s8),
      ],
    );
  }

  Widget _etapaAtual(BuildContext context, int etapa) => switch (etapa) {
    0 => _marca(),
    1 => _prova(context),
    2 => _oferta(context),
    _ => _duvidasEContato(),
  };

  Widget _marca() => FxSettingsGroup(
    header: 'Sua marca',
    caption: 'Como você aparece e o que muda na vida do aluno, sem milagre.',
    children: [
      AlunoInsetFormField(
        controller: state._nomeMarca,
        label: 'Nome de marca',
        hint: 'Ex.: Marina Costa',
        icon: Icons.badge_outlined,
        textCapitalization: TextCapitalization.words,
        rotuloFlutuante: true,
        validator: _obrigatorio,
      ),
      AlunoInsetFormField(
        controller: state._nicho,
        label: 'Nicho',
        hint: 'Ex.: Hipertrofia online para iniciantes',
        icon: Icons.track_changes_outlined,
        textCapitalization: TextCapitalization.sentences,
        rotuloFlutuante: true,
        validator: _obrigatorio,
      ),
      AlunoInsetFormField(
        controller: state._promessa,
        label: 'Promessa em 1 frase',
        hint: 'Ganhe massa com método claro em 12 semanas',
        icon: Icons.auto_awesome_outlined,
        textCapitalization: TextCapitalization.sentences,
        maxLines: 2,
        rotuloFlutuante: true,
        validator: _obrigatorio,
      ),
      AlunoInsetFormField(
        controller: state._antiPersona,
        label: 'Pra quem não é (opcional)',
        hint: 'Ex.: quem busca milagre sem treinar',
        icon: Icons.block_outlined,
        textCapitalization: TextCapitalization.sentences,
        rotuloFlutuante: true,
        showDivider: false,
      ),
    ],
  );

  Widget _prova(BuildContext context) => FxSettingsGroup(
    header: 'Por que confiar em você',
    caption: 'Resultado, depoimento ou histórico, não só CREF.',
    helpTooltip: 'Prova que convence',
    onHelpTap: () => _showLandingTip(
      context,
      title: LandingStudioGuidance.provaTitle,
      body: LandingStudioGuidance.provaBody,
    ),
    children: [
      AlunoInsetFormField(
        controller: state._prova,
        label: 'Sua prova (opcional)',
        hint: 'Ex.: 8 anos, 120 alunos, 40 kg perdidos por uma aluna',
        icon: Icons.verified_outlined,
        textCapitalization: TextCapitalization.sentences,
        maxLines: 3,
        rotuloFlutuante: true,
        showDivider: false,
      ),
    ],
  );

  Widget _oferta(BuildContext context) => FxSettingsGroup(
    header: 'Sua oferta',
    caption: 'O plano principal da página.',
    helpTooltip: 'Oferta clara',
    onHelpTap: () => _showLandingTip(
      context,
      title: LandingStudioGuidance.ofertaTitle,
      body: LandingStudioGuidance.ofertaBody,
    ),
    children: [
      AlunoInsetFormField(
        controller: state._ofertaNome,
        label: 'Nome da oferta',
        hint: 'Acompanhamento completo',
        icon: Icons.sell_outlined,
        textCapitalization: TextCapitalization.sentences,
        rotuloFlutuante: true,
        validator: _obrigatorio,
      ),
      AlunoInsetFormField(
        controller: state._ofertaInclui,
        label: 'O que inclui (opcional)',
        hint: 'Treino no app, check-ins e ajustes',
        icon: Icons.checklist_outlined,
        textCapitalization: TextCapitalization.sentences,
        maxLines: 2,
        rotuloFlutuante: true,
      ),
      AlunoInsetFormField(
        controller: state._ofertaPreco,
        label: 'Preço (opcional)',
        hint: 'Ex.: R\$ 297/mês',
        icon: Icons.payments_outlined,
        rotuloFlutuante: true,
      ),
      AlunoInsetFormField(
        controller: state._cta,
        label: 'Texto do botão',
        hint: 'Quero minha avaliação',
        icon: Icons.touch_app_outlined,
        textCapitalization: TextCapitalization.sentences,
        rotuloFlutuante: true,
        showDivider: false,
        validator: _obrigatorio,
      ),
    ],
  );

  Widget _duvidasEContato() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FxSettingsGroup(
        header: 'Dúvidas frequentes',
        caption: 'Até 3 perguntas que sempre te fazem (opcional).',
        children: [
          AlunoInsetFormField(
            controller: state._duvida1,
            label: 'Dúvida 1',
            hint: 'Serve para iniciante?',
            icon: Icons.help_outline_rounded,
            textCapitalization: TextCapitalization.sentences,
            rotuloFlutuante: true,
          ),
          AlunoInsetFormField(
            controller: state._duvida2,
            label: 'Dúvida 2',
            hint: 'Como funciona online?',
            icon: Icons.help_outline_rounded,
            textCapitalization: TextCapitalization.sentences,
            rotuloFlutuante: true,
          ),
          AlunoInsetFormField(
            controller: state._duvida3,
            label: 'Dúvida 3',
            hint: 'Preciso de academia completa?',
            icon: Icons.help_outline_rounded,
            textCapitalization: TextCapitalization.sentences,
            rotuloFlutuante: true,
            showDivider: false,
          ),
        ],
      ),
      const SizedBox(height: FxSettingsLayout.groupGap),
      FxSettingsGroup(
        header: 'Contato da página',
        caption:
            'Só na página pública. Telefone e Instagram do app ficam em Editar perfil.',
        children: [
          AlunoInsetFormField(
            controller: state._whatsapp,
            label: 'WhatsApp do botão',
            hint: '(11) 99999-9999',
            icon: Icons.chat_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [BrPhone.formatter()],
            rotuloFlutuante: true,
          ),
          AlunoInsetFormField(
            controller: state._instagram,
            label: 'Instagram da página',
            hint: 'seu.usuario',
            icon: Icons.camera_alt_outlined,
            rotuloFlutuante: true,
            showDivider: false,
          ),
        ],
      ),
    ],
  );
}
