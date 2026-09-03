import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

class QualidadeOperacionalData {
  const QualidadeOperacionalData({
    required this.ticketPessoal,
    required this.ticketMercado,
    required this.retencaoPessoal,
    required this.retencaoMercado,
    required this.score,
    required this.recomendacao,
  });

  final double ticketPessoal;
  final double ticketMercado;
  final int retencaoPessoal;
  final int retencaoMercado;
  final int score;
  final String recomendacao;

  bool get isEmpty => ticketPessoal <= 0 && retencaoPessoal <= 0;

  factory QualidadeOperacionalData.fromJson(Map<String, dynamic> j) =>
      QualidadeOperacionalData(
        ticketPessoal: (j['ticketPessoal'] as num).toDouble(),
        ticketMercado: (j['ticketMercado'] as num).toDouble(),
        retencaoPessoal: (j['retencaoPessoal'] as num).toInt(),
        retencaoMercado: (j['retencaoMercado'] as num).toInt(),
        score: (j['score'] as num).toInt(),
        recomendacao: j['recomendacao'] as String? ?? '',
      );
}

final qualidadeProvider = FutureProvider<QualidadeOperacionalData>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.dio.get('/api/dashboard/qualidade');
  return QualidadeOperacionalData.fromJson(res.data as Map<String, dynamic>);
});
