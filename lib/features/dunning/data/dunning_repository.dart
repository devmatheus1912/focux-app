import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class DunningSnapshot {
  final int total;
  final int abertas;
  final int recuperadas;
  final double recoveryRate;

  DunningSnapshot({
    required this.total,
    required this.abertas,
    required this.recuperadas,
    required this.recoveryRate,
  });

  factory DunningSnapshot.fromJson(Map<String, dynamic> j) => DunningSnapshot(
    total: (j['total'] as num?)?.toInt() ?? 0,
    abertas: (j['abertas'] as num?)?.toInt() ?? 0,
    recuperadas: (j['recuperadas'] as num?)?.toInt() ?? 0,
    recoveryRate: (j['recoveryRate'] as num?)?.toDouble() ?? 0,
  );
}

class DunningFalha {
  final int id;
  final int? alunoId;
  final String contexto;
  final String? motivo;
  final double? valor;
  final int tentativa;
  final DateTime? criadoEm;

  DunningFalha({
    required this.id,
    this.alunoId,
    required this.contexto,
    this.motivo,
    this.valor,
    required this.tentativa,
    this.criadoEm,
  });

  factory DunningFalha.fromJson(Map<String, dynamic> j) => DunningFalha(
    id: (j['id'] as num).toInt(),
    alunoId: (j['alunoId'] as num?)?.toInt(),
    contexto: j['contexto'] as String? ?? '',
    motivo: j['motivo'] as String?,
    valor: (j['valor'] as num?)?.toDouble(),
    tentativa: (j['tentativa'] as num?)?.toInt() ?? 0,
    criadoEm:
        j['criadoEm'] != null
            ? DateTime.tryParse(j['criadoEm'].toString())
            : null,
  );
}

class DunningHomeBundle {
  final DunningSnapshot snapshot;
  final List<DunningFalha> falhas;

  const DunningHomeBundle({required this.snapshot, required this.falhas});

  factory DunningHomeBundle.fromJson(Map<String, dynamic> j) {
    final snapshotJson = j['snapshot'];
    return DunningHomeBundle(
      snapshot:
          snapshotJson is Map<String, dynamic>
              ? DunningSnapshot.fromJson(snapshotJson)
              : DunningSnapshot(
                total: 0,
                abertas: 0,
                recuperadas: 0,
                recoveryRate: 0,
              ),
      falhas:
          ((j['falhas'] as List?) ?? const [])
              .map((e) => DunningFalha.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class DunningRepository {
  final Dio _dio;

  DunningRepository(ApiClient client) : _dio = client.dio;

  /// BFF tipado — first paint da tela Dunning (snapshot + falhas).
  Future<DunningHomeBundle> getHome() async {
    final r = await _dio.get('/api/dunning/home');
    return DunningHomeBundle.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> marcarRecuperado(int falhaId) async {
    await _dio.post('/api/dunning/$falhaId/recuperado');
  }
}
