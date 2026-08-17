import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/business_repository.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

final _repoProvider = Provider(
  (ref) => BusinessRepository(ref.read(apiClientProvider)),
);

class BusinessReportsScreen extends ConsumerStatefulWidget {
  const BusinessReportsScreen({super.key});

  @override
  ConsumerState<BusinessReportsScreen> createState() =>
      _BusinessReportsScreenState();
}

class _BusinessReportsScreenState extends ConsumerState<BusinessReportsScreen> {
  BusinessSnapshot? _snapshot;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final s = await ref.read(_repoProvider).snapshot();
      if (!mounted) return;
      setState(() {
        _snapshot = s;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Relatório de Negócio',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Relatório de Negócio',
          subtitle: 'MRR, retenção e saúde financeira',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
        ),
        body:
            _loading
                ? const Center(child: FxLoading())
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: _erro!,
                  onRetry: _carregar,
                )
                : _snapshot == null
                ? FxEmptyState(
                  icon: 'bar-chart-2',
                  title: 'Sem dados do relatório',
                  subtitle: 'Ainda não há métricas de negócio para exibir.',
                  action: FxEmptyAction(
                    label: 'Tentar novamente',
                    onTap: _carregar,
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _carregar,
                  child: _Body(snapshot: _snapshot!),
                ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.snapshot});
  final BusinessSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ndrColor =
        snapshot.ndrPct >= 100
            ? EagleTokens.good
            : snapshot.ndrPct >= 90
            ? EagleTokens.warn
            : EagleTokens.bad;
    return ListView(
      padding: const EdgeInsets.all(TokensStrip.s4),
      children: [
        _MetricCard(
          titulo: 'MRR (Receita recorrente)',
          valor: 'R\$ ${snapshot.mrrAtual.toStringAsFixed(2)}',
          delta:
              'Mês anterior: R\$ ${snapshot.mrrAnterior.toStringAsFixed(2)}  ·  Previsto: R\$ ${snapshot.mrrPrevisto.toStringAsFixed(2)}',
          icon: Icons.attach_money,
          color: EagleTokens.good,
        ),
        _MetricCard(
          titulo: 'NDR (Net Dollar Retention)',
          valor: '${snapshot.ndrPct.toStringAsFixed(1)}%',
          delta:
              snapshot.ndrPct >= 100
                  ? 'Você está expandindo. Mantenha.'
                  : 'Abaixo de 100% = contração. Reduza churn ou suba preço.',
          icon: Icons.trending_up,
          color: ndrColor,
        ),
        Row(
          children: [
            Expanded(
              child: _MiniMetric(
                titulo: 'ARPA',
                valor: 'R\$ ${snapshot.arpa.toStringAsFixed(2)}',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniMetric(
                titulo: 'LTV (proxy)',
                valor: 'R\$ ${snapshot.ltvProxy.toStringAsFixed(2)}',
                icon: Icons.payments_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MiniMetric(
                titulo: 'Alunos ativos',
                valor: '${snapshot.alunosAtivos}/${snapshot.alunosTotal}',
                icon: Icons.group,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniMetric(
                titulo: 'Inadimplentes',
                valor: '${snapshot.inadimplentes}',
                icon: Icons.warning_amber_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _MetricCard(
          titulo: 'Recuperação de Pagamentos (Dunning)',
          valor: '${snapshot.dunningRecoveryPct.toStringAsFixed(1)}%',
          delta:
              '${snapshot.dunningAbertas} falhas em aberto. Benchmark global: 55-70%.',
          icon: Icons.replay_circle_filled_outlined,
          color: primary,
          onTap: () => context.push('/dunning'),
        ),
        _MetricCard(
          titulo: 'Ativação Focux (PQL)',
          valor: '${snapshot.pqlScore} pts',
          delta: 'Classificação: ${snapshot.pqlClassificacao}',
          icon: Icons.rocket_launch_outlined,
          color: primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Dicas',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const _Tip(
          icon: Icons.handshake,
          texto:
              'NDR < 100%: ative o flow de cancel save (pause/desconto/anual). Save rate global: 20-35%.',
        ),
        const _Tip(
          icon: Icons.schedule,
          texto:
              'Inadimplência: configure mensalidades antecipadas + lembretes 5d/3d/1d antes.',
        ),
        const _Tip(
          icon: Icons.layers,
          texto:
              'ARPA baixo: monte pacotes (treino+nutri+consultoria). Bundling +30-60% ARPU.',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.titulo,
    required this.valor,
    required this.delta,
    required this.icon,
    required this.color,
    this.onTap,
  });
  final String titulo;
  final String valor;
  final String delta;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: fxListCardDecoration(context, accent: color),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    Text(
                      valor,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(delta, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.titulo,
    required this.valor,
    required this.icon,
  });
  final String titulo;
  final String valor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: fxListCardDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(titulo, style: Theme.of(context).textTheme.bodySmall),
            Text(
              valor,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.texto});
  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
