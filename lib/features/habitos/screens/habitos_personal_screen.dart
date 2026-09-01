import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_inset_picker_row.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/alunos/widgets/aluno_inset_form_field.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/planos/data/planos_repository.dart';
import '../../../features/planos/providers/plano_features_provider.dart';
import '../../../features/subscription/models/subscription_plan.dart';
import '../data/habito_repository.dart';
import '../utils/habitos_display.dart';

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
    var created = false;
    try {
      final ok = await showFxFormSheet(
        context,
        title: 'Novo hábito',
        subtitle: 'Vale para todos os seus alunos.',
        icon: Icons.add_task_outlined,
        confirmLabel: 'Criar',
        child: StatefulBuilder(
          builder:
              (ctx, setDialogState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (templates.isNotEmpty)
                    FxInsetPickerRow(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Template',
                      value: habitoTemplateValue(
                        selected?.titulo,
                        icone: selected?.icone,
                      ),
                      onTap: () async {
                        final picked = await showFxInsetPickerSheet<String>(
                          ctx,
                          title: 'Template',
                          selected: selected?.tipo,
                          items: [
                            for (final t in templates)
                              FxInsetPickerSheetItem(
                                value: t.tipo,
                                label: habitoTemplateLabel(
                                  titulo: t.titulo,
                                  icone: t.icone,
                                ),
                              ),
                          ],
                        );
                        if (picked == null) return;
                        HabitoTemplate? match;
                        for (final t in templates) {
                          if (t.tipo == picked) {
                            match = t;
                            break;
                          }
                        }
                        final template = match;
                        if (template == null) return;
                        setDialogState(() {
                          selected = template;
                          tituloCtrl.text = template.titulo;
                          descricaoCtrl.text = template.descricao ?? '';
                        });
                      },
                    ),
                  AlunoInsetFormField(
                    controller: tituloCtrl,
                    label: 'Título',
                    icon: Icons.title_outlined,
                    showDivider: true,
                  ),
                  AlunoInsetFormField(
                    controller: descricaoCtrl,
                    label: 'Descrição (opcional)',
                    icon: Icons.notes_outlined,
                    maxLines: 2,
                    showDivider: false,
                  ),
                ],
              ),
        ),
      );
      if (ok == true && tituloCtrl.text.trim().isNotEmpty) {
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
        created = true;
      }
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      tituloCtrl.dispose();
      descricaoCtrl.dispose();
    }
    if (created) await _carregar();
  }

  Future<void> _desativar(Habito h) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Desativar hábito?',
      subtitle: h.titulo,
      message: 'Os alunos deixam de ver este hábito. Dá para criar outro depois.',
      confirmLabel: 'Desativar',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(_repoProvider).desativar(h.id);
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
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
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'habitCoaching',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Hábitos & Compliance',
            subtitle: habitoHubSubtitle(freshnessLabel),
            actions: [
              ShellHeaderIconButton(
                icon: 'plus',
                tooltip: 'Novo hábito',
                onTap: _novoHabito,
              ),
            ],
          ),
          body:
              _loading
                  ? const Padding(
                    padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                    child: SkeletonList(count: 5),
                  )
                  : _error != null
                  ? FxErrorState(
                    chromeOnDark: chrome.isDark,
                    primary: primary,
                    message: _error!,
                    onRetry: _carregar,
                  )
                  : FxContentWidthLimiter(child: _buildBody()),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        children: [
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
            FxSettingsGroup(
              header: 'Hábitos cadastrados',
              caption: 'Toque para desativar. Vale para todos os seus alunos.',
              children: [
                for (var i = 0; i < _habitos.length; i++)
                  FxSettingsTile(
                    fxIcon: 'circle-check',
                    label: _habitos[i].titulo,
                    subtitle: habitoSubtitle(
                      descricao: _habitos[i].descricao,
                      metaSemanal: _habitos[i].metaSemanal,
                    ),
                    value: habitoMetaValue(_habitos[i].metaSemanal),
                    numeric: true,
                    showDivider: i != _habitos.length - 1,
                    onTap: () => _desativar(_habitos[i]),
                  ),
              ],
            ),
          const SizedBox(height: FxSettingsLayout.groupGap),
          if (_compliance.isEmpty)
            const FxEmptyState(
              icon: 'trend',
              title: 'Sem dados ainda',
              subtitle: 'Cadastre hábitos e os alunos vão começar a marcar.',
            )
          else
            FxSettingsGroup(
              header: 'Compliance da semana',
              caption: 'Toque para abrir o aluno.',
              children: [
                for (var i = 0; i < _compliance.length; i++)
                  FxSettingsTile(
                    fxIcon: habitoComplianceFxIcon(
                      _compliance[i].compliancePct,
                    ),
                    label: habitoComplianceLabel(_compliance[i].alunoNome),
                    subtitle: habitoComplianceSubtitle(
                      _compliance[i].checksSemana,
                    ),
                    value: habitoComplianceValue(
                      _compliance[i].compliancePct,
                    ),
                    numeric: true,
                    danger: habitoComplianceDanger(
                      _compliance[i].compliancePct,
                    ),
                    showDivider: i != _compliance.length - 1,
                    onTap:
                        () => context.push(
                          '/alunos/${_compliance[i].alunoId}',
                        ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
