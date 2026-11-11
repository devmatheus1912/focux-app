import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/design_tokens.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/fx_icons.dart';
import '../theme/tokens_strip.dart';
import 'fx_loading.dart';
import 'fx_tonal_button.dart';

/// Cloudinary entrega H.264 (o iPhone não toca todo codec de upload).
String cloudinaryH264VideoUrl(String rawUrl) {
  const marker = '/video/upload/';
  final url = rawUrl.trim();
  if (!url.contains(marker)) return url;
  final delivery = url.substring(url.indexOf(marker) + marker.length);
  if (delivery.startsWith('f_mp4') ||
      delivery.startsWith('vc_h264') ||
      delivery.startsWith('vc_auto')) {
    return url;
  }
  return url.replaceFirst(marker, '${marker}f_mp4,vc_h264/');
}

/// Vídeo de rede em 16:9, dentro da tela: carregando, tocar/pausar com um
/// toque e, se não carregar, "Abrir fora do app" ([onAbrirFora]).
class FxVideoRede extends StatefulWidget {
  const FxVideoRede({
    super.key,
    required this.url,
    this.autoplay = false,
    this.semSom = false,
    this.onAbrirFora,
  });

  final String url;
  final bool autoplay;
  final bool semSom;
  final VoidCallback? onAbrirFora;

  @override
  State<FxVideoRede> createState() => _FxVideoRedeState();
}

class _FxVideoRedeState extends State<FxVideoRede> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(cloudinaryH264VideoUrl(widget.url)),
    );
    _controller = controller;
    if (mounted) {
      setState(() {
        _ready = false;
        _failed = false;
      });
    }
    try {
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      if (widget.semSom) await controller.setVolume(0);
      controller.addListener(_atualizar);
      setState(() => _ready = true);
      if (widget.autoplay) await controller.play();
    } catch (_) {
      await controller.dispose();
      if (!mounted || _controller != controller) return;
      _controller = null;
      // Vídeo recém-enviado ainda processando no Cloudinary: tenta de novo.
      if (_attempt < 4) {
        _attempt += 1;
        await Future<void>.delayed(Duration(seconds: 2 + _attempt));
        if (mounted) await _carregar();
        return;
      }
      if (mounted) setState(() => _failed = true);
    }
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  void _alternar() {
    final c = _controller;
    if (c == null || !_ready) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      if (c.value.position >= c.value.duration) c.seekTo(Duration.zero);
      c.play();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_atualizar);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final c = _controller;
    final tocando = c?.value.isPlaying ?? false;
    return ClipRRect(
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      clipBehavior: Clip.hardEdge,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: isDark ? TokensStrip.cinematicSurface : TokensStrip.cardBg,
          child:
              _failed
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Não deu para tocar aqui.',
                          style: FocuxHubTypography.bodyMuted(color: mute),
                        ),
                        if (widget.onAbrirFora != null)
                          FxTonalButton(
                            label: 'Abrir fora do app',
                            onPressed: widget.onAbrirFora,
                            compact: true,
                          ),
                      ],
                    ),
                  )
                  : _ready && c != null
                  ? Semantics(
                    button: true,
                    label: tocando ? 'Pausar vídeo' : 'Tocar vídeo',
                    child: GestureDetector(
                      onTap: _alternar,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          FittedBox(
                            fit: BoxFit.contain,
                            clipBehavior: Clip.hardEdge,
                            child: SizedBox(
                              width: c.value.size.width,
                              height: c.value.size.height,
                              child: VideoPlayer(c),
                            ),
                          ),
                          if (!tocando)
                            Center(
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  color: Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    TokensStrip.s2,
                                  ),
                                  child: Icon(
                                    FxIcons.playCirculo,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                  : Center(
                    child: FxLoading(
                      size: 28,
                      color: isDark ? Colors.white : TokensStrip.textPrimary,
                    ),
                  ),
        ),
      ),
    );
  }
}
