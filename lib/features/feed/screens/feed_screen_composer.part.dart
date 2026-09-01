part of 'feed_screen.dart';

class _FeedComposerSheet extends StatefulWidget {
  const _FeedComposerSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_FeedComposerSheet> createState() => _FeedComposerSheetState();
}

class _FeedComposerSheetState extends State<_FeedComposerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _conteudoCtrl = TextEditingController();
  String _tipoSelecionado = 'TEXTO';
  XFile? _midiaSelecionada;
  bool _salvando = false;
  bool _escolhendoMidia = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _conteudoCtrl.dispose();
    super.dispose();
  }

  Future<void> _escolherMidia(String tipo) async {
    if (_escolhendoMidia) return;
    setState(() => _escolhendoMidia = true);
    try {
      final picker = ImagePicker();
      final file =
          tipo == 'VIDEO'
              ? await picker.pickVideo(source: ImageSource.gallery)
              : await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: 86,
                maxWidth: 1600,
              );
      if (file != null) {
        setState(() => _midiaSelecionada = file);
      }
    } finally {
      if (mounted) setState(() => _escolhendoMidia = false);
    }
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _salvando = true);
    try {
      String? midiaUrl;
      if (_midiaSelecionada != null &&
          (_tipoSelecionado == 'IMAGEM' || _tipoSelecionado == 'VIDEO')) {
        midiaUrl = await MediaUploadService(
          widget.ref.read(apiClientProvider),
        ).uploadBytes(
          bytes: await _midiaSelecionada!.readAsBytes(),
          filename: _midiaSelecionada!.name,
          folder: _tipoSelecionado == 'VIDEO' ? 'feed/videos' : 'feed/images',
          resourceType: _tipoSelecionado == 'VIDEO' ? 'video' : 'image',
        );
      }
      await FeedRepository(widget.ref.read(apiClientProvider)).criar(
        _tituloCtrl.text.trim(),
        _conteudoCtrl.text.trim(),
        tipoPost: _tipoSelecionado,
        midiaUrl: midiaUrl,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: FxSettingsLayout.pageInset,
        right: FxSettingsLayout.pageInset,
        top: TokensStrip.s3,
        bottom: MediaQuery.of(context).viewInsets.bottom + TokensStrip.s4,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FxInsetPickerRow(
                  icon: Icons.category_outlined,
                  label: 'Tipo de post',
                  value: feedTipoLabel(_tipoSelecionado),
                  onTap: () async {
                    final picked = await showFxInsetPickerSheet<String>(
                      context,
                      title: 'Tipo de post',
                      selected: _tipoSelecionado,
                      items: [
                        for (final t in feedTipoValues)
                          FxInsetPickerSheetItem(
                            value: t,
                            label: feedTipoLabel(t),
                          ),
                      ],
                    );
                    if (picked == null) return;
                    setState(() {
                      _tipoSelecionado = picked;
                      if (!feedTipoTemMidia(picked)) {
                        _midiaSelecionada = null;
                      }
                    });
                  },
                ),
                AlunoInsetFormField(
                  controller: _tituloCtrl,
                  label: 'Título',
                  icon: Icons.title_outlined,
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Informe o título'
                              : null,
                ),
                AlunoInsetFormField(
                  controller: _conteudoCtrl,
                  label: 'Conteúdo',
                  icon: Icons.notes_outlined,
                  maxLines: 4,
                  showDivider: false,
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Informe o conteúdo'
                              : null,
                ),
                if (feedTipoTemMidia(_tipoSelecionado)) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed:
                        _salvando || _escolhendoMidia
                            ? null
                            : () => _escolherMidia(_tipoSelecionado),
                    icon:
                        _escolhendoMidia
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: FxLoading(strokeWidth: 2),
                            )
                            : Icon(
                              _tipoSelecionado == 'VIDEO'
                                  ? Icons.video_library_outlined
                                  : Icons.photo_library_outlined,
                            ),
                    label: Text(
                      feedMidiaCta(
                        tipo: _tipoSelecionado,
                        hasFile: _midiaSelecionada != null,
                      ),
                    ),
                  ),
                  if (_midiaSelecionada != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(TokensStrip.rCard),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _tipoSelecionado == 'VIDEO'
                                ? Icons.movie_outlined
                                : Icons.image_outlined,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _midiaSelecionada!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remover arquivo',
                            visualDensity: VisualDensity.compact,
                            onPressed:
                                _salvando
                                    ? null
                                    : () => setState(
                                      () => _midiaSelecionada = null,
                                    ),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: TokensStrip.s5),
                FxLiquidPrimaryButton(
                  label: _salvando ? 'Publicando...' : 'Publicar',
                  icon: Icons.send,
                  loading: _salvando,
                  onPressed: _salvando ? null : _publicar,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
