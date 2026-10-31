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
    (v == null || v.trim().isEmpty) ? ptS.landingObrigatorio : null;

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
          ptS.landingRespondaEmLinguagemSimplesO,
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
    header: ptS.landingSuaMarca,
    caption: ptS.landingComoVoceApareceEO,
    children: [
      AlunoInsetFormField(
        controller: state._nomeMarca,
        label: ptS.landingNomeDeMarca,
        hint: ptS.landingExMarinaCosta,
        icon: Icons.badge_outlined,
        textCapitalization: TextCapitalization.words,
        rotuloFlutuante: true,
        validator: _obrigatorio,
      ),
      AlunoInsetFormField(
        controller: state._nicho,
        label: ptS.landingNicho,
        hint: ptS.landingExHipertrofiaOnlineParaIniciantes,
        icon: Icons.track_changes_outlined,
        textCapitalization: TextCapitalization.sentences,
        rotuloFlutuante: true,
        validator: _obrigatorio,
      ),
      AlunoInsetFormField(
        controller: state._promessa,
        label: ptS.landingPromessaEm1Frase,
        hint: ptS.landingGanheMassaComMetodoClaro,
        icon: Icons.auto_awesome_outlined,
        textCapitalization: TextCapitalization.sentences,
        maxLines: 2,
        rotuloFlutuante: true,
        validator: _obrigatorio,
      ),
      AlunoInsetFormField(
        controller: state._antiPersona,
        label: ptS.landingPraQuemNaoEOpcional,
        hint: ptS.landingExQuemBuscaMilagreSem,
        icon: Icons.block_outlined,
        textCapitalization: TextCapitalization.sentences,
        rotuloFlutuante: true,
        showDivider: false,
      ),
    ],
  );

  Widget _prova(BuildContext context) => FxSettingsGroup(
    header: ptS.landingPorQueConfiarEmVoce,
    caption: ptS.landingResultadoDepoimentoOuHistoricoNao,
    helpTooltip: ptS.landingProvaQueConvence,
    onHelpTap: () => _showLandingTip(
      context,
      title: LandingStudioGuidance.provaTitle,
      body: LandingStudioGuidance.provaBody,
    ),
    children: [
      AlunoInsetFormField(
        controller: state._prova,
        label: ptS.landingSuaProvaOpcional,
        hint: ptS.landingEx8Anos120Alunos,
        icon: Icons.verified_outlined,
        textCapitalization: TextCapitalization.sentences,
        maxLines: 3,
        rotuloFlutuante: true,
        showDivider: false,
      ),
    ],
  );

  Widget _oferta(BuildContext context) => FxSettingsGroup(
    header: ptS.landingSuaOferta,
    caption: ptS.landingOPlanoPrincipalDaPagina,
    helpTooltip: ptS.landingOfertaClara,
    onHelpTap: () => _showLandingTip(
      context,
      title: LandingStudioGuidance.ofertaTitle,
      body: LandingStudioGuidance.ofertaBody,
    ),
    children: [
      AlunoInsetFormField(
        controller: state._ofertaNome,
        label: ptS.landingOfertaNome,
        hint: ptS.landingAcompanhamentoCompleto,
        icon: Icons.sell_outlined,
        textCapitalization: TextCapitalization.sentences,
        rotuloFlutuante: true,
        validator: _obrigatorio,
      ),
      AlunoInsetFormField(
        controller: state._ofertaInclui,
        label: ptS.landingOQueIncluiOpcional,
        hint: ptS.landingTreinoNoAppCheckIns,
        icon: Icons.checklist_outlined,
        textCapitalization: TextCapitalization.sentences,
        maxLines: 2,
        rotuloFlutuante: true,
      ),
      AlunoInsetFormField(
        controller: state._ofertaPreco,
        label: ptS.landingPrecoOpcional,
        hint: ptS.landingExR297Mes,
        icon: Icons.payments_outlined,
        rotuloFlutuante: true,
      ),
      AlunoInsetFormField(
        controller: state._cta,
        label: ptS.landingTextoBotao,
        hint: ptS.landingQueroMinhaAvaliacao,
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
        header: ptS.landingDuvidasFrequentes,
        caption: ptS.landingAte3PerguntasQueSempre,
        children: [
          AlunoInsetFormField(
            controller: state._duvida1,
            label: ptS.landingDuvida1,
            hint: ptS.landingServeParaIniciante,
            icon: Icons.help_outline_rounded,
            textCapitalization: TextCapitalization.sentences,
            rotuloFlutuante: true,
          ),
          AlunoInsetFormField(
            controller: state._duvida2,
            label: ptS.landingDuvida2,
            hint: ptS.landingComoFuncionaOnline,
            icon: Icons.help_outline_rounded,
            textCapitalization: TextCapitalization.sentences,
            rotuloFlutuante: true,
          ),
          AlunoInsetFormField(
            controller: state._duvida3,
            label: ptS.landingDuvida3,
            hint: ptS.landingPrecisoDeAcademiaCompleta,
            icon: Icons.help_outline_rounded,
            textCapitalization: TextCapitalization.sentences,
            rotuloFlutuante: true,
            showDivider: false,
          ),
        ],
      ),
      const SizedBox(height: FxSettingsLayout.groupGap),
      FxSettingsGroup(
        header: ptS.landingContatoDaPagina,
        caption:
            ptS.landingSoNaPaginaPublicaTelefone,
        children: [
          AlunoInsetFormField(
            controller: state._whatsapp,
            label: ptS.landingWhatsappDoBotao,
            hint: '(11) 99999-9999',
            icon: Icons.chat_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [BrPhone.formatter()],
            rotuloFlutuante: true,
          ),
          AlunoInsetFormField(
            controller: state._instagram,
            label: ptS.landingInstagramDaPagina,
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
