import 'dart:async';

import 'checkin_execucao_display.dart';

/// Descanso contado pelo horário de fim, então pausa do app não o atrasa.
class CheckinDescansoRelogio {
  CheckinDescansoRelogio({
    required this.agora,
    required this.onTick,
    required this.onFim,
  });

  final DateTime Function() agora;
  final void Function() onTick;

  /// Só quando o descanso acaba com o app aberto; pular não chama.
  final void Function() onFim;

  Timer? _timer;
  DateTime? _fim;
  bool ativo = false;
  int segundos = 60;
  int total = 60;

  void iniciar(int seconds) {
    _timer?.cancel();
    total = segundos = seconds.clamp(15, 600).toInt();
    _fim = agora().add(Duration(seconds: total));
    ativo = true;
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _conferir(avisar: true),
    );
  }

  void parar() {
    _timer?.cancel();
    ativo = false;
  }

  /// Volta do background: o descanso que acabou lá fora some sem aviso.
  void sincronizar() {
    if (ativo) _conferir(avisar: false);
  }

  void _conferir({required bool avisar}) {
    final fim = _fim;
    if (fim == null) return;
    final left = checkinRestRemaining(endsAt: fim, now: agora());
    if (left > 0) {
      segundos = left;
      onTick();
      return;
    }
    parar();
    onTick();
    if (avisar) onFim();
  }

  void dispose() => _timer?.cancel();
}
