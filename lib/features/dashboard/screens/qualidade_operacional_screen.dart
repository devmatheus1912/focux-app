import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class QualidadeOperacionalData {
  final double ticketPessoal;
  final double ticketMercado;
  final int retencaoPessoal;
  final int retencaoMercado;
  final int score;
  final String recomendacao;

  QualidadeOperacionalData({
    required this.ticketPessoal,
    required this.ticketMercado,
    required this.retencaoPessoal,
    required this.retencaoMercado,
    required this.score,
    required this.recomendacao,
  });

  factory QualidadeOperacionalData.fromJson(Map<String, dynamic> j) => QualidadeOperacionalData(
        ticketPessoal: (j['ticketPessoal'] as num).toDouble(),
        ticketMercado: (j['ticketMercado'] as num).toDouble(),
        retencaoPessoal: j['retencaoPessoal'],
        retencaoMercado: j['retencaoMercado'],
        score: j['score'],
        recomendacao: j['recomendacao'],
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final qualidadeProvider = FutureProvider<QualidadeOperacionalData>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.dio.get('/api/dashboard/qualidade');
  return QualidadeOperacionalData.fromJson(res.data as Map<String, dynamic>);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class QualidadeOperacionalScreen extends ConsumerWidget {
  const QualidadeOperacionalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(qualidadeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qualidade Operacional'),
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e', style: const TextStyle(color: Colors.red))),
        data: (data) => _QualidadeBody(data: data),
      ),
    );
  }
}

class _QualidadeBody extends StatelessWidget {
  final QualidadeOperacionalData data;
  
  const _QualidadeBody({required this.data});

  Color get _scoreColor {
    if (data.score >= 80) return const Color(0xFF22C55E);
    if (data.score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header com o Score Geral
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_scoreColor.withOpacity(0.8), _scoreColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Focux Score™', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '${data.score}/100',
                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data.recomendacao,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Ticket Médio Comparativo
          const Text('Precificação (Ticket Médio)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ComparativoCard(
            labelSua: 'Seu Ticket',
            valorSua: 'R\$ ${data.ticketPessoal.toStringAsFixed(2)}',
            labelMercado: 'Mercado Focux',
            valorMercado: 'R\$ ${data.ticketMercado.toStringAsFixed(2)}',
            acimaDoMercado: data.ticketPessoal >= data.ticketMercado,
          ),
          const SizedBox(height: 24),
          
          // Retenção Comparativa
          const Text('Saúde da Base (Retenção)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ComparativoCard(
            labelSua: 'Sua Retenção',
            valorSua: '${data.retencaoPessoal}%',
            labelMercado: 'Mercado Focux',
            valorMercado: '${data.retencaoMercado}%',
            acimaDoMercado: data.retencaoPessoal >= data.retencaoMercado,
          ),
          
          const SizedBox(height: 32),
          const Text(
            'Nota: O Mercado Focux é baseado na média de todos os personais da plataforma (dados anonimizados).',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ComparativoCard extends StatelessWidget {
  final String labelSua;
  final String valorSua;
  final String labelMercado;
  final String valorMercado;
  final bool acimaDoMercado;

  const _ComparativoCard({
    required this.labelSua,
    required this.valorSua,
    required this.labelMercado,
    required this.valorMercado,
    required this.acimaDoMercado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(labelSua, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(valorSua, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      if (acimaDoMercado)
                        const Icon(Icons.arrow_upward, color: Colors.green, size: 20)
                      else
                        const Icon(Icons.arrow_downward, color: Colors.orange, size: 20),
                    ],
                  ),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(labelMercado, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(valorMercado, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
