import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/checkin_series_pendentes.dart';
import '../providers/checkin_provider.dart';
import '../utils/checkin_series_fila.dart';

/// Único dono do reenvio da fila de séries. A tela de execução e o app
/// dividem a mesma rodada, então a mesma série nunca sobe duas vezes junto.
class CheckinFilaSync {
  CheckinFilaSync(this._ref);

  final Ref _ref;
  static const store = CheckinSeriesPendentesStore();
  final _rodadas = StreamController<CheckinFilaResultado>.broadcast();
  Future<CheckinFilaResultado>? _emVoo;

  /// Toda rodada concluída, para quem reage fora dela (caches, aviso).
  Stream<CheckinFilaResultado> get rodadas => _rodadas.stream;

  /// Quem chamar durante uma rodada recebe o resultado dela.
  Future<CheckinFilaResultado> enviar() =>
      _emVoo ??= _rodada().whenComplete(() => _emVoo = null);

  Future<CheckinFilaResultado> _rodada() async {
    final r = await checkinEnviarFila(
      store: store,
      enviar: checkinEnvioPelo(_ref.read(checkinRepositoryProvider)),
    );
    if (!_rodadas.isClosed) _rodadas.add(r);
    return r;
  }

  void dispose() => _rodadas.close();
}

final checkinFilaSyncProvider = Provider<CheckinFilaSync>((ref) {
  final sync = CheckinFilaSync(ref);
  ref.onDispose(sync.dispose);
  return sync;
});
