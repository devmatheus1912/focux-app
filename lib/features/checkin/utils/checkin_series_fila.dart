import 'package:dio/dio.dart';

import '../../../core/api/transient_error.dart';
import '../data/checkin_repository.dart';
import '../data/checkin_series_pendentes.dart';

typedef CheckinEnvioSerie =
    Future<ExecucaoExercicio> Function(CheckinSeriePendente serie);

/// Mesmo envio para a série nova e para a reenviada pela fila.
CheckinEnvioSerie checkinEnvioPelo(CheckinRepository repo) =>
    (p) => repo.registrarSerie(
      p.execucaoId,
      p.treinoExercicioId,
      numero: p.numero,
      cargaKg: p.cargaKg,
      repeticoes: p.repeticoes,
      feedback: p.feedback,
      rpe: p.rpe,
      dor: p.dor,
    );

sealed class CheckinRegistro {
  const CheckinRegistro();
}

class CheckinRegistroSalvo extends CheckinRegistro {
  const CheckinRegistroSalvo(this.exercicio);
  final ExecucaoExercicio exercicio;
}

/// Guardada no aparelho: conta como feita até a fila enviar.
class CheckinRegistroNaFila extends CheckinRegistro {
  const CheckinRegistroNaFila(this.fila);
  final List<CheckinSeriePendente> fila;
}

/// Recusa definitiva (validação ou sessão encerrada): nada foi salvo, nem
/// no aparelho.
class CheckinRegistroRecusado extends CheckinRegistro {
  const CheckinRegistroRecusado(this.erro);
  final Object erro;
}

/// `true` enquanto o aparelho ainda tem sessão (token) do usuário.
typedef CheckinSessaoAtiva = Future<bool> Function();

/// Série nova: mesma classificação de erro da fila, para que o que a fila
/// tentaria de novo também não se perca no primeiro envio. Sem sessão no
/// aparelho (401 após refresh falho, logout) a série de saúde não fica
/// gravada: é recusa.
Future<CheckinRegistro> checkinRegistrarSerie({
  required CheckinSeriePendente serie,
  required CheckinSeriesPendentesStore store,
  required CheckinEnvioSerie enviar,
  required CheckinSessaoAtiva sessaoAtiva,
}) async {
  try {
    return CheckinRegistroSalvo(await enviar(serie));
  } catch (e) {
    if (!isTransientApiError(e)) return CheckinRegistroRecusado(e);
    try {
      if (_status(e) == 401 && !await sessaoAtiva()) {
        return CheckinRegistroRecusado(e);
      }
      await store.adicionar(serie);
      // Logout concorrente pode ter limpado a fila antes desta gravação.
      if (!await sessaoAtiva()) {
        await store.remover(serie);
        return CheckinRegistroRecusado(e);
      }
      return CheckinRegistroNaFila(await store.ler());
    } catch (_) {
      return CheckinRegistroRecusado(e);
    }
  }
}

int? _status(Object e) => e is DioException ? e.response?.statusCode : null;

class CheckinFilaResultado {
  const CheckinFilaResultado({
    required this.enviadas,
    required this.rejeitadas,
    required this.restantes,
  });

  final List<({int execucaoId, ExecucaoExercicio exercicio})> enviadas;

  /// Recusadas pelo servidor (4xx): saem da fila.
  final int rejeitadas;
  final List<CheckinSeriePendente> restantes;
}

/// Envia na ordem de registro. Para no primeiro erro transitório.
Future<CheckinFilaResultado> checkinEnviarFila({
  required CheckinSeriesPendentesStore store,
  required CheckinEnvioSerie enviar,
}) async {
  final fila = await store.ler();
  final enviadas = <({int execucaoId, ExecucaoExercicio exercicio})>[];
  var rejeitadas = 0;
  for (final serie in fila) {
    try {
      final exercicio = await enviar(serie);
      await store.remover(serie);
      enviadas.add((execucaoId: serie.execucaoId, exercicio: exercicio));
    } catch (e) {
      if (isTransientApiError(e)) break;
      await store.remover(serie);
      rejeitadas++;
    }
  }
  return CheckinFilaResultado(
    enviadas: enviadas,
    rejeitadas: rejeitadas,
    restantes: await store.ler(),
  );
}
