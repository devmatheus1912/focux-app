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
    _load(reset: true);
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

  Future<void> _load({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _erro = null;
        _items.clear();
        _nextCursor = null;
        _hasNext = false;
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
        _items.addAll(pagina.content);
        _hasNext = pagina.hasNext;
        _nextCursor = pagina.nextCursor;
        _loading = false;
        _loadingMore = false;
        if (reset) {
          _fetchedAt = DateTime.now();
          ref.invalidate(historicoCheckinProvider);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
        _loadingMore = false;
      });
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
    context.push(historicoDetalhePath(id));
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
              padding: const EdgeInsets.fromLTRB(
                TokensStrip.s4,
                TokensStrip.s2,
                TokensStrip.s4,
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
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
              padding: const EdgeInsets.fromLTRB(
                TokensStrip.s4,
                0,
                TokensStrip.s4,
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
                  _loading
                      ? const Padding(
                        padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                        child: SkeletonList(count: 6),
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
        onRefresh: () => _load(reset: true),
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
    return RefreshIndicator(
      color: primary,
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        itemCount: visible.length + (showMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (showMore && i == visible.length) {
            return FxSatelliteListTile(
              title: _loadingMore ? 'Carregando…' : 'Carregar mais',
              onTap: _loadingMore ? null : () => _load(reset: false),
            );
          }
          return _HistoricoTile(
            entry: visible[i],
            onTap: () => _abrirItem(visible[i]),
          );
        },
      ),
    );
  }
}

class _HistoricoTile extends StatelessWidget {
  const _HistoricoTile({required this.entry, required this.onTap});

  final ExecucaoTreino entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final concluido = historicoConcluido(entry.status);
    final dateLabel = historicoDateLabel(entry.iniciadoEm);
    return FxSatelliteListTile(
      title: entry.treinoNome,
      subtitle:
          dateLabel.isEmpty
              ? Text(historicoStatusLabel(entry.status))
              : Text('$dateLabel · ${historicoStatusLabel(entry.status)}'),
      leading: FxIcon(
        name: concluido ? 'circle-check' : 'calendar',
        size: 22,
        color: concluido ? EagleTokens.good : EagleTokens.warn,
      ),
      accent: concluido ? null : EagleTokens.warn,
      onTap: entry.id == null ? null : onTap,
    );
  }
}
