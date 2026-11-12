import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../l10n/pt.dart';
import '../data/feed_repository.dart';
import '../utils/feed_display.dart';

/// Compositor do feed: uma caixa só (a primeira linha vira o título), Foto e
/// Vídeo com rótulo, "Mostrar como dica" e "Avisar os alunos". Publica com a
/// folha aberta; se falhar, o texto e a mídia ficam.
class FeedComposerSheet extends StatefulWidget {
  const FeedComposerSheet({super.key, required this.ref, this.post});

  final WidgetRef ref;

  /// Com post, edita só o texto: mídia e tipo ficam como foram publicados.
  final FeedPost? post;

  @override
  State<FeedComposerSheet> createState() => _FeedComposerSheetState();
}

class _FeedComposerSheetState extends State<FeedComposerSheet> {
  final _textoCtrl = TextEditingController();
  String _tipoMidia = 'IMAGEM';
  bool _dica = false;
  bool _avisar = true;
  XFile? _midia;
  bool _salvando = false;
  bool _escolhendoMidia = false;

  bool get _editando => widget.post != null;

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    if (post != null) {
      _textoCtrl.text = feedJuntarTitulo(post.titulo, post.conteudo);
    }
  }

  @override
  void dispose() {
    _textoCtrl.dispose();
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
      if (file != null && mounted) {
        setState(() {
          _midia = file;
          _tipoMidia = tipo;
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
    final partes = feedSepararTitulo(_textoCtrl.text);
    try {
      final repo = FeedRepository(widget.ref.read(apiClientProvider));
      if (widget.post case final post?) {
        await repo.editar(post.id, partes.titulo, partes.conteudo);
        if (mounted) FxHomeSheetChrome.dismissAndPop(context, true);
        return;
      }
      String? midiaUrl;
      if (_midia case final midia?) {
        midiaUrl = await MediaUploadService(
          widget.ref.read(apiClientProvider),
        ).uploadBytes(
          bytes: await midia.readAsBytes(),
          filename: midia.name,
          folder: _tipoMidia == 'VIDEO' ? 'feed/videos' : 'feed/images',
          resourceType: _tipoMidia == 'VIDEO' ? 'video' : 'image',
        );
      }
      await repo.criar(
        partes.titulo,
        partes.conteudo,
        tipoPost: _tipoFinal,
        midiaUrl: midiaUrl,
        avisar: _avisar,
      );
      if (mounted) {
        HapticFeedback.heavyImpact();
        FxHomeSheetChrome.dismissAndPop(context, true);
      }
    } catch (e) {
      // A folha fica aberta com o texto e a mídia: é só tentar de novo.
      if (mounted) {
        setState(() => _salvando = false);
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  /// A mídia define o tipo; sem mídia é texto, ou dica se ligada.
  String get _tipoFinal {
    if (_midia != null) return _tipoMidia;
    return _dica ? 'DICA' : 'TEXTO';
  }

  bool get _podePublicar =>
      _textoCtrl.text.trim().isNotEmpty ||
      _midia != null ||
      (widget.post?.midiaUrl?.trim().isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final midia = _midia;
    final ocupado = _salvando || _escolhendoMidia;
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
            controller: _textoCtrl,
            autofocus: true,
            minLines: 4,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: [
              LengthLimitingTextInputFormatter(feedConteudoMax),
            ],
            onChanged: (_) => setState(() {}),
            style: FocuxHubTypography.body(color: chrome.ink),
            decoration: InputDecoration(
              hintText: ptS.feedOQueVoceQuerContar,
              border: InputBorder.none,
              filled: false,
              isDense: true,
            ),
          ),
          Text(
            'A primeira linha vira o título.',
            style: FocuxHubTypography.minimo(color: chrome.mute),
          ),
          if (midia != null) ...[
            const SizedBox(height: TokensStrip.s3),
            _PreviaMidia(midia: midia, video: _tipoMidia == 'VIDEO'),
            const SizedBox(height: TokensStrip.s2),
            Row(
              children: [
                FxTonalButton(
                  label: 'Trocar',
                  icon: FxIcons.trocar,
                  compact: true,
                  onPressed: ocupado ? null : () => _escolherMidia(_tipoMidia),
                ),
                const SizedBox(width: TokensStrip.s2),
                FxTonalButton(
                  label: 'Remover',
                  icon: FxIcons.fechar,
                  compact: true,
                  onPressed:
                      ocupado ? null : () => setState(() => _midia = null),
                ),
              ],
            ),
          ] else if (!_editando) ...[
            const SizedBox(height: TokensStrip.s3),
            Row(
              children: [
                FxTonalButton(
                  label: 'Foto',
                  icon: FxIcons.imagem,
                  compact: true,
                  onPressed: ocupado ? null : () => _escolherMidia('IMAGEM'),
                ),
                const SizedBox(width: TokensStrip.s2),
                FxTonalButton(
                  label: ptS.feedVideo,
                  icon: FxIcons.video,
                  compact: true,
                  onPressed: ocupado ? null : () => _escolherMidia('VIDEO'),
                ),
              ],
            ),
          ],
          if (!_editando) ...[
            const SizedBox(height: TokensStrip.s3),
            FxSettingsGroup(
              children: [
                if (midia == null)
                  FxSettingsTile(
                    icon: FxIcons.ideia,
                    label: 'Mostrar como dica',
                    subtitle:
                        'Aparece com o selo de dica e fica no filtro Dicas dos alunos.',
                    value: '',
                    accessory: Switch.adaptive(
                      activeTrackColor: primary,
                      value: _dica,
                      onChanged:
                          _salvando ? null : (v) => setState(() => _dica = v),
                    ),
                  ),
                FxSettingsTile(
                  icon: FxIcons.notificacao,
                  label: 'Avisar os alunos',
                  subtitle: 'Eles recebem um aviso no celular.',
                  value: '',
                  showDivider: false,
                  accessory: Switch.adaptive(
                    activeTrackColor: primary,
                    value: _avisar,
                    onChanged:
                        _salvando ? null : (v) => setState(() => _avisar = v),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: TokensStrip.s3),
          FxLiquidPrimaryButton(
            label: _editando ? ptS.save : 'Publicar',
            loading: _salvando,
            loadingLabel:
                _editando ? ptS.checkinSalvandoSerie : ptS.feedPublicando,
            onPressed: _salvando || !_podePublicar ? null : _publicar,
          ),
        ],
      ),
    );
  }
}

/// Prévia no tamanho real: foto inteira (até 280 de altura), vídeo pelo nome.
class _PreviaMidia extends StatelessWidget {
  const _PreviaMidia({required this.midia, required this.video});

  final XFile midia;
  final bool video;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    if (video) {
      return Container(
        padding: const EdgeInsets.all(TokensStrip.s3),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
        ),
        child: Row(
          children: [
            Icon(FxIcons.video, color: primary, size: 22),
            const SizedBox(width: TokensStrip.s2),
            Expanded(
              child: Text(
                midia.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.bodyMuted(color: chrome.ink),
              ),
            ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: Image.file(
          File(midia.path),
          fit: BoxFit.contain,
          width: double.infinity,
          errorBuilder:
              (_, __, ___) => Padding(
                padding: const EdgeInsets.all(TokensStrip.s3),
                child: Text(
                  midia.name,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
              ),
        ),
      ),
    );
  }
}
