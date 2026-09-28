import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Fim do descanso com o app aberto: vibra e toca um bipe curto.
abstract interface class CheckinDescansoAlerta {
  Future<void> tocar();
}

final checkinDescansoAlertaProvider =
    Provider.autoDispose<CheckinDescansoAlerta>((ref) {
      final alerta = _CheckinDescansoAlertaPadrao();
      ref.onDispose(alerta.dispose);
      return alerta;
    });

class _CheckinDescansoAlertaPadrao implements CheckinDescansoAlerta {
  static const _asset = 'assets/sounds/descanso_fim.wav';

  AudioPlayer? _player;
  bool _carregado = false;

  @override
  Future<void> tocar() async {
    await HapticFeedback.heavyImpact();
    await HapticFeedback.vibrate();
    try {
      final player = _player ??= await _criarPlayer();
      if (!_carregado) {
        await player.setAsset(_asset);
        _carregado = true;
      }
      await player.seek(Duration.zero);
      if (!player.playing) unawaited(player.play());
    } catch (_) {
      // Sem som ainda vibra; o bipe nunca derruba a execução.
    }
  }

  /// iOS em `ambient` mistura com a música do aluno; sem ativar a sessão, o
  /// Android não pede foco de áudio e a música não pausa.
  Future<AudioPlayer> _criarPlayer() async {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.ambient,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
      ),
    );
    return AudioPlayer(
      handleInterruptions: false,
      handleAudioSessionActivation: false,
    );
  }

  void dispose() => _player?.dispose();
}
