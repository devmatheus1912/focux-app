import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/ia_repository.dart';
import '../../../core/widgets/fx_loading.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final sugestoesProgressaoProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return IaRepository(ref.read(apiClientProvider)).sugestoesProgressao();
});

// ─── Tela ─────────────────────────────────────────────────────────────────────

class ProgressaoAceitarScreen extends ConsumerWidget {
  const ProgressaoAceitarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sugestoesAsync = ref.watch(sugestoesProgressaoProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Progressão de Carga — Sugestões'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(sugestoesProgressaoProvider),
          ),
        ],
      ),
      body: sugestoesAsync.when(
        loading: () => const FxLoading(),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: EagleTokens.bad),
            const SizedBox(height: 12),
            Text('Erro ao carregar sugestões: $e',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(sugestoesProgressaoProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ]),
        ),
        data: (lista) {
          if (lista.isEmpty) {
            return const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_outline, size: 64, color: EagleTokens.good),
                SizedBox(height: 12),
                Text('Nenhuma sugestão pendente.',
                    style: TextStyle(fontSize: 16)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            itemBuilder: (_, i) => _CardSugestao(
              sugestao: lista[i],
              onAceitar: () async {
                await _acao(context, ref, lista[i], aceitar: true);
              },
              onRejeitar: () async {
                await _acao(context, ref, lista[i], aceitar: false);
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _acao(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> sugestao, {
    required bool aceitar,
  }) async {
    final id = sugestao['id'] as int?;
    if (id == null) return;
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      if (aceitar) {
        await repo.aceitarSugestao(id);
      } else {
        await repo.rejeitarSugestao(id);
      }
      ref.invalidate(sugestoesProgressaoProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(aceitar
              ? 'Sugestão aceita e aplicada!'
              : 'Sugestão rejeitada.'),
          backgroundColor: aceitar ? EagleTokens.good : EagleTokens.warn,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')));
      }
    }
  }
}

// ─── Card de Sugestão ─────────────────────────────────────────────────────────

class _CardSugestao extends StatelessWidget {
  final Map<String, dynamic> sugestao;
  final VoidCallback onAceitar;
  final VoidCallback onRejeitar;

  const _CardSugestao({
    required this.sugestao,
    required this.onAceitar,
    required this.onRejeitar,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final alunoNome = sugestao['alunoNome'] as String? ?? 'Aluno';
    final exercicio = sugestao['exercicio'] as String?
        ?? sugestao['exercicioNome'] as String?
        ?? '—';
    final cargaAtual = sugestao['cargaAtual'] ?? sugestao['cargaAtualKg'];
    final cargaSugerida = sugestao['cargaSugerida']
        ?? sugestao['cargaSugeridaKg']
        ?? sugestao['novaCarga'];
    final motivo = sugestao['motivo'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Cabeçalho: nome do aluno
          Row(children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: primary,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(alunoNome,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Exercício
          Text(exercicio,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          // Carga atual → sugerida
          Row(children: [
            _CargaBox(
              label: 'Carga Atual',
              valor: cargaAtual != null ? '${cargaAtual}kg' : '—',
              cor: EagleTokens.inkMute,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.arrow_forward, color: primary),
            ),
            _CargaBox(
              label: 'Sugerido',
              valor: cargaSugerida != null ? '${cargaSugerida}kg' : '—',
              cor: primary,
            ),
          ]),

          // Motivo
          if (motivo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: EagleTokens.inkMute.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.info_outline, size: 14, color: EagleTokens.inkMute),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(motivo,
                      style: const TextStyle(fontSize: 12, color: EagleTokens.inkMute)),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 14),

          // Botões
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRejeitar,
                icon: const Text('❌', style: TextStyle(fontSize: 14)),
                label: const Text('Rejeitar'),
                style: OutlinedButton.styleFrom(foregroundColor: EagleTokens.bad),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onAceitar,
                icon: const Text('✅', style: TextStyle(fontSize: 14)),
                label: const Text('Aceitar'),
                style: FilledButton.styleFrom(backgroundColor: EagleTokens.good),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _CargaBox extends StatelessWidget {
  final String label, valor;
  final Color cor;
  const _CargaBox({required this.label, required this.valor, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text(valor,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: cor)),
        Text(label, style: const TextStyle(fontSize: 10, color: EagleTokens.inkMute)),
      ]),
    );
  }
}
