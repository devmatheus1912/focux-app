import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../features/alunos/widgets/aluno_inset_form_field.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/feed_repository.dart';
import '../utils/feed_display.dart';

class FeedComposerSheet extends StatefulWidget {
  const FeedComposerSheet({super.key, required this.ref});

  final WidgetRef ref;

  @override
  State<FeedComposerSheet> createState() => _FeedComposerSheetState();
}

class _FeedComposerSheetState extends State<FeedComposerSheet> {
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
    if (_salvando) return;
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final ok = await showFxConfirmSheet(
      context,
      title: feedPublicarConfirmTitle(),
      message: feedPublicarConfirmMessage(),
      icon: Icons.rss_feed_outlined,
      confirmLabel: feedPublicarConfirmLabel(),
    );
    if (!ok || !mounted) return;
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
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _abrirTipo() async {
    final picked = await showFxInsetPickerSheet<String>(
      context,
      title: 'Tipo de post',
      selected: _tipoSelecionado,
      items: [
        for (final t in feedTipoValues.where((t) => t != 'ENQUETE'))
          FxInsetPickerSheetItem(value: t, label: feedTipoLabel(t)),
      ],
    );
    if (picked == null) return;
    setState(() {
      _tipoSelecionado = picked;
      if (!feedTipoTemMidia(picked)) {
        _midiaSelecionada = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final temMidia = feedTipoTemMidia(_tipoSelecionado);
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
                FxSettingsGroup(
                  children: [
                    FxSettingsTile(
                      fxIcon: 'article',
                      label: 'Tipo de post',
                      value: feedTipoLabel(_tipoSelecionado),
                      picker: true,
                      onTap: _salvando ? null : _abrirTipo,
                    ),
                    AlunoInsetFormField(
                      controller: _tituloCtrl,
                      label: 'Título',
                      icon: Icons.title_outlined,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(feedTituloMax),
                      ],
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
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(feedConteudoMax),
                      ],
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Informe o conteúdo'
                                  : null,
                    ),
                  ],
                ),
                if (temMidia) ...[
                  const SizedBox(height: TokensStrip.s3),
                  FxSettingsGroup(
                    children: [
                      FxSettingsTile(
                        fxIcon: _tipoSelecionado == 'VIDEO' ? 'trend' : 'article',
                        label: feedMidiaCta(
                          tipo: _tipoSelecionado,
                          hasFile: _midiaSelecionada != null,
                        ),
                        value:
                            _escolhendoMidia
                                ? 'Abrindo…'
                                : (_midiaSelecionada?.name ?? 'Galeria'),
                        picker: true,
                        onTap:
                            _salvando || _escolhendoMidia
                                ? null
                                : () => _escolherMidia(_tipoSelecionado),
                        showDivider: _midiaSelecionada != null,
                      ),
                      if (_midiaSelecionada != null)
                        FxSettingsTile(
                          fxIcon: 'x',
                          label: 'Remover arquivo',
                          value: '',
                          danger: true,
                          showDivider: false,
                          onTap:
                              _salvando
                                  ? null
                                  : () => setState(() => _midiaSelecionada = null),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: TokensStrip.s3),
                FxLiquidPrimaryButton(
                  label: feedPublicarTileLabel(),
                  loading: _salvando,
                  loadingLabel: 'Publicando…',
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
