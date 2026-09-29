import 'dart:async';

/// Intervalo entre drenagens da fila offline com o app em primeiro plano.
const Duration kOfflineDrainInterval = Duration(seconds: 60);

/// Drena a fila offline além do boot e da conectividade: ao voltar ao
/// primeiro plano e em intervalo enquanto houver item pendente. Timeout com o
/// aparelho "online" não gera evento de conectividade, então sem isto a fila
/// ficaria parada até o próximo boot.
///
/// Fila vazia ou app em segundo plano: nenhum timer vivo.
class OfflineDrainScheduler {
  OfflineDrainScheduler({
    required Future<int> Function() pendingCount,
    required Future<void> Function() drain,
    this.interval = kOfflineDrainInterval,
  }) : _pendingCount = pendingCount,
       _drain = drain;

  final Future<int> Function() _pendingCount;
  final Future<void> Function() _drain;
  final Duration interval;

  Timer? _timer;
  Future<void>? _inFlight;
  bool _foreground = true;
  bool _disposed = false;

  bool get hasTimer => _timer != null;

  /// App voltou ao primeiro plano: drena já e religa o intervalo.
  Future<void> onResumed() {
    _foreground = true;
    return _drainIfPending();
  }

  /// App saiu do primeiro plano: nada de timer em background.
  void onBackground() {
    _foreground = false;
    _cancel();
  }

  /// A fila mudou (enfileirou, drenou, limpou): liga ou desliga o intervalo.
  Future<void> onQueueChanged() => _reschedule();

  void dispose() {
    _disposed = true;
    _cancel();
  }

  Future<void> _drainIfPending() {
    return _inFlight ??= _runDrain().whenComplete(() => _inFlight = null);
  }

  Future<void> _runDrain() async {
    if (!_active) return;
    if (await _pendingCount() > 0 && _active) {
      await _drain();
    }
    await _reschedule();
  }

  Future<void> _reschedule() async {
    final pending = _active ? await _pendingCount() : 0;
    if (!_active || pending == 0) {
      _cancel();
      return;
    }
    _timer ??= Timer.periodic(interval, (_) => _drainIfPending());
  }

  bool get _active => _foreground && !_disposed;

  void _cancel() {
    _timer?.cancel();
    _timer = null;
  }
}
