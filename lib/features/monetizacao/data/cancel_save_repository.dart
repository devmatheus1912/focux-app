import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';

final cancelSaveRepositoryProvider = Provider<CancelSaveRepository>(
  (ref) => CancelSaveRepository(ref.read(apiClientProvider)),
);

class CancelSaveOferta {
  final String tipo;
  final String titulo;
  final String descricao;
  final String ctaLabel;
  final String billingChannel;
  final bool requiresStoreAction;

  CancelSaveOferta({
    required this.tipo,
    required this.titulo,
    required this.descricao,
    required this.ctaLabel,
    required this.billingChannel,
    required this.requiresStoreAction,
  });

  factory CancelSaveOferta.fromJson(Map<String, dynamic> j) => CancelSaveOferta(
    tipo: j['tipo'] as String? ?? '',
    titulo: j['titulo'] as String? ?? '',
    descricao: j['descricao'] as String? ?? '',
    ctaLabel: j['ctaLabel'] as String? ?? 'Aceitar oferta',
    billingChannel: j['billingChannel'] as String? ?? 'MERCADO_PAGO',
    requiresStoreAction: j['requiresStoreAction'] as bool? ?? false,
  );
}

class CancelSaveResposta {
  final bool aceita;
  final String mensagem;
  final bool billingApplied;
  final bool requiresStoreAction;

  CancelSaveResposta({
    required this.aceita,
    required this.mensagem,
    this.billingApplied = false,
    this.requiresStoreAction = false,
  });

  factory CancelSaveResposta.fromJson(Map<String, dynamic> j) =>
      CancelSaveResposta(
        aceita: j['aceita'] as bool? ?? false,
        mensagem: (j['mensagem'] as String?)?.trim() ?? '',
        billingApplied: j['billingApplied'] as bool? ?? false,
        requiresStoreAction: j['requiresStoreAction'] as bool? ?? false,
      );
}

class CancelSaveRepository {
  final Dio _dio;
  CancelSaveRepository(ApiClient c) : _dio = c.dio;

  Future<CancelSaveOferta> oferta(String motivo) async {
    final r = await _dio.get(
      '/api/cancel-save/oferta',
      queryParameters: {'motivo': motivo},
    );
    return CancelSaveOferta.fromJson(r.data as Map<String, dynamic>);
  }

  Future<CancelSaveResposta> responder({
    required String motivo,
    required String ofertaApresentada,
    required bool aceitar,
    String? feedback,
  }) async {
    final r = await _dio.post(
      '/api/cancel-save/responder',
      data: {
        'motivo': motivo,
        'ofertaApresentada': ofertaApresentada,
        'aceitar': aceitar ? 'SIM' : 'NAO',
        if (feedback != null && feedback.trim().isNotEmpty)
          'feedback': feedback.trim(),
      },
    );
    return CancelSaveResposta.fromJson(r.data as Map<String, dynamic>);
  }
}
