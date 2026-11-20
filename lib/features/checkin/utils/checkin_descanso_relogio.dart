import 'dart:async';

import 'checkin_execucao_display.dart';

/// Descanso contado pelo horário de fim, então pausa do app não o atrasa.
class CheckinDescansoRelogio {
  CheckinDescansoRelogio({
    required this.agora,
    required this.onTick,
    required this.onFim,
    this.aoMudarFim,
    this.emPrimeiroPlano,
  });

  /// Fim do descanso mudou (nulo = acabou ou foi pulado): agenda ou cancela o
  /// aviso com a tela bloqueada (SPEC-notificacoes).
  final void Function(DateTime? fim)? aoMudarFim;

  /// No fim natural com o app em segundo plano o aviso agendado fica: é ele
  /// que avisa. Com o app aberto, cancela e vale o bipe.
  final bool Function()? emPrimeiroPlano;

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
    aoMudarFim?.call(_fim);
  }

  /// Soma ou tira segundos do descanso em andamento (mínimo 5 s, máx. 10 min).
  /// Tirar além do que resta encerra o descanso, sem tocar o aviso de fim.
  void ajustar(int delta) {
    final fim = _fim;
    if (!ativo || fim == null) return;
    _fim = fim.add(Duration(seconds: delta));
    total = (total + delta).clamp(5, 600).toInt();
    _conferir(avisar: false);
    if (ativo) aoMudarFim?.call(_fim);
  }

  /// Pular, terminar ou descartar: cancela também o aviso agendado.
  void parar() => _encerrar(cancelarAviso: true);

  void _encerrar({required bool cancelarAviso}) {
    final estava = ativo;
    _timer?.cancel();
    ativo = false;
    if (estava && cancelarAviso) aoMudarFim?.call(null);
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
    // Fim pelo relógio: em segundo plano o aviso agendado é quem avisa.
    _encerrar(cancelarAviso: !avisar || (emPrimeiroPlano?.call() ?? true));
    onTick();
    if (avisar) onFim();
  }

  void dispose() => _timer?.cancel();
}
