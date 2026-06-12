import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/motion_preferences.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import 'financeiro_dashboard_screen.dart';
import 'financeiro_mensalidades_tab.dart';
import 'financeiro_resumo_screen.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

class FinanceiroScreen extends ConsumerStatefulWidget {
  const FinanceiroScreen({super.key, this.initialAlunoId});

  final int? initialAlunoId;

  @override
  ConsumerState<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends ConsumerState<FinanceiroScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _periodFilter = 'agora';

  static const Map<String, String> _periodLabels = {
    'agora': FocuxMicrocopy.periodoAgora,
    'mes_atual': FocuxMicrocopy.periodoEsteMes,
    'mes_anterior': FocuxMicrocopy.periodoMesAnterior,
    'ano': FocuxMicrocopy.periodoAno,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialAlunoId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (reduceMotionOf(context)) {
          _tabController.index = 1;
        } else {
          _tabController.animateTo(
            1,
            duration: fxMotionDuration(context, normal: const Duration(milliseconds: 280)),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      featureName: 'Financeiro',
      requiredPlan: SubscriptionPlan.PREMIUM,
      capability: 'financeiro',
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Financeiro',
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(136),
          child: FxContentWidthLimiter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FxShellAppBar(
                  title: 'Financeiro',
                  subtitle: FocuxMicrocopy.financeiroEsteMes,
                  onBack: () => safePopOrGo(context, '/dashboard/personal'),
                  actions: [
                    PopupMenuButton<String>(
                      initialValue: _periodFilter,
                      tooltip: 'Filtrar periodo',
                      onSelected: (value) {
                        setState(() => _periodFilter = value);
                        if (value == 'ano') {
                          _tabController.animateTo(2);
                        }
                      },
                      itemBuilder:
                          (context) =>
                              _periodLabels.entries
                                  .map(
                                    (entry) => PopupMenuItem<String>(
                                      value: entry.key,
                                      child: Text(entry.value),
                                    ),
                                  )
                                  .toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: chrome.panel(radius: 999),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _periodLabels[_periodFilter] ?? 'agora',
                              style: TextStyle(
                                fontSize: 12,
                                color: ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: TokensStrip.s2),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: mute,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                TabBar(
                  controller: _tabController,
                  indicatorColor: primary,
                  labelColor: primary,
                  unselectedLabelColor: mute,
                  indicatorWeight: 2.5,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(icon: Icon(Icons.dashboard_outlined), text: 'Resumo'),
                    Tab(
                      icon: Icon(Icons.receipt_long_outlined),
                      text: 'Mensalidades',
                    ),
                    Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Metricas'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: FxContentWidthLimiter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.initialAlunoId != null)
                _FinanceiroAlunoContextBanner(alunoId: widget.initialAlunoId!),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    const FinanceiroDashboardScreen(),
                    FinanceiroMensalidadesTab(
                      initialAlunoId: widget.initialAlunoId,
                    ),
                    const FinanceiroResumoScreen(),
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

class _FinanceiroAlunoContextBanner extends ConsumerWidget {
  const _FinanceiroAlunoContextBanner({required this.alunoId});

  final int alunoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alunoAsync = ref.watch(alunoProvider(alunoId));
    final nome = alunoAsync.valueOrNull?.nome ?? 'Aluno #$alunoId';
    final chrome = ShellChrome.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: EagleTokens.warn.withValues(
            alpha: chrome.isDark ? 0.14 : 0.08,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: EagleTokens.warn.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline, color: EagleTokens.warn, size: 18),
            SizedBox(width: TokensStrip.s2),
            Expanded(
              child: Text(
                'Mensalidades de $nome',
                style: TextStyle(
                  color: chrome.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
