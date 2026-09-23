import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/checkin_repository.dart';
import '../data/historico_mem_cache.dart';
import '../providers/checkin_provider.dart';
import '../utils/historico_display.dart';

class HistoricoCheckinScreen extends ConsumerStatefulWidget {
  const HistoricoCheckinScreen({super.key});

  @override
  ConsumerState<HistoricoCheckinScreen> createState() =>
      _HistoricoCheckinScreenState();
}

class _HistoricoCheckinScreenState
    extends ConsumerState<HistoricoCheckinScreen> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _items = <ExecucaoTreino>[];
  var _loading = true;
  var _loadingMore = false;
  var _hasNext = false;
  String? _nextCursor;
  String? _erro;
  DateTime? _fetchedAt;
  var _chip = HistoricoStatusChip.todos;
  var _query = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final cached = HistoricoMemCache.loadIfFresh();
    if (cached != null && cached.isNotEmpty) {
      _items.addAll(cached);
      _loading = false;
      _fetchedAt = DateTime.now();
    }
    _load(reset: true, keepStale: cached != null && cached.isNotEmpty);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) _load(reset: true);
    });
  }

  Future<void> _load({required bool reset, bool keepStale = false}) async {
    if (reset) {
      setState(() {
        _loading = _items.isEmpty;
        _erro = null;
        if (!keepStale) {
          _items.clear();
          _nextCursor = null;
          _hasNext = false;
        }
      });
    } else {
      if (_loadingMore || !_hasNext) return;
      setState(() => _loadingMore = true);
    }
    try {
      final pagina = await ref.read(checkinRepositoryProvider).historico(
        cursor: reset ? null : _nextCursor,
        q: _query,
        status: historicoStatusQuery(_chip),
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(pagina.content);
        } else {
          _items.addAll(pagina.content);
        }
        _hasNext = pagina.hasNext;
        _nextCursor = pagina.nextCursor;
        _loading = false;
        _loadingMore = false;
        if (reset) {
          _fetchedAt = DateTime.now();
          HistoricoMemCache.save(_items);
          ref.invalidate(historicoCheckinProvider);
          _prefetchTopDetalhes(_items);
        }
      });
    } catch (e) {
      if (!mounted) return;
      final message = friendlyError(e);
      if (reset) {
        setState(() {
          _erro = message;
          _loading = false;
          _loadingMore = false;
        });
      } else {
        setState(() => _loadingMore = false);
        FeedbackHelper.showError(context, message);
      }
    }
  }

  void _abrirTreinos() {
    FxKeyboardDismissScope.dismiss();
    context.push('/checkin/treinos');
  }

  void _leave() {
    FxKeyboardDismissScope.dismiss();
    safePopOrGo(context, '/checkin/treinos');
  }

  void _abrirItem(ExecucaoTreino entry) {
    final id = entry.id;
    if (id == null) return;
    // Prefetch em paralelo ao push — detalhe usa MemCache se chegar primeiro.
    unawaited(_prefetchDetalhe(id));
    context.push(historicoDetalhePath(id));
  }

  Future<void> _prefetchDetalhe(int id) async {
    if (HistoricoDetalheMemCache.loadIfFresh(id) != null) return;
    try {
      final loaded = await ref.read(checkinRepositoryProvider).detalhe(id);
      HistoricoDetalheMemCache.save(loaded);
    } catch (_) {}
  }

  void _prefetchTopDetalhes(List<ExecucaoTreino> items) {
    for (final entry in items.take(3)) {
      final id = entry.id;
      if (id == null) continue;
      unawaited(_prefetchDetalhe(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final mute = chrome.mute;
    final visible = _items;
    final count = visible.length;

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return fxScreenA11yScope(
      label: 'Histórico de Treinos',
      child: PopScope(
        canPop: !keyboardOpen && !_searchFocus.hasFocus,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (keyboardOpen || _searchFocus.hasFocus) {
            FxKeyboardDismissScope.dismiss();
            return;
          }
          _leave();
        },
        child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Histórico de Treinos',
          subtitle: FxHubFreshness.joinCount(
            _loading
                ? historicoCountLabel(0)
                : '${historicoCountLabel(count)}${_hasNext ? '+' : ''}',
            _loading ? null : FxHubFreshness.fromFetchedAt(_fetchedAt),
          ),
          showBack: true,
          fallbackLocation: '/checkin/treinos',
          onBack: _leave,
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar o histórico',
              onTap: () => showFxHelpSheet(
                context,
                title: 'Histórico',
                subtitle: 'Treinos que o aluno já fechou.',
                tips: const [
                  FxHelpTip(
                    'Busca',
                    'Filtra pelo nome. Os chips separam feitos e pendentes.',
                  ),
                  FxHelpTip(
                    'Detalhe',
                    'Toque na linha abre o check-in daquele treino.',
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
              ),
              child: DecoratedBox(
                decoration: fxStripCardDecoration(
                  context,
                  accent: primary,
                  radius: TokensStrip.rCard,
                  glowStrength: 0.03,
                ),
                child: TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  onChanged: _onQueryChanged,
                  onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Buscar treino',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: TokensStrip.s3,
                      vertical: TokensStrip.s3,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: primary,
                      size: 20,
                    ),
                    suffixIcon:
                        _query.trim().isEmpty
                            ? null
                            : IconButton(
                              tooltip: 'Limpar busca',
                              onPressed: () {
                                _searchDebounce?.cancel();
                                _searchCtrl.clear();
                                setState(() => _query = '');
                                _load(reset: true);
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                color: mute,
                                size: 18,
                              ),
                            ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                0,
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
              ),
              child: Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  for (final chip in HistoricoStatusChip.values)
                    FxToggleChip(
                      label: historicoChipLabel(chip),
                      selected: _chip == chip,
                      isDark: chrome.isDark,
                      onTap: () {
                        setState(() => _chip = chip);
                        _load(reset: true);
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child:
                  _loading && visible.isEmpty
                      ? const Padding(
                        padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                        child: SkeletonList(count: 5),
                      )
                      : _erro != null
                      ? FxErrorState(
                        chromeOnDark: chrome.isDark,
                        primary: primary,
                        message: _erro!,
                        title: FocuxMicrocopy.naoFoiPossivelCarregar,
                        onRetry: () => _load(reset: true),
                      )
                      : FxContentWidthLimiter(child: _buildList(visible)),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildList(List<ExecucaoTreino> visible) {
    final primary = Theme.of(context).colorScheme.primary;
    if (visible.isEmpty) {
      final filtered =
          _query.trim().isNotEmpty || _chip != HistoricoStatusChip.todos;
      return RefreshIndicator(
        color: primary,
        onRefresh: () => _load(reset: true, keepStale: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            if (filtered)
              FxEmptyState(
                icon: 'search',
                title: 'Nenhum treino encontrado',
                subtitle: 'Ajuste a busca ou o filtro para ver outros treinos.',
                action: FxEmptyAction(
                  label: 'Limpar filtros',
                  onTap: () {
                    _searchDebounce?.cancel();
                    _searchCtrl.clear();
                    setState(() {
                      _query = '';
                      _chip = HistoricoStatusChip.todos;
                    });
                    _load(reset: true);
                  },
                ),
              )
            else
              FxEmptyState(
                icon: 'dumbbell',
                title: 'Nenhum treino ainda',
                subtitle: 'Seus treinos concluídos aparecerão aqui.',
                action: FxEmptyAction(
                  label: 'Ver treinos disponíveis',
                  onTap: _abrirTreinos,
                ),
              ),
          ],
        ),
      );
    }

    final showMore = _hasNext;
    final groupTodos = _chip == HistoricoStatusChip.todos;
    final grouped = groupTodos ? historicoGroupByStatus(visible) : null;

    final rows = <Widget>[];
    if (grouped != null) {
      if (grouped.andamento.isNotEmpty) {
        rows.add(
          const Padding(
            padding: EdgeInsets.only(bottom: TokensStrip.s2),
            child: _HistoricoSectionLabel(label: 'Em andamento'),
          ),
        );
        for (final cluster in historicoCollapseSamePlan(grouped.andamento)) {
          rows.add(
            _HistoricoTile(
              entry: cluster.newest,
              count: cluster.count,
              onTap: () => _abrirItem(cluster.newest),
            ),
          );
        }
      }
      if (grouped.concluidos.isNotEmpty) {
        rows.add(
          Padding(
            padding: EdgeInsets.only(
              top: grouped.andamento.isEmpty ? 0 : TokensStrip.s3,
              bottom: TokensStrip.s2,
            ),
            child: const _HistoricoSectionLabel(label: 'Concluído'),
          ),
        );
        for (final cluster in historicoCollapseSamePlan(grouped.concluidos)) {
          rows.add(
            _HistoricoTile(
              entry: cluster.newest,
              count: cluster.count,
              onTap: () => _abrirItem(cluster.newest),
            ),
          );
        }
      }
    } else {
      for (final cluster in historicoCollapseSamePlan(visible)) {
        rows.add(
          _HistoricoTile(
            entry: cluster.newest,
            count: cluster.count,
            onTap: () => _abrirItem(cluster.newest),
          ),
        );
      }
    }
    if (showMore) {
      rows.add(
        FxSatelliteListTile(
          title: _loadingMore ? 'Carregando…' : 'Carregar mais',
          onTap: _loadingMore ? null : () => _load(reset: false),
        ),
      );
    }

    return RefreshIndicator(
      color: primary,
      onRefresh: () => _load(reset: true, keepStale: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        children: rows,
      ),
    );
  }
}

class _HistoricoSectionLabel extends StatelessWidget {
  const _HistoricoSectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final mute = ShellChrome.of(context).mute;
    return Text(
      label.toUpperCase(),
      style: FxSettingsLayout.sectionHeader(color: mute),
    );
  }
}

class _HistoricoTile extends StatelessWidget {
  const _HistoricoTile({
    required this.entry,
    required this.onTap,
    this.count = 1,
  });

  final ExecucaoTreino entry;
  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    final concluido = historicoConcluido(entry.status);
    final dateLabel = historicoDateLabel(entry.iniciadoEm);
    final subtitle = historicoClusterSubtitle(
      dateLabel: dateLabel,
      count: count,
    );
    final statusColor = concluido ? EagleTokens.good : EagleTokens.warn;
    return FxSatelliteListTile(
      title: entry.treinoNome,
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      leading: FxIcon(
        name: concluido ? 'circle-check' : 'calendar',
        size: 22,
        color: statusColor,
      ),
      accent: concluido ? null : EagleTokens.warn,
      trailing: _HistoricoStatusChip(
        label: historicoStatusLabel(entry.status),
        color: statusColor,
      ),
      onTap: entry.id == null ? null : onTap,
    );
  }
}

class _HistoricoStatusChip extends StatelessWidget {
  const _HistoricoStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
