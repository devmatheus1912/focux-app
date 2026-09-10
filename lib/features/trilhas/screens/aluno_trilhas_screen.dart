import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
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
  final _mais = <TrilhaModel>[];
  var _nextPage = 1;
  var _hasMore = false;
  var _loadingMore = false;

  Future<void> _refresh() async {
    _mais.clear();
    _nextPage = 1;
    _hasMore = false;
    ref.invalidate(trilhasMinhasProvider);
    try {
      final lista = await ref.read(trilhasMinhasProvider.future);
      if (mounted) {
        setState(() {
          _fetchedAt = DateTime.now();
          _hasMore = lista.hasMore;
        });
      }
    } catch (_) {}
  }

  Future<void> _carregarMais() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await ref
          .read(trilhasRepositoryProvider)
          .listarMinhas(page: _nextPage);
      if (!mounted) return;
      setState(() {
        _mais.addAll(next.items);
        _nextPage += 1;
        _hasMore = next.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMore = false);
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _concluirMarco(TrilhaModel trilha, MarcoModel marco) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Concluir etapa?',
      subtitle: marco.titulo,
      message: 'Marca esta etapa da trilha ${trilha.titulo}.',
      confirmLabel: 'Concluir',
    );
    if (!ok || !mounted) return;
    try {
      await ref
          .read(trilhasRepositoryProvider)
          .concluirMarco(trilhaId: trilha.id, marcoId: marco.id);
      if (mounted) FeedbackHelper.showSuccess(context, 'Etapa concluída.');
      await _refresh();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  void _abrirTrilha(TrilhaModel trilha) {
    showFxHomeSheet<void>(
      context,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final primary = Theme.of(sheetContext).colorScheme.primary;
        final mute = ShellChrome.forDark(isDark).mute;
        final marco = trilhaProximoMarco(trilha);
        final maxHeight =
            MediaQuery.sizeOf(sheetContext).height *
            FxHomeSheetChrome.maxHeightFactor;

        return FxHomeSheetSurface(
          isDark: isDark,
          maxHeight: maxHeight,
          expand: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              const SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: isDark,
                title: trilha.titulo,
                leading: FxIcon(name: 'route', size: 18, color: primary),
              ),
              const SizedBox(height: TokensStrip.s3),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TrilhaSheetRow(
                        label: 'Status',
                        value: trilhaStatusLabel(trilha.concluida),
                        mute: mute,
                      ),
                      _TrilhaSheetRow(
                        label: 'Progresso',
                        value: trilhaPercentLabel(trilha.percentualConclusao),
                        mute: mute,
                      ),
                      _TrilhaSheetRow(
                        label: 'Valor atual',
                        value: trilhaValorAtualLabel(trilha),
                        mute: mute,
                      ),
                      if (marco != null)
                        _TrilhaSheetRow(
                          label: 'Próximo marco',
                          value: marco.titulo,
                          mute: mute,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              FxLiquidPrimaryButton(
                label: 'Ir aos treinos',
                onPressed: () {
                  FxHomeSheetChrome.dismissAndPop(sheetContext);
                  context.push('/checkin/treinos');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  TrilhaModel? _trilhaComMarcoPendente(List<TrilhaModel> trilhas) {
    for (final trilha in trilhas) {
      if (trilhaProximoMarco(trilha) != null) return trilha;
    }
    return null;
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
          constrainWidth: false,
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
                  data: (lista) {
                    _stampFreshness();
                    final merged = lista.append(
                      TrilhaLista(
                        items: _mais,
                        hasMore: _mais.isEmpty ? lista.hasMore : _hasMore,
                      ),
                    );
                    return FxContentWidthLimiter(
                      child: _buildBody(merged, primary, chrome),
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
    TrilhaLista lista,
    Color primary,
    bool isDark,
  ) {
    final trilhas = lista.items;
    final visiveis = trilhaFiltradas(trilhas, _filtro);
    final pagePadding = const EdgeInsets.fromLTRB(
      FxSettingsLayout.pageInset,
      TokensStrip.s4,
      FxSettingsLayout.pageInset,
      32,
    );

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: pagePadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const FxHubHeader(
                  title: 'Seu progresso',
                  subtitle: 'Metas que o personal atribuiu',
                ),
                const SizedBox(height: TokensStrip.s3),
                Wrap(
                  spacing: TokensStrip.s2,
                  runSpacing: TokensStrip.s2,
                  children: [
                    DashboardHomeActionChip(
                      label: 'Hábitos',
                      accent: primary,
                      isDark: isDark,
                      onPressed: () => context.push('/aluno/habitos'),
                    ),
                    DashboardHomeActionChip(
                      label: 'Chat',
                      accent: primary,
                      isDark: isDark,
                      onPressed: () => context.push('/chat/aluno'),
                    ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s4),
                OperationalMetricTile(
                  label: 'Ativas',
                  value: '${trilhaListaAtivas(lista)}',
                  hint:
                      trilhas.isEmpty
                          ? 'Nenhuma trilha ainda'
                          : '${trilhaConcluidasCount(trilhas)} concluídas',
                  color: primary,
                  isDark: isDark,
                ),
                const SizedBox(height: TokensStrip.s3),
                OperationalMetricTile(
                  label: 'Progresso',
                  value: trilhaListaProgressoLabel(lista),
                  hint: 'Média das suas trilhas',
                  color: primary,
                  isDark: isDark,
                ),
                const SizedBox(height: TokensStrip.s3),
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
                const SizedBox(height: TokensStrip.s3),
                OperationalMetricTile(
                  label: 'Prazo',
                  value: trilhaListaPrazoValue(lista),
                  hint: trilhaListaPrazoHint(lista),
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
              ]),
            ),
          ),
          if (trilhas.isEmpty)
            SliverPadding(
              padding: pagePadding.copyWith(top: 0),
              sliver: SliverToBoxAdapter(
                child: FxEmptyState(
                  icon: 'route',
                  title: 'Nenhuma trilha atribuída',
                  subtitle:
                      'Quando o personal criar uma meta, o progresso aparece aqui.',
                  action: FxEmptyAction(
                    label: 'Ir aos treinos',
                    onTap: () => context.push('/checkin/treinos'),
                  ),
                ),
              ),
            )
          else if (visiveis.isEmpty)
            SliverPadding(
              padding: pagePadding.copyWith(top: 0),
              sliver: SliverToBoxAdapter(
                child: FxEmptyState(
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
                ),
              ),
            )
          else ...[
            if (trilhaMarcosPendentes(trilhas) > 0)
              if (_trilhaComMarcoPendente(trilhas) case final focus?)
                if (trilhaProximoMarco(focus) case final marco?)
                  SliverPadding(
                    padding: pagePadding.copyWith(top: 0),
                    sliver: SliverToBoxAdapter(
                      child: FxStripCard(
                        emphasize: true,
                        semanticsLabel:
                            'Próximo marco: ${marco.titulo}. ${focus.titulo}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Próximo marco',
                              style: FocuxHubTypography.chip(
                                ShellChrome.forDark(isDark).mute,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              marco.titulo,
                              style: FocuxHubTypography.sectionTitle(
                                context,
                                color: ShellChrome.forDark(isDark).ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              focus.titulo,
                              style: FocuxHubTypography.bodyMuted(
                                color: ShellChrome.forDark(isDark).mute,
                              ),
                            ),
                            const SizedBox(height: TokensStrip.s3),
                            DashboardHomeActionChip(
                              label: 'Continuar',
                              accent: primary,
                              isDark: isDark,
                              onPressed: () => _abrirTrilha(focus),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            SliverPadding(
              padding: pagePadding.copyWith(top: TokensStrip.s4),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    DashboardSectionHeader(title: 'Trilhas'),
                    SizedBox(height: TokensStrip.s3),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: pagePadding.copyWith(top: 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final trilha = visiveis[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FxSatelliteListTile(
                          title: trilha.titulo,
                          titleCase: false,
                          onTap: () => _abrirTrilha(trilha),
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
                        if (trilhaProximoMarco(trilha) case final marco?)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: TokensStrip.s3,
                            ),
                            child: DashboardHomeActionChip(
                              label: 'Concluir ${marco.titulo}',
                              accent: primary,
                              isDark: isDark,
                              onPressed: () => _concluirMarco(trilha, marco),
                            ),
                          ),
                      ],
                    );
                  },
                  childCount: visiveis.length,
                ),
              ),
            ),
            if (lista.hasMore)
              SliverPadding(
                padding: pagePadding.copyWith(top: 0),
                sliver: SliverToBoxAdapter(
                  child: DashboardHomeActionChip(
                    label: _loadingMore ? 'Carregando…' : 'Carregar mais',
                    accent: primary,
                    isDark: isDark,
                    enabled: !_loadingMore,
                    onPressed: _carregarMais,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _TrilhaSheetRow extends StatelessWidget {
  const _TrilhaSheetRow({
    required this.label,
    required this.value,
    required this.mute,
  });

  final String label;
  final String value;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: FocuxHubTypography.chip(mute)),
          const SizedBox(height: 4),
          Text(
            value,
            style: FocuxHubTypography.body(
              color: ShellChrome.of(context).ink,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
