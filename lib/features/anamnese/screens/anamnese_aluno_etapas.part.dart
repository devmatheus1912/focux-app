part of 'anamnese_aluno_screen.dart';

extension on _AnamneseAlunoScreenState {
  Widget _corpoEtapa(S s, Anamnese a, bool isDark) {
    final mostrarBanner =
        _etapa == AnamneseEtapa.saudeGeral && a.alunoDevePreencher;
    return ListView(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        8,
        FxSettingsLayout.pageInset,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      children: [
        Semantics(
          label: s.anamneseAlunoEtapa(_etapa.index + 1, AnamneseEtapa.values.length),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TokensStrip.s1),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: (_etapa.index + 1) / AnamneseEtapa.values.length,
              backgroundColor: ShellChrome.of(context).line,
            ),
          ),
        ),
        const SizedBox(height: TokensStrip.s3),
        if (mostrarBanner) ...[
          FxStatusBanner(
            title: anamneseAlunoCtaTitle(a),
            body: anamneseAlunoCtaBody(a),
            tone: a.isPrecisaAtestado ? FxBannerTone.warn : FxBannerTone.info,
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
        ],
        switch (_etapa) {
          AnamneseEtapa.saudeGeral => _etapaSaudeGeral(s),
          AnamneseEtapa.historico => _etapaHistorico(s, isDark),
          AnamneseEtapa.habitos => _etapaHabitos(s),
          AnamneseEtapa.objetivos => _etapaObjetivos(s),
        },
      ],
    );
  }

  Widget _etapaSaudeGeral(S s) {
    final algumSim = _parq.values.any((v) => v == true);
    return FxSettingsGroup(
      header: 'PAR-Q+',
      caption: s.anamneseAlunoParqTexto,
      children: [
        for (final q in anamneseParqPerguntas)
          KeyedSubtree(
            key: _parqKeys[q.key],
            child: AnamneseParqLinha(
              pergunta: q.label,
              resposta: _parq[q.key],
              pendente: _mostrarPendencias && _parq[q.key] == null,
              onResponder: (v) {
                setState(() => _parq[q.key] = v);
                _markDirty();
              },
            ),
          ),
        if (_parq['parqOutraRazao'] == true)
          AlunoInsetFormField(
            controller: _parqOutraDetalheCtrl,
            label: s.anamneseAlunoOutraRazao,
            hint: s.anamneseAlunoOutraRazaoDica,
            icon: FxIcons.notas,
            maxLines: 3,
            maxLength: AnamneseFieldLimits.parqOutraRazaoDetalhe,
            rotuloVisivel: true,
            showDivider: false,
          ),
        if (algumSim)
          Padding(
            padding: const EdgeInsets.only(top: TokensStrip.s2),
            child: Text(
              s.anamneseAlunoParqSim,
              style: FocuxHubTypography.bodyMuted(
                color: ShellChrome.of(context).mute,
              ),
            ),
          ),
      ],
    );
  }

  Widget _tenhoCampo(
    TextEditingController c,
    String titulo,
    IconData icon,
    int maxLength, {
    String? hint,
  }) => AnamneseCampoTenho(
    controller: c,
    titulo: titulo,
    icon: icon,
    hint: hint,
    maxLength: maxLength,
    aberto: _tenho[c],
    onAberto: (tem) => _responderTenho(c, tem),
  );

  Widget _etapaHistorico(S s, bool isDark) => FxSettingsGroup(
    header: s.anamneseAlunoHistorico,
    caption: s.anamneseAlunoHistoricoTexto,
    children: [
      _tenhoCampo(
        _historicoCtrl,
        s.anamneseAlunoCondicoes,
        FxIcons.historico,
        AnamneseFieldLimits.historicoMedico,
        hint: s.anamneseAlunoCondicoesDica,
      ),
      _tenhoCampo(
        _cirurgiasCtrl,
        s.anamneseAlunoCirurgias,
        FxIcons.hospital,
        AnamneseFieldLimits.cirurgias,
        hint: s.anamneseAlunoCirurgiasDica,
      ),
      _tenhoCampo(
        _doresCtrl,
        s.anamneseAlunoDores,
        FxIcons.triste,
        AnamneseFieldLimits.doresCronicas,
        hint: s.anamneseAlunoDoresDica,
      ),
      _tenhoCampo(
        _lesoesCtrl,
        s.anamneseAlunoLesoes,
        FxIcons.curativo,
        AnamneseFieldLimits.lesoes,
        hint: s.anamneseAlunoLesoesDica,
      ),
      _tenhoCampo(
        _medicCtrl,
        s.anamneseAlunoMedicamentos,
        FxIcons.remedio,
        AnamneseFieldLimits.medicamentos,
        hint: s.anamneseAlunoMedicamentosDica,
      ),
      _tenhoCampo(
        _alergiasCtrl,
        s.anamneseAlunoAlergias,
        FxIcons.alerta,
        AnamneseFieldLimits.alergias,
        hint: s.anamneseAlunoAlergiasDica,
      ),
      _tenhoCampo(
        _gestacaoCtrl,
        s.anamneseAlunoGestacao,
        FxIcons.gestante,
        AnamneseFieldLimits.gestacaoPosParto,
        hint: s.anamneseAlunoGestacaoDica,
      ),
      AlunoChoiceSection(
        label: s.anamneseAlunoFamiliar,
        isDark: isDark,
        showDividerAbove: true,
        child: AlunoSegmentedChoice(
          options: [
            (value: 'true', label: s.anamneseAlunoSim),
            (value: 'false', label: s.anamneseAlunoNao),
          ],
          selected: _historicoFamiliarCv?.toString(),
          isDark: isDark,
          onSelect: (v) {
            setState(() => _historicoFamiliarCv = v == 'true');
            _markDirty();
          },
        ),
      ),
      _tenhoCampo(
        _sintomasCvCtrl,
        s.anamneseAlunoSintomas,
        FxIcons.favorito,
        AnamneseFieldLimits.sintomasCv,
        hint: s.anamneseAlunoSintomasDica,
      ),
    ],
  );

  Widget _etapaHabitos(S s) => FxSettingsGroup(
    header: s.anamneseAlunoHabitos,
    caption: s.anamneseAlunoHabitosTexto,
    children: [
      FxSettingsTile(
        icon: FxIcons.sono,
        label: s.anamneseAlunoHorasSono,
        value:
            _sonoHoras == null
                ? s.anamneseAlunoSelecionar
                : anamneseSonoHorasLabel(_sonoHoras),
        picker: true,
        onTap: _abrirSono,
      ),
      AnamneseChipsCampo(
        controller: _qualidadeSonoCtrl,
        titulo: s.anamneseAlunoQualidadeSono,
        opcoes: anamneseQualidadeSonoOpcoes,
        icon: FxIcons.sono,
        maxLength: AnamneseFieldLimits.qualidadeSono,
      ),
      AnamneseChipsCampo(
        controller: _estresseCtrl,
        titulo: s.anamneseAlunoEstresse,
        opcoes: anamneseEstresseOpcoes,
        icon: FxIcons.mente,
        maxLength: AnamneseFieldLimits.nivelEstresse,
      ),
      AnamneseChipsCampo(
        controller: _tabagismoCtrl,
        titulo: s.anamneseAlunoTabagismo,
        opcoes: anamneseTabagismoOpcoes,
        comDetalhe: 'Fumo',
        icon: FxIcons.semFumo,
        maxLength: AnamneseFieldLimits.tabagismo,
      ),
      AnamneseChipsCampo(
        controller: _alcoolCtrl,
        titulo: s.anamneseAlunoAlcool,
        opcoes: anamneseAlcoolOpcoes,
        icon: FxIcons.bebida,
        maxLength: AnamneseFieldLimits.alcool,
      ),
      AlunoInsetFormField(
        controller: _obsCtrl,
        label: s.anamneseAlunoObservacoes,
        hint: s.anamneseAlunoObservacoesDica,
        icon: FxIcons.notas,
        maxLines: 3,
        maxLength: AnamneseFieldLimits.observacoes,
        rotuloVisivel: true,
        showDivider: false,
      ),
    ],
  );

  Widget _etapaObjetivos(S s) {
    final faltaObjetivo =
        _mostrarPendencias && _objetivoCtrl.text.trim().isEmpty;
    final faltaDias = _mostrarPendencias && _dispSemanal == null;
    final chrome = ShellChrome.of(context);
    final aviso = chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn;
    Widget pendencia(String texto) => Text(
      texto,
      style: FocuxHubTypography.bodyMuted(
        color: aviso,
        fontWeight: FontWeight.w600,
      ),
    );
    Widget campo(
      TextEditingController c,
      String label,
      String hint,
      IconData icon,
      int max, {
      int linhas = 3,
    }) => AlunoInsetFormField(
      controller: c,
      label: label,
      hint: hint,
      icon: icon,
      maxLines: linhas,
      maxLength: max,
      rotuloVisivel: true,
      showDivider: false,
    );
    return FxSettingsGroup(
      header: s.anamneseAlunoObjetivos,
      caption: s.anamneseAlunoObjetivosTexto,
      children: [
        AnamneseChipsCampo(
          controller: _objetivoCtrl,
          titulo: s.anamneseAlunoObjetivo,
          opcoes: anamneseObjetivoOpcoes,
          icon: FxIcons.meta,
          maxLength: AnamneseFieldLimits.objetivo,
          obrigatorio: true,
        ),
        if (faltaObjetivo) pendencia(s.anamneseAlunoFaltaObjetivo),
        FxSettingsTile(
          icon: FxIcons.calendario,
          label: s.anamneseAlunoDias,
          value:
              _dispSemanal == null
                  ? s.anamneseAlunoSelecionar
                  : anamneseDisponibilidadeLabel(_dispSemanal!),
          picker: true,
          onTap: _abrirDisponibilidade,
        ),
        if (faltaDias) pendencia(s.anamneseAlunoFaltaDias),
        campo(
          _objDetalhadoCtrl,
          s.anamneseAlunoDetalheObjetivo,
          s.anamneseAlunoDetalheObjetivoDica,
          FxIcons.alvo,
          AnamneseFieldLimits.objetivoDetalhado,
        ),
        campo(
          _prefTreinoCtrl,
          s.anamneseAlunoPreferencias,
          s.anamneseAlunoPreferenciasDica,
          FxIcons.treino,
          AnamneseFieldLimits.preferenciasTreino,
        ),
        campo(
          _restricoesCtrl,
          s.anamneseAlunoRestricoes,
          s.anamneseAlunoRestricoesDica,
          FxIcons.alimentacao,
          AnamneseFieldLimits.restricoesAlimentares,
          linhas: 2,
        ),
        campo(
          _historicoAtividadeCtrl,
          s.anamneseAlunoAtividade,
          s.anamneseAlunoAtividadeDica,
          FxIcons.diploma,
          AnamneseFieldLimits.historicoAtividade,
        ),
        campo(
          _motivoInterrupcoesCtrl,
          s.anamneseAlunoInterrupcoes,
          s.anamneseAlunoInterrupcoesDica,
          FxIcons.pausarCirculo,
          AnamneseFieldLimits.motivoInterrupcoes,
          linhas: 2,
        ),
        campo(
          _motivacaoCtrl,
          s.anamneseAlunoMotivacao,
          s.anamneseAlunoMotivacaoDica,
          FxIcons.fogo,
          AnamneseFieldLimits.motivacaoAtual,
          linhas: 2,
        ),
        campo(
          _algoMaisCtrl,
          s.anamneseAlunoAlgoMais,
          s.anamneseAlunoAlgoMaisDica,
          FxIcons.chat,
          AnamneseFieldLimits.algoMais,
        ),
      ],
    );
  }
}
