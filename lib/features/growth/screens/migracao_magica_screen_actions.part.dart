part of 'migracao_magica_screen.dart';

// Models: migracao_aluno_linha.dart, migracao_importacao_resumo.dart (imported via main).

extension MigracaoMagicaScreenActions on _MigracaoMagicaScreenState {
  bool get _hasUnsavedWork =>
      _controller.text.trim().isNotEmpty ||
      _importedFileLabel != null ||
      _importedPhotoBytes != null ||
      (_alunosEncontrados != null && _alunosEncontrados!.isNotEmpty);

  PlanoFeatures? get _plano => ref.read(planoFeaturesProvider).value;

  bool _isImageFilename(String filename) {
    final lower = filename.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  bool _isPdfFilename(String filename) =>
      filename.toLowerCase().endsWith('.pdf');

  Future<bool> _verificarAcessoFoto() async {
    final plano = _plano;
    if (plano == null) {
      await ref.read(planoFeaturesProvider.notifier).refresh();
    }
    final atual = ref.read(planoFeaturesProvider).value;
    if (atual == null) return true;

    if (!atual.migracaoFoto) {
      await _mostrarPaywallFoto();
      return false;
    }

    if (!atual.migracaoFotoPermitida) {
      final limite = atual.limiteMigracaoFotoMensal ?? 0;
      if (!mounted) return false;
      FeedbackHelper.showError(
        context,
        'Limite mensal de fotos atingido ($limite). '
        '${atual.plano == SubscriptionPlan.PRO ? 'Upgrade para Enterprise (${MigracaoFotoLimits.enterprise}/mês) ou use planilha/texto.' : 'Tente no próximo mês ou use planilha/texto.'}',
      );
      return false;
    }

    return true;
  }

  Future<void> _mostrarPaywallFoto() {
    return UpgradePromptSheet.show(
      context: context,
      featureName: 'Foto na migração',
      capability: 'migracaoFoto',
      source: 'migracao_foto',
    );
  }

  Future<void> _registrarUsoFoto() async {
    final api = ref.read(apiClientProvider);
    await api.dio.post('/api/v1/migracao/foto/registrar');
    await ref.read(planoFeaturesProvider.notifier).refresh();
  }

  void _limparImportacaoVisual() {
    _importedFileLabel = null;
    _importedPhotoBytes = null;
  }

  Future<void> _finalizarProcessamento(
    MigracaoTextoResultado? resultado, {
    String successSuffix = '',
  }) async {
    var parsed = await _enriquecerComPreview(resultado?.alunos);
    if (parsed != null && _fonte == MigracaoFonte.foto) {
      parsed = MigracaoAlunoLinha.desmarcarSoNome(parsed);
    }
    if (!mounted) return;
    setState(() {
      _alunosEncontrados = parsed;
      _emptyResult = parsed == null || parsed.isEmpty;
      _ignorados = resultado?.ignorados ?? 0;
      _amostrasIgnoradas = resultado?.amostrasIgnoradas ?? const [];
      _planilha = null;
    });

    if (parsed != null && parsed.isNotEmpty && mounted) {
      FeedbackHelper.showSuccess(
        context,
        '${parsed.length} aluno(s) identificado(s)$successSuffix.',
      );
    }
  }

  Future<void> _processarImagem(Uint8List bytes, String label) async {
    if (!MigracaoOcrService.disponivel) {
      FeedbackHelper.showError(
        context,
        'Leitura de foto disponível no app mobile. Cole o texto ou use planilha.',
      );
      return;
    }

    if (!await _verificarAcessoFoto()) return;

    setState(() {
      _isLoading = true;
      _emptyResult = false;
      _alunosEncontrados = null;
      _importedPhotoBytes = bytes;
      _importedFileLabel = label;
      _controller.clear();
    });

    try {
      final texto = await MigracaoOcrService.extrairTextoDeBytes(
        bytes,
        filename: label,
      );

      if (texto.length < 8) {
        if (!mounted) return;
        FeedbackHelper.showError(
          context,
          'Pouco texto legível no print. Tente foto mais nítida ou cole o texto.',
        );
        setState(() {
          _emptyResult = false;
          _limparImportacaoVisual();
        });
        return;
      }

      await _registrarUsoFoto();

      if (!mounted) return;
      setState(() => _controller.text = texto);
      await _processarTextoMigracao(texto, successSuffix: ' no print');
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
        setState(() {
          _emptyResult = false;
          _limparImportacaoVisual();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _subirFoto() async {
    if (_isLoading || _isImportingFile) return;
    if (!await _verificarAcessoFoto()) return;
    if (!mounted) return;

    final source = await showFxHomeSheet<ImageSource>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;
        return FxHomeSheetSurface(
          isDark: isDark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: isDark,
                title: 'Subir foto ou print',
                subtitle:
                    'Tire foto só da lista de alunos, sem menus.\nFunciona com MFIT, Trainerize, planilha ou lista no WhatsApp.',
                leading: Icon(
                  Icons.add_a_photo_outlined,
                  color: primary,
                  size: 18,
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.photo_library_outlined, color: primary),
                title: const Text('Escolher da galeria'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.photo_camera_outlined, color: primary),
                title: const Text('Tirar foto agora'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null || !mounted) return;

    setState(() => _isImportingFile = true);

    try {
      if (source == ImageSource.gallery) {
        final files = await ImagePicker().pickMultiImage(
          maxWidth: 1920,
          imageQuality: 85,
        );
        if (files.isEmpty || !mounted) return;
        await _processarMultiplasImagens(files);
      } else {
        final file = await ImagePicker().pickImage(
          source: source,
          maxWidth: 1920,
          imageQuality: 85,
        );
        if (file == null || !mounted) return;
        final bytes = await file.readAsBytes();
        final label = file.name.isNotEmpty ? file.name : 'print.jpg';
        await _processarImagem(bytes, label);
      }
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _isImportingFile = false);
    }
  }

  /// OCR em múltiplos prints — concatena os textos e processa de uma vez.
  Future<void> _processarMultiplasImagens(List<XFile> files) async {
    if (!MigracaoOcrService.disponivel) {
      FeedbackHelper.showError(
        context,
        'Leitura de foto disponível no app mobile. Cole o texto ou use planilha.',
      );
      return;
    }
    if (!await _verificarAcessoFoto()) return;

    final count = files.length;
    setState(() {
      _isLoading = true;
      _emptyResult = false;
      _alunosEncontrados = null;
      _importedPhotoBytes = null;
      _importedFileLabel = count == 1 ? files.first.name : '$count prints';
      _controller.clear();
    });

    try {
      final partes = <String>[];
      for (final f in files) {
        final bytes = await f.readAsBytes();
        final texto = await MigracaoOcrService.extrairTextoDeBytes(
          bytes,
          filename: f.name,
        );
        if (texto.length >= 8) partes.add(texto);
      }

      if (partes.isEmpty) {
        if (!mounted) return;
        FeedbackHelper.showError(
          context,
          'Pouco texto legível nos prints. Tente fotos mais nítidas ou cole o texto.',
        );
        setState(() {
          _emptyResult = false;
          _limparImportacaoVisual();
        });
        return;
      }

      await _registrarUsoFoto();

      final textoTotal = partes.join('\n\n');
      if (!mounted) return;
      setState(() => _controller.text = textoTotal);
      final suffix = count == 1 ? ' no print' : ' nos $count prints';
      await _processarTextoMigracao(textoTotal, successSuffix: suffix);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
        setState(() {
          _emptyResult = false;
          _limparImportacaoVisual();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Extrai texto de PDF via pdfx: renderiza cada página como imagem e passa pelo OCR.
  Future<void> _processarPdf(Uint8List bytes, String filename) async {
    if (!MigracaoOcrService.disponivel) {
      FeedbackHelper.showError(
        context,
        'Leitura de PDF disponível no app mobile. Cole o texto ou use planilha.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _emptyResult = false;
      _alunosEncontrados = null;
      _importedPhotoBytes = null;
      _importedFileLabel = filename;
      _controller.clear();
    });

    try {
      final doc = await PdfDocument.openData(bytes);
      final partes = <String>[];

      for (var i = 1; i <= doc.pagesCount; i++) {
        final page = await doc.getPage(i);
        final rendered = await page.render(
          width: page.width * 2,
          height: page.height * 2,
          format: PdfPageImageFormat.png,
        );
        await page.close();
        if (rendered?.bytes != null) {
          final texto = await MigracaoOcrService.extrairTextoDeBytes(
            rendered!.bytes,
            filename: 'pagina_$i.png',
          );
          if (texto.length >= 8) partes.add(texto);
        }
      }
      await doc.close();

      if (partes.isEmpty) {
        if (!mounted) return;
        FeedbackHelper.showError(
          context,
          'Não foi possível ler o conteúdo desse PDF. '
          'Tente copiar o texto do PDF e colar aqui.',
        );
        setState(() {
          _emptyResult = false;
          _limparImportacaoVisual();
        });
        return;
      }

      await _registrarUsoFoto();
      final textoTotal = partes.join('\n\n');
      if (!mounted) return;
      setState(() => _controller.text = textoTotal);
      final suffix = doc.pagesCount == 1 ? ' no PDF' : ' no PDF (${doc.pagesCount} páginas)';
      await _processarTextoMigracao(textoTotal, successSuffix: suffix);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
        setState(() {
          _emptyResult = false;
          _limparImportacaoVisual();
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _importarArquivo() async {
    if (_isLoading || _isImportingFile) return;

    setState(() => _isImportingFile = true);

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'txt', 'jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        if (!mounted) return;
        FeedbackHelper.showError(
          context,
          'Não foi possível ler o arquivo selecionado.',
        );
        return;
      }

      if (_isPdfFilename(file.name)) {
        await _processarPdf(bytes, file.name);
        return;
      }

      final parsed = MigracaoFileParser.parse(
        bytes: bytes,
        filename: file.name,
      );

      if (_isImageFilename(file.name)) {
        await _processarImagem(bytes, file.name);
        return;
      }

      if (parsed.usesDirectParse) {
        var alunos = parsed.directAlunos!;
        alunos = await _enriquecerComPreview(alunos) ?? alunos;
        if (!mounted) return;
        setState(() {
          _importedFileLabel = parsed.sourceLabel;
          _importedPhotoBytes = null;
          _controller.clear();
          _alunosEncontrados = alunos;
          _emptyResult = alunos.isEmpty;
          _ignorados = parsed.ignorados;
          _amostrasIgnoradas = const [];
          _planilha = parsed.colunas == null ? null : parsed;
        });
        if (alunos.isNotEmpty) {
          FeedbackHelper.showSuccess(
            context,
            '${alunos.length} aluno(s) lidos de ${file.name}.',
          );
        }
        return;
      }

      final text = parsed.textForIa?.trim() ?? '';
      if (!mounted) return;
      setState(() {
        _importedFileLabel = parsed.sourceLabel;
        _importedPhotoBytes = null;
        _fonte = MigracaoFonte.texto;
        _controller.text = text;
        _alunosEncontrados = null;
        _emptyResult = false;
      });
      if (text.isEmpty) {
        FeedbackHelper.showError(context, 'Arquivo vazio ou ilegível.');
      } else {
        FeedbackHelper.showSuccess(
          context,
          S.of(context).migracaoTextoCarregado(file.name),
        );
      }
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _isImportingFile = false);
    }
  }

  Future<void> _colarClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        'Nada para colar da área de transferência.',
      );
      return;
    }
    setState(() {
      _controller.text = text;
      _limparImportacaoVisual();
      _emptyResult = false;
      _alunosEncontrados = null;
    });
  }

  Future<void> _processarTextoMigracao(
    String texto, {
    String successSuffix = '',
  }) async {
    final trimmed = texto.trim();
    if (trimmed.isEmpty) {
      FeedbackHelper.showError(context, 'Cole os dados dos alunos primeiro.');
      return;
    }

    final conteudo = MigracaoTextoNormalizer.normalizeForImport(trimmed);

    setState(() {
      _isLoading = true;
      _emptyResult = false;
      _alunosEncontrados = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.post(
        '/api/v1/migracao/texto',
        data: {'conteudo': conteudo},
      );

      if (!mounted) return;
      final resultado = MigracaoTextoResultado.parse(
        response.data['resultadoEstruturado'],
      );
      await _finalizarProcessamento(resultado, successSuffix: successSuffix);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
        setState(() => _emptyResult = false);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processarMigracao() async {
    final ok = await showFxConfirmSheet(
      context,
      title: migracaoIniciarConfirmTitle(),
      message: migracaoIniciarConfirmMessage(),
      confirmLabel: migracaoIniciarLabel(),
    );
    if (!ok || !mounted) return;
    await _processarTextoMigracao(_controller.text);
  }

  Future<void> _salvarAlunos() async {
    final alunos = _alunosEncontrados;
    if (alunos == null || alunos.isEmpty) return;

    final toSave =
        alunos.where((a) => a.entraNoSalvamento).toList(growable: false);
    if (toSave.isEmpty) {
      FeedbackHelper.showError(
        context,
        'Marque ao menos um aluno novo para importar.',
      );
      return;
    }

    final plano = _plano ?? ref.read(planoFeaturesProvider).value;
    final atuais = plano?.alunosAtivos ?? 0;
    final snap = MigracaoVagasSnapshot(
      alunosAtuais: atuais,
      limiteAlunos: plano?.limiteAlunos,
      novosParaImportar: toSave.length,
    );
    if (!snap.cabeNoPlano) {
      final upgrade = upgradePlanoParaMaisVagas(plano?.plano);
      await UpgradePromptSheet.show(
        context: context,
        featureName: 'Mais vagas de alunos',
        capability: 'alunos',
        requiredPlan: upgrade,
        upgradePlano: upgrade,
        source: 'migracao_limite',
      );
      return;
    }

    final ok = await showFxConfirmSheet(
      context,
      title: migracaoSalvarConfirmTitle(toSave.length),
      message: migracaoSalvarConfirmMessage(),
      confirmLabel: migracaoSalvarLabel(toSave.length),
    );
    if (!ok || !mounted) return;

    setState(() => _isSaving = true);

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.post(
        '/api/v1/migracao/confirmar',
        data: {'alunos': toSave.map((a) => a.toJson()).toList()},
      );

      if (!mounted) return;
      final resumo = MigracaoImportacaoResumo.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      setState(() {
        _importResumo = resumo;
        _acessoStatus.clear();
        _alunosEncontrados = null;
        _emptyResult = false;
        _limparImportacaoVisual();
        _controller.clear();
      });
      if (resumo.emailNaoSaiu.isNotEmpty) {
        // Diagnóstico para quem opera o Focux: o motivo estável do Resend, sem dado do aluno.
        AnalyticsService.instance.track(
          ProductEvents.migracaoEmailNaoSaiu,
          props: {
            'quantos': resumo.emailNaoSaiu.length,
            'motivos': resumo.emailNaoSaiu.map((d) => d.emailFalha ?? 'desconhecido').toSet().join(','),
          },
        );
      }
      await MigracaoMagicaDraftCache.clear();
      invalidateAlunosCaches(ref);
      await ref.read(planoFeaturesProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;
      final paywalled = await UpgradePromptSheet.showFromError(
        context,
        e,
        fallbackFeatureName: 'Mais vagas de alunos',
        fallbackCapability: 'alunos',
        source: 'migracao_confirmar',
      );
      if (!paywalled && mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _irParaListaAlunos() async {
    final pendentes =
        _importResumo?.importadosComAcesso
            .where((d) => !_acessoStatus.containsKey(d.alunoId))
            .length ??
        0;
    if (pendentes > 0) {
      final s = S.of(context);
      final sair = await showFxConfirmSheet(
        context,
        title: s.migracaoAcessoSairTitulo,
        message: s.migracaoAcessoSairTexto(pendentes),
        confirmLabel: s.migracaoAcessoSairConfirma,
        cancelLabel: s.migracaoAcessoSairCancela,
      );
      if (!sair || !mounted) return;
    }
    if (!mounted) return;
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/alunos');
    }
  }

  void _alternarSelecao(int index, bool selecionado) {
    final alunos = _alunosEncontrados;
    if (alunos == null || index < 0 || index >= alunos.length) return;
    setState(() {
      alunos[index] = alunos[index].copyWith(selecionado: selecionado);
    });
  }

  Future<void> _trocarColuna(String campo) async {
    final planilha = _planilha;
    final atual = planilha?.colunas;
    if (planilha == null || atual == null) return;
    final selecionadoAtual = switch (campo) {
          'nome' => atual.nome,
          'email' => atual.email,
          'telefone' => atual.telefone,
          _ => atual.objetivo,
        } ??
        -1;
    final escolha = await showFxInsetPickerSheet<int>(
      context,
      title: 'Coluna de ${migracaoCampoLabel(campo)}',
      headerIcon: Icons.table_chart_outlined,
      items: [
        const FxInsetPickerSheetItem(value: -1, label: 'Não importar'),
        for (var i = 0; i < planilha.headers.length; i++)
          FxInsetPickerSheetItem(
            value: i,
            label: planilha.headers[i].isEmpty
                ? 'Coluna ${i + 1}'
                : planilha.headers[i],
          ),
      ],
      selected: selecionadoAtual,
    );
    if (escolha == null || !mounted) return;
    final idx = escolha < 0 ? null : escolha;
    final novas = MigracaoColunas(
      nome: campo == 'nome' ? idx : atual.nome,
      email: campo == 'email' ? idx : atual.email,
      telefone: campo == 'telefone' ? idx : atual.telefone,
      objetivo: campo == 'objetivo' ? idx : atual.objetivo,
    );
    final remapeado = MigracaoFileParser.reaplicarColunas(planilha, novas);
    final alunos = await _enriquecerComPreview(remapeado.directAlunos) ?? [];
    if (!mounted) return;
    setState(() {
      _planilha = remapeado;
      _alunosEncontrados = alunos;
      _ignorados = remapeado.ignorados;
      _emptyResult = alunos.isEmpty;
    });
  }

  Future<void> _editarAluno(int index) async {
    final alunos = _alunosEncontrados;
    if (alunos == null || index < 0 || index >= alunos.length) return;

    final aluno = alunos[index];
    final nomeCtrl = TextEditingController(text: aluno.nome);
    final emailCtrl = TextEditingController(text: aluno.email ?? '');
    final telCtrl = TextEditingController(text: aluno.telefone ?? '');
    final objCtrl = TextEditingController(text: aluno.objetivo ?? '');

    final saved = await showFxHomeSheet<bool>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;

        return FxHomeSheetSurface(
          isDark: isDark,
          maxHeight:
              MediaQuery.sizeOf(ctx).height * FxHomeSheetChrome.maxHeightFactor,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FxHomeSheetHandle(isDark: isDark),
                SizedBox(height: TokensStrip.s4),
                FxHomeSheetHeader(
                  isDark: isDark,
                  title: 'Editar aluno',
                  leading: Icon(
                    Icons.person_outline_rounded,
                    color: primary,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nomeCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: FxInputDeco.build(ctx, 'Nome'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: FxInputDeco.build(ctx, 'E-mail (opcional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: FxInputDeco.build(ctx, 'Telefone (opcional)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: objCtrl,
                  decoration: FxInputDeco.build(ctx, 'Objetivo (opcional)'),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Salvar alterações'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved != true || !mounted) {
      nomeCtrl.dispose();
      emailCtrl.dispose();
      telCtrl.dispose();
      objCtrl.dispose();
      return;
    }

    final updated = MigracaoAlunoLinha(
      nome:
          nomeCtrl.text.trim().isEmpty
              ? 'Aluno sem nome'
              : nomeCtrl.text.trim(),
      email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      telefone: telCtrl.text.trim().isEmpty ? null : telCtrl.text.trim(),
      objetivo: objCtrl.text.trim().isEmpty ? null : objCtrl.text.trim(),
    );

    nomeCtrl.dispose();
    emailCtrl.dispose();
    telCtrl.dispose();
    objCtrl.dispose();

    final enriched = await _enriquecerComPreview([updated]);
    setState(() {
      alunos[index] = enriched?.first ?? updated;
    });
  }

  Future<List<MigracaoAlunoLinha>?> _enriquecerComPreview(
    List<MigracaoAlunoLinha>? alunos,
  ) async {
    if (alunos == null || alunos.isEmpty) return alunos;
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.post(
        '/api/v1/migracao/preview',
        data: {'alunos': alunos.map((a) => a.toJson()).toList()},
      );
      final preview = MigracaoAlunoLinha.fromPreviewResponse(response.data);
      if (preview.isNotEmpty) {
        return MigracaoAlunoLinha.mesclarPreview(alunos, preview);
      }
    } catch (_) {
      // Preview é enriquecimento; fallback mantém lista local.
    }
    return alunos;
  }

  Future<bool> _confirmDiscard() {
    return showFxConfirmSheet(
      context,
      title: migracaoDiscardTitle(),
      message: migracaoDiscardMessage(),
      confirmLabel: migracaoDiscardConfirmLabel(),
      cancelLabel: migracaoDiscardCancelLabel(),
      destructive: true,
    );
  }

  Future<void> _handleBack() async {
    if (_isAcesso) {
      _irParaListaAlunos();
      return;
    }
    _persistDraft();
    if (!_hasUnsavedWork) {
      safePopOrGo(context, '/alunos');
      return;
    }
    final leave = await _confirmDiscard();
    if (leave && mounted) safePopOrGo(context, '/alunos');
  }
}
