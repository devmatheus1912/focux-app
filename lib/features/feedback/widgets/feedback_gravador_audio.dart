import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../chat/widgets/conversation_media_widgets.dart';
import '../utils/feedback_video_display.dart';

/// Áudio gravado para a correção (arquivo local e duração).
class GravacaoDeAudio {
  const GravacaoDeAudio({required this.path, required this.segundos});

  final String path;
  final int segundos;
}

/// Grava a correção por voz (até [limite]), mostra a prévia com play e lixeira.
/// O resultado sai em [gravacao], que a folha também ouve para ligar o botão.
class FeedbackGravadorAudio extends StatefulWidget {
  const FeedbackGravadorAudio({
    super.key,
    required this.gravacao,
    this.limite = const Duration(minutes: 2),
  });

  final ValueNotifier<GravacaoDeAudio?> gravacao;
  final Duration limite;

  @override
  State<FeedbackGravadorAudio> createState() => _FeedbackGravadorAudioState();
}

class _FeedbackGravadorAudioState extends State<FeedbackGravadorAudio> {
  final _recorder = AudioRecorder();
  Timer? _relogio;
  DateTime? _inicio;
  var _gravando = false;

  @override
  void dispose() {
    _relogio?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _gravar() async {
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          FeedbackHelper.showError(context, 'Permita o microfone para gravar.');
        }
        return;
      }
      final nome = 'correcao_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final path =
          kIsWeb ? nome : '${(await getTemporaryDirectory()).path}/$nome';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 96000,
          sampleRate: 44100,
        ),
        path: path,
      );
      HapticFeedback.mediumImpact();
      setState(() {
        _gravando = true;
        _inicio = DateTime.now();
      });
      _relogio = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_passou >= widget.limite) {
          _parar();
        } else {
          setState(() {});
        }
      });
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Não foi possível gravar agora.'),
        );
      }
    }
  }

  Duration get _passou =>
      _inicio == null ? Duration.zero : DateTime.now().difference(_inicio!);

  Future<void> _parar() async {
    _relogio?.cancel();
    final segundos = _passou.inSeconds;
    final path = await _recorder.stop();
    if (!mounted) return;
    setState(() => _gravando = false);
    if (path == null || segundos < 1) return;
    widget.gravacao.value = GravacaoDeAudio(path: path, segundos: segundos);
  }

  void _apagar() {
    final atual = widget.gravacao.value;
    widget.gravacao.value = null;
    if (atual != null && !kIsWeb) {
      unawaited(File(atual.path).delete().then((_) {}, onError: (_) {}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return ValueListenableBuilder<GravacaoDeAudio?>(
      valueListenable: widget.gravacao,
      builder: (context, gravado, _) {
        if (gravado != null) {
          return Row(
            children: [
              Expanded(
                child: ConversationAudioInlinePlayer(
                  url: Uri.file(gravado.path).toString(),
                  recordedDuration: Duration(seconds: gravado.segundos),
                  mine: true,
                  isDark: chrome.isDark,
                  onFallbackOpen: () {},
                ),
              ),
              IconButton(
                tooltip: 'Apagar áudio',
                onPressed: _apagar,
                icon: Icon(FxIcons.excluir, color: chrome.mute),
              ),
            ],
          );
        }
        if (_gravando) {
          return Row(
            children: [
              Icon(FxIcons.microfone, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: TokensStrip.s2),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    'Gravando · ${feedbackAudioDuracao(_passou.inSeconds)}',
                    style: FocuxHubTypography.body(color: chrome.ink),
                  ),
                ),
              ),
              FxTonalButton(label: 'Parar', onPressed: _parar, compact: true),
            ],
          );
        }
        return Align(
          alignment: Alignment.centerLeft,
          child: FxTonalButton(
            label: 'Gravar áudio',
            icon: FxIcons.microfone,
            onPressed: _gravar,
            compact: true,
          ),
        );
      },
    );
  }
}
