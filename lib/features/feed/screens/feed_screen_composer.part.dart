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
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Nova Publicação',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s4),
                DropdownButtonFormField<String>(
                  initialValue: _tipoSelecionado,
                  decoration: InputDecoration(
                    labelText: 'Tipo de post',
                    border: FxInputDeco.outlineBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'TEXTO', child: Text('Texto')),
                    DropdownMenuItem(value: 'IMAGEM', child: Text('Imagem')),
                    DropdownMenuItem(value: 'VIDEO', child: Text('Vídeo')),
                    DropdownMenuItem(value: 'ENQUETE', child: Text('Enquete')),
                    DropdownMenuItem(value: 'DICA', child: Text('Dica rápida')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _tipoSelecionado = v;
                        if (v != 'IMAGEM' && v != 'VIDEO') {
                          _midiaSelecionada = null;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tituloCtrl,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    border: FxInputDeco.outlineBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Informe o título'
                              : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _conteudoCtrl,
                  decoration: InputDecoration(
                    labelText: 'Conteúdo',
                    border: FxInputDeco.outlineBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    prefixIcon: Icon(Icons.text_fields),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator:
                      (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Informe o conteúdo'
                              : null,
                ),
                if (_tipoSelecionado == 'IMAGEM' ||
                    _tipoSelecionado == 'VIDEO') ...[
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
                      _midiaSelecionada == null
                          ? (_tipoSelecionado == 'VIDEO'
                              ? 'Escolher vídeo'
                              : 'Escolher imagem')
                          : 'Trocar arquivo',
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
