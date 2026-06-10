import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/chat_repository.dart';

enum ConversationMediaType { photo, video, audio }

class ConversationMediaPreview extends StatelessWidget {
  final ChatMsg msg;
  final bool mine;
  final bool isDark;
  final VoidCallback onOpen;

  const ConversationMediaPreview({
    super.key,
    required this.msg,
    required this.mine,
    required this.isDark,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final tipo = msg.primaryMediaType;
    final url = msg.primaryMediaUrl;
    if (tipo == null || url == null || url.isEmpty) {
      return const SizedBox.shrink();
    }

    if (tipo == 'IMAGE' || tipo == 'IMAGEM') {
      final previewWidth = (MediaQuery.sizeOf(context).width * 0.56).clamp(
        156.0,
        220.0,
      );
      final previewHeight = previewWidth * 0.9;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: onOpen,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Image.network(
                  url,
                  height: previewHeight,
                  width: previewWidth,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        height: previewHeight,
                        width: previewWidth,
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Abrir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    IconData icon = Icons.insert_drive_file_outlined;
    String label = 'Arquivo';
    if (tipo == 'VIDEO') {
      icon = Icons.play_circle_outline;
      label = 'Video';
    } else if (tipo == 'AUDIO') {
      icon = Icons.graphic_eq_outlined;
      label = 'Audio';
    }

    final textColor =
        mine
            ? Colors.white
            : (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary);

    if (tipo == 'AUDIO') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ConversationAudioInlinePlayer(
          url: url,
          label: msg.conteudo.replaceFirst('Audio ', ''),
          mine: mine,
          isDark: isDark,
          onFallbackOpen: onOpen,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                mine
                    ? Colors.white.withValues(alpha: 0.12)
                    : primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Toque para abrir',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.72),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, color: textColor, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class ConversationMediaFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color primary;
  final bool isDark;

  const ConversationMediaFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink =
        selected
            ? Colors.white
            : (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color:
                selected
                    ? primary
                    : (isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  selected
                      ? primary
                      : (isDark
                          ? EagleTokens.darkLine
                          : TokensStrip.borderDefault),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class ConversationMediaGalleryTile extends StatelessWidget {
  final ChatMsg msg;
  final bool isDark;
  final VoidCallback onTap;

  const ConversationMediaGalleryTile({
    super.key,
    required this.msg,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = msg.primaryMediaType;
    final title = _title(tipo);
    final icon = _icon(tipo);
    final url = msg.primaryMediaUrl;
    final isImage = tipo == 'IMAGE';
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final muted = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: fxListCardDecoration(context, accent: primary),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 54,
                height: 54,
                color: primary.withValues(alpha: 0.10),
                child:
                    isImage && url != null && url.isNotEmpty
                        ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Icon(
                                Icons.broken_image_outlined,
                                color: primary,
                              ),
                        )
                        : Icon(icon, color: primary, size: 26),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_sender(msg.remetente)} - ${_dateLabel(msg.enviadoEm)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: muted),
          ],
        ),
      ),
    );
  }

  static IconData _icon(String? tipo) {
    if (tipo == 'VIDEO') return Icons.play_circle_outline_rounded;
    if (tipo == 'AUDIO') return Icons.graphic_eq_rounded;
    return Icons.image_outlined;
  }

  static String _title(String? tipo) {
    if (tipo == 'VIDEO') return 'Video';
    if (tipo == 'AUDIO') return 'Audio';
    return 'Foto';
  }

  static String _sender(String remetente) {
    if (remetente == 'PERSONAL') return 'Personal';
    if (remetente == 'ALUNO') return 'Aluno';
    return remetente;
  }

  static String _dateLabel(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class ConversationAudioInlinePlayer extends StatefulWidget {
  final String url;
  final String label;
  final bool mine;
  final bool isDark;
  final VoidCallback onFallbackOpen;

  const ConversationAudioInlinePlayer({
    super.key,
    required this.url,
    required this.label,
    required this.mine,
    required this.isDark,
    required this.onFallbackOpen,
  });

  @override
  State<ConversationAudioInlinePlayer> createState() =>
      _ConversationAudioInlinePlayerState();
}

class _ConversationAudioInlinePlayerState
    extends State<ConversationAudioInlinePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _loaded = false;
  bool _busy = false;

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) return;
    if (_player.playing) {
      await _player.pause();
      return;
    }

    setState(() => _busy = true);
    try {
      if (!_loaded) {
        await _player.setUrl(widget.url);
        _loaded = true;
      }
      await _player.play();
    } catch (_) {
      widget.onFallbackOpen();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg =
        widget.mine
            ? Colors.white.withValues(alpha: 0.12)
            : primary.withValues(alpha: 0.10);
    final ink =
        widget.mine
            ? Colors.white
            : (widget.isDark ? EagleTokens.darkInk : TokensStrip.textPrimary);
    final muted = ink.withValues(alpha: 0.70);
    final name = widget.label.trim().isEmpty ? 'Audio' : widget.label.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            StreamBuilder<PlayerState>(
              stream: _player.playerStateStream,
              builder: (context, snapshot) {
                final processing =
                    snapshot.data?.processingState ?? ProcessingState.idle;
                final loading = _busy || processing == ProcessingState.loading;
                final playing = snapshot.data?.playing ?? false;
                return IconButton(
                  tooltip: playing ? 'Pausar audio' : 'Reproduzir audio',
                  visualDensity: VisualDensity.compact,
                  onPressed: loading ? null : _toggle,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        widget.mine
                            ? Colors.white.withValues(alpha: 0.18)
                            : primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(36, 36),
                  ),
                  icon:
                      loading
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: FxLoading(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StreamBuilder<Duration?>(
                stream: _player.durationStream,
                builder: (context, durationSnapshot) {
                  final duration = durationSnapshot.data;
                  return StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (context, positionSnapshot) {
                      final position = positionSnapshot.data ?? Duration.zero;
                      final totalMs = duration?.inMilliseconds ?? 0;
                      final progress =
                          totalMs <= 0
                              ? 0.0
                              : (position.inMilliseconds / totalMs).clamp(
                                0.0,
                                1.0,
                              );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 4,
                              value: progress,
                              backgroundColor: ink.withValues(alpha: 0.16),
                              valueColor: AlwaysStoppedAnimation<Color>(ink),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${_audioTime(position)} / ${_audioTime(duration)}',
                            style: TextStyle(color: muted, fontSize: 11),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Abrir anexo',
              visualDensity: VisualDensity.compact,
              onPressed: widget.onFallbackOpen,
              icon: Icon(Icons.open_in_new_rounded, color: muted, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  static String _audioTime(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
