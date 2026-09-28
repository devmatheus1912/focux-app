import 'package:dio/dio.dart';

import '../data/checkin_repository.dart';
import '../data/checkin_series_pendentes.dart';

/// Sem resposta do servidor: a série vai para a fila em vez de sumir.
bool checkinErroDeConexao(Object erro) {
  if (erro is! DioException || erro.response != null) return false;
  return switch (erro.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => true,
    _ => false,
  };
}

/// Vale tentar de novo depois; só recusa definitiva (4xx) descarta a série.
bool checkinErroTransitorio(Object erro) {
  if (checkinErroDeConexao(erro)) return true;
  if (erro is! DioException) return false;
  final status = erro.response?.statusCode ?? 0;
  return status >= 500 || status == 401 || status == 408 || status == 429;
}

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
      if (checkinErroTransitorio(e)) break;
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
