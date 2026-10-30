import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
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
  final _tituloCtrl = TextEditingController();
  final _conteudoCtrl = TextEditingController();
  String _tipoSelecionado = 'IMAGEM';
  bool _dica = false;
  bool _comTitulo = false;
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
        setState(() {
          _midiaSelecionada = file;
          _tipoSelecionado = tipo;
        });
      }
    } finally {
      if (mounted) setState(() => _escolhendoMidia = false);
    }
  }

  Future<void> _publicar() async {
    if (_salvando) return;
    HapticFeedback.mediumImpact();
    setState(() => _salvando = true);
    try {
      String? midiaUrl;
      if (_midiaSelecionada != null) {
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
        tipoPost: _tipoFinal,
        midiaUrl: midiaUrl,
      );
      if (mounted) {
        HapticFeedback.heavyImpact();
        FxHomeSheetChrome.dismissAndPop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _salvando = false);
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  /// A mídia define o tipo; sem mídia é texto, ou dica se ligada.
  String get _tipoFinal {
    if (_midiaSelecionada != null) return _tipoSelecionado;
    return _dica ? 'DICA' : 'TEXTO';
  }

  bool get _podePublicar =>
      _conteudoCtrl.text.trim().isNotEmpty || _midiaSelecionada != null;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final midia = _midiaSelecionada;
    // viewInsets já sobe em FxHomeSheetChrome.paddingOf — sem pad duplicado.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s3,
        FxSettingsLayout.pageInset,
        TokensStrip.s2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _conteudoCtrl,
            autofocus: true,
            minLines: 4,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [LengthLimitingTextInputFormatter(feedConteudoMax)],
            onChanged: (_) => setState(() {}),
            style: FocuxHubTypography.body(color: chrome.ink),
            decoration: const InputDecoration(
              hintText: 'O que você quer contar aos alunos?',
              border: InputBorder.none,
              filled: false,
              isDense: true,
            ),
          ),
          if (_comTitulo)
            TextField(
              controller: _tituloCtrl,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(feedTituloMax)],
              style: FocuxHubTypography.cardTitle(color: chrome.ink),
              decoration: const InputDecoration(
                hintText: 'Título',
                border: InputBorder.none,
                filled: false,
                isDense: true,
              ),
            ),
          if (midia != null) ...[
            const SizedBox(height: TokensStrip.s2),
            Row(
              children: [
                Icon(
                  _tipoSelecionado == 'VIDEO'
                      ? Icons.videocam_outlined
                      : Icons.image_outlined,
                  color: primary,
                  size: 20,
                ),
                const SizedBox(width: TokensStrip.s2),
                Expanded(
                  child: Text(
                    midia.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                ),
                IconButton(
                  tooltip: 'Remover',
                  onPressed:
                      _salvando
                          ? null
                          : () => setState(() => _midiaSelecionada = null),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ],
          const SizedBox(height: TokensStrip.s2),
          Row(
            children: [
              IconButton(
                tooltip: 'Foto',
                onPressed:
                    _salvando || _escolhendoMidia
                        ? null
                        : () => _escolherMidia('IMAGEM'),
                icon: Icon(Icons.image_outlined, color: primary),
              ),
              IconButton(
                tooltip: 'Vídeo',
                onPressed:
                    _salvando || _escolhendoMidia
                        ? null
                        : () => _escolherMidia('VIDEO'),
                icon: Icon(Icons.videocam_outlined, color: primary),
              ),
              IconButton(
                tooltip: 'Título',
                onPressed: () => setState(() => _comTitulo = !_comTitulo),
                icon: Icon(Icons.title_rounded, color: primary),
              ),
              const Spacer(),
              FilterChip(
                label: const Text('Dica'),
                selected: _dica,
                onSelected:
                    midia != null ? null : (v) => setState(() => _dica = v),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s2),
          FxLiquidPrimaryButton(
            label: feedPublicarTileLabel(),
            loading: _salvando,
            loadingLabel: 'Publicando…',
            onPressed: _salvando || !_podePublicar ? null : _publicar,
          ),
        ],
      ),
    );
  }
}
