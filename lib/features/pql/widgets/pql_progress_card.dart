import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../data/pql_repository.dart';

final pqlRepoProvider = Provider(
  (ref) => PqlRepository(ref.read(apiClientProvider)),
);

final pqlSnapshotProvider = FutureProvider<PqlSnapshot>(
  (ref) => ref.read(pqlRepoProvider).me(),
);

/// Card de progresso de ativação (PQL) — incentiva o personal a percorrer
/// os passos que comprovadamente convertem em conversão paga.
class PqlProgressCard extends ConsumerWidget {
  const PqlProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(pqlSnapshotProvider);
    return snap.when(
      data: (s) => _Body(snapshot: s),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.snapshot});
  final PqlSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot.score >= 90) return const SizedBox.shrink();

    final passos = _passos();
    final feitos = passos.where((p) => snapshot.eventos.contains(p.tipo)).length;
    final total = passos.length;
    final pct = total == 0 ? 0.0 : feitos / total;
    final theme = Theme.of(context);
    final color = _classificacaoColor(snapshot.classificacao, theme);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      elevation: 0,
      color: color.withOpacity(.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch_outlined, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ativação Focux  ·  $feitos/$total etapas',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${snapshot.score} pts',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: color.withOpacity(.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 12),
            ..._proximasEtapas(passos).take(2).map(
                  (p) => _Step(
                    feito: snapshot.eventos.contains(p.tipo),
                    label: p.label,
                    rota: p.rota,
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Color _classificacaoColor(String c, ThemeData t) {
    return switch (c) {
      'PRIORIDADE' => Colors.green.shade700,
      'PQL' => Colors.teal.shade700,
      'NURTURE' => Colors.indigo.shade600,
      _ => t.colorScheme.primary,
    };
  }

  List<_PqlPasso> _proximasEtapas(List<_PqlPasso> p) =>
      p.where((x) => !snapshot.eventos.contains(x.tipo)).toList();

  List<_PqlPasso> _passos() => const [
        _PqlPasso('PRIMEIRO_ALUNO', 'Cadastre seu 1º aluno', '/alunos/novo'),
        _PqlPasso('PRIMEIRO_TREINO', 'Crie seu 1º treino', '/treinos'),
        _PqlPasso('PRIMEIRA_MENSALIDADE', 'Lance sua 1ª mensalidade', '/financeiro'),
        _PqlPasso('PRIMEIRO_HABITO', 'Crie um hábito para seus alunos', '/habitos'),
        _PqlPasso('PRIMEIRO_PACOTE', 'Monte seu 1º pacote', '/pacotes'),
        _PqlPasso('PRIMEIRA_IA', 'Use a IA Copiloto', '/ia'),
      ];
}

class _PqlPasso {
  const _PqlPasso(this.tipo, this.label, this.rota);
  final String tipo;
  final String label;
  final String rota;
}

class _Step extends StatelessWidget {
  const _Step({required this.feito, required this.label, required this.rota});
  final bool feito;
  final String label;
  final String rota;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: feito ? null : () => context.push(rota),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(
              feito ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: feito ? Colors.green.shade600 : theme.colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration: feito ? TextDecoration.lineThrough : null,
                  color: feito ? theme.colorScheme.outline : null,
                ),
              ),
            ),
            if (!feito)
              Icon(Icons.chevron_right,
                  size: 18, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
