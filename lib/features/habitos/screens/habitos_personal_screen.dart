import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/planos/data/planos_repository.dart';
import '../../../features/planos/providers/plano_features_provider.dart';
import '../../../features/subscription/models/subscription_plan.dart';
import '../data/habito_repository.dart';

final _repoProvider = Provider(
  (ref) => HabitoRepository(ref.read(apiClientProvider)),
);

class HabitosPersonalScreen extends ConsumerStatefulWidget {
  const HabitosPersonalScreen({super.key});

  @override
  ConsumerState<HabitosPersonalScreen> createState() =>
      _HabitosPersonalScreenState();
}

class _HabitosPersonalScreenState extends ConsumerState<HabitosPersonalScreen> {
  List<Habito> _habitos = [];
  List<ComplianceItem> _compliance = [];
  PlanoFeatures? _planoFromHome;
  bool _loading = true;
  String? _error;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final home = await ref.read(_repoProvider).getHome();
      if (!mounted) return;
      setState(() {
        _habitos = home.habitos;
        _compliance = home.compliance;
        _planoFromHome = home.planoFeatures;
        _fetchedAt = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  Future<void> _novoHabito() async {
    List<HabitoTemplate> templates = [];
    try {
      templates = await ref.read(_repoProvider).templates();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }

    if (!mounted) return;

    HabitoTemplate? selected;
    final tituloCtrl = TextEditingController();
    final descricaoCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setDialogState) => AlertDialog(
                  title: const Text('Novo hábito'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (templates.isNotEmpty) ...[
                          DropdownButtonFormField<HabitoTemplate>(
                            decoration: const InputDecoration(
                              labelText: 'Template',
                            ),
                            items:
                                templates
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(
                                          '${t.icone ?? ''} ${t.titulo}',
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (t) {
                              setDialogState(() {
                                selected = t;
                                if (t != null) {
                                  tituloCtrl.text = t.titulo;
                                  descricaoCtrl.text = t.descricao ?? '';
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                        TextField(
                          controller: tituloCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descricaoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Descrição (opcional)',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Criar'),
                    ),
                  ],
                ),
          ),
    );
    if (ok == true && tituloCtrl.text.trim().isNotEmpty) {
      try {
        await ref
            .read(_repoProvider)
            .criar(
              titulo: tituloCtrl.text.trim(),
              descricao:
                  descricaoCtrl.text.trim().isEmpty
                      ? null
                      : descricaoCtrl.text.trim(),
              tipo: selected?.tipo ?? 'CUSTOM',
              metaDiaria: selected?.metaDiaria,
              metaSemanal: selected?.metaSemanal,
              icone: selected?.icone,
            );
        AnalyticsService.instance.track(
          ProductEvents.habitoCreated,
          props: {'feature': 'habitos'},
        );
        await _carregar();
      } catch (e) {
        if (!mounted) return;
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final planoFromHome = _planoFromHome;
    if (planoFromHome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(planoFeaturesProvider.notifier).seedFromHome(planoFromHome);
      });
    }

    return fxScreenA11yScope(
      label: 'Hábitos & Compliance',
      child: FeatureGate(
        featureName: 'Habit Coaching',
        requiredPlan: SubscriptionPlan.PREMIUM,
        capability: 'habitCoaching',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Hábitos & Compliance',
            subtitle: freshnessLabel ?? 'Coaching diário e aderência',
          ),
        floatingActionButton: Semantics(
          label: 'Novo hábito',
          button: true,
          child: FloatingActionButton.extended(
            onPressed: _novoHabito,
            icon: const Icon(Icons.add),
            label: const Text('Novo hábito'),
          ),
        ),
        body:
            _loading
                ? const Padding(
                  padding: EdgeInsets.all(TokensStrip.s4),
                  child: SkeletonList(count: 5),
                )
                : _error != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: _error!,
                  onRetry: _carregar,
                )
                : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _SectionHeader(
                        titulo: 'Hábitos cadastrados',
                        subtitulo: 'Aplica para todos os seus alunos',
                      ),
                      if (_habitos.isEmpty)
                        FxEmptyState(
                          icon: 'circle-check',
                          title: 'Nenhum hábito cadastrado',
                          subtitle:
                              'Hábitos diários (água, sono, refeições) aumentam aderência e reduzem churn.',
                          action: FxEmptyAction(
                            label: 'Novo hábito',
                            onTap: _novoHabito,
                          ),
                        )
                      else
                        ..._habitos.map(
                          (h) => FxSatelliteListTile(
                            title: h.titulo,
                            titleCase: false,
                            leading: Icon(
                              Icons.fitness_center_rounded,
                              color: primary,
                            ),
                            subtitle: Text(
                              h.descricao ?? 'Meta semanal: ${h.metaSemanal}x',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () async {
                                await ref.read(_repoProvider).desativar(h.id);
                                await _carregar();
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        titulo: 'Compliance da semana',
                        subtitulo: 'Aderência dos seus alunos aos hábitos',
                      ),
                      if (_compliance.isEmpty)
                        const FxEmptyState(
                          icon: 'trend',
                          title: 'Sem dados ainda',
                          subtitle:
                              'Cadastre hábitos e os alunos vão começar a marcar.',
                        )
                      else
                        ..._compliance.map((c) => _ComplianceTile(item: c)),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.titulo, required this.subtitulo});
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            subtitulo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplianceTile extends StatelessWidget {
  const _ComplianceTile({required this.item});
  final ComplianceItem item;

  @override
  Widget build(BuildContext context) {
    final color =
        item.compliancePct >= 70
            ? EagleTokens.good
            : item.compliancePct >= 40
            ? EagleTokens.warn
            : EagleTokens.bad;
    return FxSatelliteListTile(
      title: item.alunoNome,
      accent: color,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Text(
          '${item.compliancePct}%',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      subtitle: Text('${item.checksSemana} checks na semana'),
      trailing: Icon(
        item.compliancePct >= 70
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        color: color,
      ),
    );
  }
}
