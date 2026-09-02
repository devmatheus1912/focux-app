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

  Future<bool> _verificarAcessoFoto() async {
    final plano = _plano;
    if (plano == null) {
      await ref.read(planoFeaturesProvider.notifier).refresh();
    }
    final atual = ref.read(planoFeaturesProvider).value;
    if (atual == null) return true;

    if (!atual.migracaoFoto) {
      await _mostrarPaywallFoto(atual);
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

  Future<void> _mostrarPaywallFoto(PlanoFeatures plano) async {
    final offer = PlanEntitlements.lockedOffer(
      featureName: 'Foto na migração',
      capability: 'migracaoFoto',
    );
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    offer.headline,
                    style: FocuxHubTypography.sectionTitle(
                      ctx,
                      color: ShellChrome.of(ctx).ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(offer.body, style: const TextStyle(height: 1.45)),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push(
                        '/assinatura',
                        extra: offer.targetPlan?.apiName,
                      );
                    },
                    child: Text(offer.ctaLabel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Agora não'),
                  ),
                ],
              ),
            ),
          ),
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
    List<MigracaoAlunoLinha>? parsed, {
    String successSuffix = '',
  }) async {
    parsed = await _enriquecerComPreview(parsed);
    if (!mounted) return;
    setState(() {
      _alunosEncontrados = parsed;
      _emptyResult = parsed == null || parsed.isEmpty;
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
                    'Screenshot de MFIT, Trainerize, planilha ou lista no WhatsApp.',
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
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      final label = file.name.isNotEmpty ? file.name : 'print.jpg';
      await _processarImagem(bytes, label);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _isImportingFile = false);
    }
  }

  Future<void> _importarArquivo() async {
    if (_isLoading || _isImportingFile) return;

    setState(() => _isImportingFile = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'txt', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (!mounted) return;
        FeedbackHelper.showError(
          context,
          'Não foi possível ler o arquivo selecionado.',
        );
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
        _controller.text = text;
        _alunosEncontrados = null;
        _emptyResult = false;
      });
      if (text.isEmpty) {
        FeedbackHelper.showError(context, 'Arquivo vazio ou ilegível.');
      } else {
        FeedbackHelper.showSuccess(
          context,
          'Texto carregado de ${file.name}. Toque Iniciar migração.',
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

    setState(() {
      _isLoading = true;
      _emptyResult = false;
      _alunosEncontrados = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.post(
        '/api/v1/migracao/texto',
        data: {'conteudo': trimmed},
      );

      if (!mounted) return;
      final parsed = _parsarResultado(response.data['resultadoEstruturado']);
      await _finalizarProcessamento(parsed, successSuffix: successSuffix);
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

    final toSave = alunos.where((a) => !a.duplicado).toList(growable: false);
    if (toSave.isEmpty) {
      FeedbackHelper.showError(
        context,
        'Todos os alunos já estão cadastrados. Remova duplicados ou edite e-mails.',
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
      await _mostrarResumoImportacao(
        MigracaoImportacaoResumo.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        ),
      );
      setState(() {
        _alunosEncontrados = null;
        _emptyResult = false;
        _limparImportacaoVisual();
        _controller.clear();
      });
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _mostrarResumoImportacao(MigracaoImportacaoResumo data) async {
    final importados = data.importados;
    final duplicados = data.duplicados;
    final erros = data.erros;
    final mensagem = data.mensagem;
    final detalhes = data.detalhes;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
        final mute =
            isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
        final brand = Theme.of(ctx).colorScheme.primary;

        Widget stat(String label, int value, Color color) {
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(TokensStrip.rSm),
              ),
              child: Column(
                children: [
                  Text(
                    '$value',
                    style: FocuxTypography.headline(color: color),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: FocuxHubTypography.bodyMuted(
                      color: mute,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: brand, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Importação concluída',
                        style: FocuxHubTypography.sectionTitle(
                          context,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
                if (mensagem.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(mensagem, style: TextStyle(color: mute, height: 1.45)),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    stat('Importados', importados, brand),
                    const SizedBox(width: 8),
                    stat('Duplicados', duplicados, EagleTokens.warn),
                    const SizedBox(width: 8),
                    stat('Erros', erros, EagleTokens.bad),
                  ],
                ),
                if (detalhes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: detalhes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final item = detalhes[i];
                        final nome = item.nome;
                        final status = item.status;
                        final motivo = item.motivo;
                        Color badgeColor;
                        switch (status) {
                          case 'IMPORTADO':
                            badgeColor = brand;
                          case 'DUPLICADO':
                            badgeColor = EagleTokens.warn;
                          default:
                            badgeColor = EagleTokens.bad;
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: badgeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nome,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: ink,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (motivo.isNotEmpty)
                                    Text(
                                      motivo,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: mute,
                                        height: 1.35,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removerAluno(int index) {
    final alunos = _alunosEncontrados;
    if (alunos == null) return;
    setState(() {
      alunos.removeAt(index);
      if (alunos.isEmpty) _alunosEncontrados = null;
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
              ? 'Aluno importado'
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
      if (preview.isNotEmpty) return preview;
    } catch (_) {
      // Preview é enriquecimento; fallback mantém lista local.
    }
    return alunos;
  }

  List<MigracaoAlunoLinha>? _parsarResultado(dynamic data) =>
      MigracaoAlunoLinha.parseResultado(data);

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
    if (!_hasUnsavedWork) {
      safePopOrGo(context, '/dashboard/personal');
      return;
    }
    final discard = await _confirmDiscard();
    if (discard && mounted) safePopOrGo(context, '/dashboard/personal');
  }
}
