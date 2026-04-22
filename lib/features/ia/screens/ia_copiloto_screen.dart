import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/ia_repository.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final resumoSemanalProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return IaRepository(ref.read(apiClientProvider)).resumoSemanal();
});

final insightsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return IaRepository(ref.read(apiClientProvider)).insights();
});

// ─── Tela ─────────────────────────────────────────────────────────────────────

class IaCopilotoScreen extends ConsumerStatefulWidget {
  const IaCopilotoScreen({super.key});

  @override
  ConsumerState<IaCopilotoScreen> createState() => _IaCopilotoScreenState();
}

class _IaCopilotoScreenState extends ConsumerState<IaCopilotoScreen> {
  final _alunoIdCtrl = TextEditingController();
  Map<String, dynamic>? _proximaAcaoData;
  bool _buscandoAcao = false;

  @override
  void dispose() {
    _alunoIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarProximaAcao() async {
    final idText = _alunoIdCtrl.text.trim();
    final id = int.tryParse(idText);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um ID de aluno válido.')));
      return;
    }
    setState(() { _buscandoAcao = true; _proximaAcaoData = null; });
    try {
      final data = await IaRepository(ref.read(apiClientProvider)).proximaAcao(id);
      if (mounted) setState(() => _proximaAcaoData = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _buscandoAcao = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumoAsync = ref.watch(resumoSemanalProvider);
    final insightsAsync = ref.watch(insightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Copiloto IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(resumoSemanalProvider);
              ref.invalidate(insightsProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── Resumo Semanal ──────────────────────────────────────────────
          Text('Resumo Semanal', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          resumoAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Erro ao carregar resumo: $e',
                    style: const TextStyle(color: EagleTokens.bad)),
              ),
            ),
            data: (resumo) => _CardResumoSemanal(resumo: resumo),
          ),

          const SizedBox(height: 24),

          // ── Insights ────────────────────────────────────────────────────
          Text('Insights IA', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          insightsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erro ao carregar insights: $e',
                style: const TextStyle(color: EagleTokens.bad)),
            data: (lista) {
              if (lista.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('Nenhum insight disponível.')),
                );
              }
              return Column(
                children: lista.map((i) => _CardInsight(insight: i)).toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Próxima Ação ─────────────────────────────────────────────────
          Text('Próxima Ação', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _alunoIdCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ID do Aluno',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: 42',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _buscandoAcao ? null : _buscarProximaAcao,
                    child: _buscandoAcao
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Buscar'),
                  ),
                ]),
                if (_proximaAcaoData != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _CardProximaAcao(data: _proximaAcaoData!),
                ],
              ]),
            ),
          ),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ─── Card Resumo Semanal ──────────────────────────────────────────────────────

class _CardResumoSemanal extends StatelessWidget {
  final Map<String, dynamic> resumo;
  const _CardResumoSemanal({required this.resumo});

  @override
  Widget build(BuildContext context) {
    final texto = resumo['resumo'] as String? ?? '—';
    final totalAlunos = resumo['totalAlunos'] ?? 0;
    final emRisco = resumo['alunosEmRisco'] ?? 0;
    final treinosSemana = resumo['treinosSemana'] ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(texto, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 8, children: [
            _ChipInfo(
              label: 'Total Alunos',
              valor: totalAlunos.toString(),
              cor: EagleTokens.brand,
            ),
            _ChipInfo(
              label: 'Em Risco',
              valor: emRisco.toString(),
              cor: EagleTokens.bad,
            ),
            _ChipInfo(
              label: 'Treinos Semana',
              valor: treinosSemana.toString(),
              cor: EagleTokens.good,
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── Card Insight ─────────────────────────────────────────────────────────────

class _CardInsight extends StatelessWidget {
  final Map<String, dynamic> insight;
  const _CardInsight({required this.insight});

  Color _cor(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'RISCO': return EagleTokens.bad;
      case 'ENGAJAMENTO': return EagleTokens.brand;
      case 'OPORTUNIDADE': return EagleTokens.good;
      default: return EagleTokens.inkMute;
    }
  }

  IconData _icone(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'RISCO': return Icons.warning_amber_rounded;
      case 'ENGAJAMENTO': return Icons.bolt;
      case 'OPORTUNIDADE': return Icons.lightbulb_outline;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipo = insight['tipo'] as String? ?? '';
    final descricao = insight['descricao'] as String? ?? '';
    final recomendacao = insight['recomendacao'] as String? ?? '';
    final cor = _cor(tipo);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_icone(tipo), color: cor, size: 18),
            const SizedBox(width: 6),
            Chip(
              label: Text(tipo.toUpperCase(),
                  style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w600)),
              backgroundColor: cor.withValues(alpha: 0.1),
              side: BorderSide(color: cor.withValues(alpha: 0.3)),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ]),
          const SizedBox(height: 8),
          Text(descricao, style: const TextStyle(fontSize: 13)),
          if (recomendacao.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.arrow_forward_ios, size: 12, color: EagleTokens.inkMute),
              const SizedBox(width: 4),
              Expanded(
                child: Text(recomendacao,
                    style: const TextStyle(fontSize: 12, color: EagleTokens.inkMute)),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ─── Card Próxima Ação ────────────────────────────────────────────────────────

class _CardProximaAcao extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CardProximaAcao({required this.data});

  @override
  Widget build(BuildContext context) {
    final nome = data['alunoNome'] as String? ?? 'Aluno';
    final acao = data['acao'] as String? ?? '—';
    final motivo = data['motivo'] as String? ?? '';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(height: 6),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.play_arrow, size: 18, color: EagleTokens.good),
        const SizedBox(width: 4),
        Expanded(child: Text(acao, style: const TextStyle(fontSize: 13))),
      ]),
      if (motivo.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(motivo, style: const TextStyle(fontSize: 12, color: EagleTokens.inkMute)),
      ],
    ]);
  }
}

// ─── Chip Info ────────────────────────────────────────────────────────────────

class _ChipInfo extends StatelessWidget {
  final String label, valor;
  final Color cor;
  const _ChipInfo({required this.label, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(valor,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cor)),
        Text(label, style: const TextStyle(fontSize: 11, color: EagleTokens.inkMute)),
      ]),
    );
  }
}
