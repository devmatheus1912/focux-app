import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/relatorio_repository.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

part 'relatorio_global_screen_widgets.part.dart';

class RelatorioGlobalScreen extends ConsumerStatefulWidget {
  const RelatorioGlobalScreen({super.key});

  @override
  ConsumerState<RelatorioGlobalScreen> createState() =>
      _RelatorioGlobalScreenState();
}

class _RelatorioGlobalScreenState extends ConsumerState<RelatorioGlobalScreen> {
  ResumoGlobal? _dados;
  bool _loading = true;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final repo = RelatorioRepository(ref.read(apiClientProvider));
      final dados = await repo.resumoGlobal();
      if (!mounted) return;
      setState(() {
        _dados = dados;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    return fxScreenA11yScope(
      label: 'Relatorio global',
      child: FeatureGate(
        featureName: 'Relatório global',
        requiredPlan: SubscriptionPlan.PREMIUM,
        capability: 'relatorios',
        child: FxShellScaffold(
          constrainWidth: false,
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Relatorio global',
            subtitle: freshnessLabel,
            onBack: () => safePopOrGo(context, '/dashboard/personal'),
            actions: [
              IconButton(
                tooltip: 'Atualizar',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: _load,
              ),
            ],
          ),
          body:
              _loading
                  ? const SkeletonList(count: 5)
                  : _erro != null
                  ? FxErrorState(
                    chromeOnDark: ShellChrome.of(context).isDark,
                    primary: Theme.of(context).colorScheme.primary,
                    message: _erro!,
                    onRetry: _load,
                  )
                  : _dados == null
                  ? const FxEmptyState(
                    icon: 'bar-chart-2',
                    title: 'Sem relatório ainda',
                    subtitle:
                        'Quando houver treinos na base, o panorama global aparece aqui.',
                  )
                  : _ReportContent(dados: _dados!, onRefresh: _load),
        ),
      ),
    );
  }
}
