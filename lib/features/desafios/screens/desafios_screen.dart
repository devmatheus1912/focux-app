import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_inset_picker_row.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/desafio_repository.dart';
import '../utils/desafio_display.dart';

final _repo = Provider((ref) => DesafioRepository(ref.read(apiClientProvider)));

class DesafiosScreen extends ConsumerStatefulWidget {
  const DesafiosScreen({super.key});

  @override
  ConsumerState<DesafiosScreen> createState() => _DesafiosScreenState();
}

class _DesafiosScreenState extends ConsumerState<DesafiosScreen> {
  List<Desafio> _desafios = [];
  var _filtro = DesafioTipoFiltro.todos;
  var _loading = true;
  String? _error;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Desafio> get _visiveis => _desafios
      .where((d) => desafioMatchesFiltro(d.tipo, _filtro))
      .toList();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lista = await ref.read(_repo).listar();
      if (!mounted) return;
      setState(() {
        _desafios = lista;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  Future<void> _criar() async {
    final tituloCtrl = TextEditingController();
    final descricaoCtrl = TextEditingController();
    var tipo = desafioTipos.first.value;
    var dias = 30;
    var metaPontos = 100;
    var created = false;
    try {
      final ok = await showFxFormSheet(
        context,
        title: 'Novo desafio',
        subtitle: 'Prazo, tipo e meta entram no ranking.',
        icon: Icons.flag_outlined,
        confirmLabel: 'Criar',
        child: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AlunoInsetFormField(
                controller: tituloCtrl,
                label: 'Título',
                icon: Icons.title_outlined,
              ),
              AlunoInsetFormField(
                controller: descricaoCtrl,
                label: 'Descrição (opcional)',
                icon: Icons.notes_outlined,
                maxLines: 2,
              ),
              FxInsetPickerRow(
                icon: Icons.category_outlined,
                label: 'Tipo',
                value: desafioTipoLabel(tipo),
                onTap: () async {
                  final picked = await showFxInsetPickerSheet<String>(
                    ctx,
                    title: 'Tipo',
                    selected: tipo,
                    items: [
                      for (final item in desafioTipos)
                        FxInsetPickerSheetItem(
                          value: item.value,
                          label: item.label,
                        ),
                    ],
                  );
                  if (picked == null) return;
                  setDialogState(() => tipo = picked);
                },
              ),
              FxInsetPickerRow(
                icon: Icons.event_outlined,
                label: 'Prazo',
                value: desafioDuracaoLabel(dias),
                onTap: () async {
                  final picked = await showFxInsetPickerSheet<int>(
                    ctx,
                    title: 'Prazo',
                    selected: dias,
                    items: [
                      for (final d in desafioDuracoes)
                        FxInsetPickerSheetItem(
                          value: d,
                          label: desafioDuracaoLabel(d),
                        ),
                    ],
                  );
                  if (picked == null) return;
                  setDialogState(() => dias = picked);
                },
              ),
              FxInsetPickerRow(
                icon: Icons.emoji_events_outlined,
                label: 'Meta',
                value: desafioMetaLabel(metaPontos),
                showDivider: false,
                onTap: () async {
                  final picked = await showFxInsetPickerSheet<int>(
                    ctx,
                    title: 'Meta',
                    selected: metaPontos,
                    items: const [
                      FxInsetPickerSheetItem(value: 50, label: '50 pts'),
                      FxInsetPickerSheetItem(value: 100, label: '100 pts'),
                      FxInsetPickerSheetItem(value: 200, label: '200 pts'),
                    ],
                  );
                  if (picked == null) return;
                  setDialogState(() => metaPontos = picked);
                },
              ),
            ],
          ),
        ),
      );
      if (ok != true || tituloCtrl.text.trim().isEmpty) return;
      final hoje = DateTime.now();
      await ref.read(_repo).criar(
        titulo: tituloCtrl.text.trim(),
        descricao: descricaoCtrl.text.trim().isEmpty
            ? null
            : descricaoCtrl.text.trim(),
        tipo: tipo,
        metaPontos: metaPontos,
        inicio: hoje,
        fim: hoje.add(Duration(days: dias)),
      );
      AnalyticsService.instance.track(
        ProductEvents.desafioCreated,
        props: {'feature': 'desafios', 'tipo': tipo},
      );
      created = true;
      if (mounted) FeedbackHelper.showSuccess(context, 'Desafio criado');
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      tituloCtrl.dispose();
      descricaoCtrl.dispose();
    }
    if (created) await _load();
  }

  Future<void> _abrirDetalhe(Desafio d) async {
    try {
      final lb = await ref.read(_repo).leaderboard(d.id);
      if (!mounted) return;
      showFxHomeSheet<void>(
        context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final primary = Theme.of(ctx).colorScheme.primary;
          return FxHomeSheetSurface(
            isDark: isDark,
            expand: true,
            maxHeight:
                MediaQuery.sizeOf(ctx).height *
                FxHomeSheetChrome.expandHeightFactor,
            child: Column(
              children: [
                FxHomeSheetHandle(isDark: isDark),
                SizedBox(height: FxSettingsLayout.headerToGroup),
                FxHomeSheetHeader(
                  isDark: isDark,
                  title: d.titulo,
                  subtitle: desafioSubtitle(
                    tipo: d.tipo,
                    metaPontos: d.metaPontos,
                    inicio: d.inicio,
                    fim: d.fim,
                  ),
                  leading: Icon(
                    Icons.emoji_events_outlined,
                    color: primary,
                    size: 18,
                  ),
                ),
                SizedBox(height: FxSettingsLayout.headerToGroup),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      0,
                      FxSettingsLayout.pageInset,
                      24,
                    ),
                    children: [
                      if (d.descricao != null && d.descricao!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            d.descricao!.trim(),
                            style: FocuxHubTypography.bodyMuted(
                              color: fxScreenMute(ctx),
                            ),
                          ),
                        ),
                      if (lb.isEmpty)
                        Text(desafioLeaderboardEmpty())
                      else
                        FxSettingsGroup(
                          header: 'Ranking',
                          children: [
                            for (var i = 0; i < lb.length; i++)
                              FxSettingsTile(
                                fxIcon: 'star',
                                label: desafioLeaderboardName(lb[i].alunoNome),
                                subtitle: '${i + 1}º lugar',
                                value: desafioLeaderboardPoints(lb[i].pontos),
                                numeric: true,
                                showDivider: i != lb.length - 1,
                                onTap: lb[i].alunoId <= 0
                                    ? null
                                    : () {
                                        Navigator.of(ctx).pop();
                                        context.push(
                                          '/alunos/${lb[i].alunoId}',
                                        );
                                      },
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final scheme = Theme.of(context).colorScheme;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Desafios',
      child: FeatureGate(
        featureName: 'Desafios',
        requiredPlan: SubscriptionPlan.ENTERPRISE,
        capability: 'comunidadeGrupos',
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Desafios',
            subtitle: desafioHubSubtitle(
              count: _loading ? 0 : _desafios.length,
              freshness: _loading ? null : freshnessLabel,
            ),
            onBack: () => safePopOrGo(context, '/perfil/ferramentas'),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar desafios',
                onTap: () => showFxHelpSheet(
                  context,
                  title: 'Desafios',
                  subtitle: 'Campanha com prazo, meta e ranking.',
                  tips: const [
                    FxHelpTip(
                      'Criar',
                      'Título, tipo, prazo e meta. O ranking soma hábitos ou treinos.',
                    ),
                    FxHelpTip(
                      'Participar',
                      'O aluno entra sozinho pelo app. Toque no ranking para abrir o 360.',
                    ),
                  ],
                ),
              ),
              ShellHeaderIconButton(
                icon: 'plus',
                tooltip: 'Novo desafio',
                onTap: _criar,
              ),
            ],
          ),
          body: _loading
              ? const Padding(
                  padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 5),
                )
              : _error != null
              ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: scheme.primary,
                  message: _error!,
                  onRetry: _load,
                )
              : FxContentWidthLimiter(child: _buildBody()),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final visiveis = _visiveis;
    return RefreshIndicator(
      onRefresh: _load,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s4,
              TokensStrip.s2,
              TokensStrip.s4,
              TokensStrip.s2,
            ),
            child: Wrap(
              spacing: TokensStrip.s2,
              runSpacing: TokensStrip.s2,
              children: [
                for (final filtro in DesafioTipoFiltro.values)
                  FxToggleChip(
                    label: desafioFiltroLabel(filtro),
                    selected: _filtro == filtro,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                    onTap: () => setState(() => _filtro = filtro),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                8,
                FxSettingsLayout.pageInset,
                32,
              ),
              itemCount: visiveis.isEmpty ? 1 : visiveis.length + 2,
              itemBuilder: (context, index) {
                if (visiveis.isEmpty) {
                  return FxEmptyState(
                    icon: 'spark',
                    title: _desafios.isEmpty
                        ? 'Nenhum desafio'
                        : 'Nada neste filtro',
                    subtitle: _desafios.isEmpty
                        ? 'Crie o primeiro desafio com prazo e meta.'
                        : 'Troque o tipo ou crie outro desafio.',
                    action: FxEmptyAction(
                      label: 'Criar desafio',
                      onTap: _criar,
                    ),
                  );
                }
                if (index == 0) {
                  return const DashboardSectionHeader(title: 'Desafios ativos');
                }
                if (index == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      top: TokensStrip.s2,
                      bottom: TokensStrip.s3,
                    ),
                    child: Text(
                      'Toque para ver prazo e ranking.',
                      style: FocuxHubTypography.bodyMuted(
                        color: fxScreenMute(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                final desafio = visiveis[index - 2];
                return FxSatelliteListTile(
                  title: desafio.titulo,
                  subtitle: Text(
                    desafioSubtitle(
                      tipo: desafio.tipo,
                      metaPontos: desafio.metaPontos,
                      inicio: desafio.inicio,
                      fim: desafio.fim,
                    ),
                  ),
                  trailing: Text(
                    desafioMetaLabel(desafio.metaPontos),
                    style: FocuxHubTypography.bodyMuted(
                      color: fxScreenMute(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () => _abrirDetalhe(desafio),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
