import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../models/trilha.dart';
import '../providers/trilhas_provider.dart';
import '../utils/trilhas_display.dart';
import '../widgets/trilhas_help_sheet.dart';

class AlunoTrilhasScreen extends ConsumerStatefulWidget {
  const AlunoTrilhasScreen({super.key});

  @override
  ConsumerState<AlunoTrilhasScreen> createState() => _AlunoTrilhasScreenState();
}

class _AlunoTrilhasScreenState extends ConsumerState<AlunoTrilhasScreen> {
  DateTime? _fetchedAt;
  String _filtro = trilhaFiltroAndamento;

  Future<void> _refresh() async {
    ref.invalidate(trilhasMinhasProvider);
    try {
      await ref.read(trilhasMinhasProvider.future);
      if (mounted) setState(() => _fetchedAt = DateTime.now());
    } catch (_) {}
  }

  void _stampFreshness() {
    if (_fetchedAt != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _fetchedAt != null) return;
      setState(() => _fetchedAt = DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final chrome = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final async = ref.watch(trilhasMinhasProvider);
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final showSticky = !async.isLoading && !async.hasError;

    return fxScreenA11yScope(
      label: 'Minhas trilhas',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          safePopOrGo(context, '/dashboard/aluno');
        },
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Trilhas',
            subtitle: freshness,
            onBack: () => safePopOrGo(context, '/dashboard/aluno'),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar as trilhas',
                onTap: () => showAlunoTrilhasHelpSheet(context),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: async.when(
                  loading:
                      () => const Padding(
                        padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                        child: SkeletonList(count: 4),
                      ),
                  error:
                      (e, _) => FxErrorState(
                        chromeOnDark: chrome,
                        primary: primary,
                        message: friendlyError(e),
                        onRetry: _refresh,
                        title: 'Não conseguimos carregar as trilhas',
                      ),
                  data: (trilhas) {
                    _stampFreshness();
                    return FxContentWidthLimiter(
                      child: _buildBody(trilhas, freshness, primary, chrome),
                    );
                  },
                ),
              ),
              if (showSticky)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s2,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: FxLiquidPrimaryButton(
                      label: 'Ir aos treinos',
                      onPressed: () => context.push('/checkin/treinos'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    List<TrilhaModel> trilhas,
    String? freshness,
    Color primary,
    bool isDark,
  ) {
    final visiveis = trilhaFiltradas(trilhas, _filtro);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s4,
          FxSettingsLayout.pageInset,
          32,
        ),
        children: [
          FxHubHeader(
            title: 'Seu progresso',
            subtitle: freshness ?? 'Metas que o personal atribuiu',
          ),
          const SizedBox(height: TokensStrip.s4),
          OperationalMetricTile(
            label: 'Ativas',
            value: '${trilhaAtivasCount(trilhas)}',
            hint:
                trilhas.isEmpty
                    ? 'Nenhuma trilha ainda'
                    : '${trilhaConcluidasCount(trilhas)} concluídas',
            color: primary,
            isDark: isDark,
          ),
          const SizedBox(height: TokensStrip.s2),
          OperationalMetricTile(
            label: 'Progresso',
            value: trilhaProgressoMedioLabel(trilhas),
            hint: 'Média das suas trilhas',
            color: primary,
            isDark: isDark,
          ),
          const SizedBox(height: TokensStrip.s2),
          OperationalMetricTile(
            label: 'Marcos',
            value: '${trilhaMarcosPendentes(trilhas)}',
            hint:
                trilhaMarcosPendentes(trilhas) == 0
                    ? 'Nada pendente'
                    : 'Etapas em aberto',
            color: primary,
            isDark: isDark,
          ),
          if (trilhas.isNotEmpty) ...[
            const SizedBox(height: TokensStrip.s4),
            AlunoSegmentedChoice(
              options: trilhaFiltroOpcoes,
              selected: _filtro,
              isDark: isDark,
              onSelect: (value) => setState(() => _filtro = value),
            ),
          ],
          const SizedBox(height: TokensStrip.s5),
          if (trilhas.isEmpty)
            const FxEmptyState(
              icon: 'route',
              title: 'Nenhuma trilha atribuída',
              subtitle:
                  'Quando o personal criar uma meta, o progresso aparece aqui.',
            )
          else if (visiveis.isEmpty)
            FxEmptyState(
              icon: 'route',
              title:
                  _filtro == trilhaFiltroConcluidas
                      ? 'Nenhuma trilha concluída'
                      : 'Nada em andamento',
              subtitle:
                  _filtro == trilhaFiltroConcluidas
                      ? 'As trilhas ativas aparecem na outra seção.'
                      : 'Tudo que existia já foi concluído.',
              action: FxEmptyAction(
                label:
                    _filtro == trilhaFiltroConcluidas
                        ? 'Ver em andamento'
                        : 'Ver concluídas',
                onTap:
                    () => setState(
                      () => _filtro =
                          _filtro == trilhaFiltroConcluidas
                              ? trilhaFiltroAndamento
                              : trilhaFiltroConcluidas,
                    ),
              ),
            )
          else ...[
            const DashboardSectionHeader(title: 'Trilhas'),
            const SizedBox(height: TokensStrip.s3),
            for (final trilha in visiveis)
              FxSatelliteListTile(
                title: trilha.titulo,
                titleCase: false,
                subtitle: Text(
                  '${trilhaStatusLabel(trilha.concluida)} · ${trilhaPercentLabel(trilha.percentualConclusao)}',
                ),
                leading: FxIcon(
                  name: trilha.concluida ? 'circle-check' : 'route',
                  size: 18,
                  color: primary,
                ),
                trailing: Text(trilhaValorAtualLabel(trilha)),
              ),
          ],
        ],
      ),
    );
  }
}
