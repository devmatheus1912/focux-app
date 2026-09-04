import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/winback_repository.dart';
import '../utils/winback_display.dart';

final winbackRepositoryProvider = Provider(
  (ref) => WinbackRepository(ref.read(apiClientProvider)),
);

class WinbackScreen extends ConsumerStatefulWidget {
  const WinbackScreen({super.key});

  @override
  ConsumerState<WinbackScreen> createState() => _WinbackScreenState();
}

class _WinbackScreenState extends ConsumerState<WinbackScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  var _query = '';
  List<WinbackLogEntry> _entries = [];
  var _page = 0;
  var _hasMore = false;
  var _total = 0;
  var _loading = true;
  var _carregandoMais = false;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final next = value.trim();
      if (next == _query) return;
      _query = next;
      _carregar();
    });
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final page = await ref.read(winbackRepositoryProvider).log(q: _query);
      if (!mounted) return;
      setState(() {
        _entries = List.of(page.itens);
        _page = page.page;
        _hasMore = page.hasNext;
        _total = page.totalItens;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = friendlyError(e);
      });
    }
  }

  Future<void> _carregarMais() async {
    if (_carregandoMais || !_hasMore) return;
    setState(() => _carregandoMais = true);
    try {
      final next = await ref
          .read(winbackRepositoryProvider)
          .log(page: _page + 1, q: _query);
      if (!mounted) return;
      final seen = _entries.map((e) => '${e.alunoId}-${e.enviadoEm}').toSet();
      setState(() {
        _entries = [
          ..._entries,
          ...next.itens.where((e) => seen.add('${e.alunoId}-${e.enviadoEm}')),
        ];
        _page = next.page;
        _hasMore = next.hasNext;
        _total = next.totalItens;
        _carregandoMais = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregandoMais = false);
    }
  }

  void _abrirRetencao() {
    HapticFeedback.selectionClick();
    goPersonalShellTab(context, '/retencao');
  }

  void _abrirAluno(WinbackLogEntry entry) {
    final id = entry.alunoId;
    if (id == null || id <= 0) return;
    AnalyticsService.instance.track(ProductEvents.alunosViewed);
    context.push('/alunos/$id', extra: entry.alunoNome);
  }

  void _abrirChat(WinbackLogEntry entry) {
    final id = entry.alunoId;
    if (id == null || id <= 0) return;
    context.push('/alunos/$id/chat', extra: entry.alunoNome);
  }

  void _abrirCobranca(WinbackLogEntry entry) {
    final id = entry.alunoId;
    if (id == null || id <= 0) return;
    AnalyticsService.instance.track(ProductEvents.financeiroViewed);
    context.push('/financeiro?alunoId=$id');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Win-back automático',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Win-back automático',
          subtitle: winbackHubSubtitle(freshness),
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como funciona o win-back',
              onTap: () => showFxHelpSheet(
                context,
                title: 'Win-back',
                subtitle: 'Push automático para aluno inativo.',
                tips: const [
                  FxHelpTip('Como calculamos', winbackComoCalculamos),
                  FxHelpTip(
                    'Lista',
                    'Toque no aluno para o 360. Trial do personal não aparece aqui.',
                  ),
                  FxHelpTip(
                    'Retenção',
                    'A saúde da base continua em Retenção.',
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _loading
            ? const SkeletonList(count: 5)
            : _erro != null
            ? FxErrorState(
              chromeOnDark: isDark,
              primary: primary,
              message: _erro!,
              onRetry: _carregar,
            )
            : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s4,
                    TokensStrip.s2,
                    TokensStrip.s4,
                    TokensStrip.s2,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onChanged: _onQueryChanged,
                    onSubmitted: (value) {
                      _debounce?.cancel();
                      final next = value.trim();
                      if (next == _query && _entries.isNotEmpty) return;
                      _query = next;
                      _carregar();
                    },
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    decoration: FxInputDeco.build(context, 'Buscar aluno'),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
              color: primary,
              onRefresh: _carregar,
              child: _entries.isEmpty
                  ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      const SizedBox(height: 48),
                      FxEmptyState(
                        icon: 'bell',
                        title: winbackSearchEmptyTitle(_query),
                        subtitle: winbackSearchEmptySubtitle(_query),
                        action: _query.isEmpty
                            ? FxEmptyAction(
                                label: 'Saúde da base',
                                onTap: _abrirRetencao,
                              )
                            : null,
                      ),
                    ],
                  )
                  : FxContentWidthLimiter(
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.all(TokensStrip.s4),
                      itemCount: _entries.length + (_hasMore ? 2 : 1),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          final first = _entries.first;
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: TokensStrip.s3,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _WinbackFocusCard(
                                  total: _total,
                                  first: first,
                                  isDark: isDark,
                                  onAluno: () => _abrirAluno(first),
                                  onChat: () => _abrirChat(first),
                                  onCobrar: () => _abrirCobranca(first),
                                  onRetencao: _abrirRetencao,
                                ),
                                const SizedBox(height: TokensStrip.s4),
                                const DashboardSectionHeader(title: 'Envios'),
                              ],
                            ),
                          );
                        }
                        if (_hasMore && index == _entries.length + 1) {
                          return FxSatelliteListTile(
                            title: _carregandoMais
                                ? 'Carregando…'
                                : 'Carregar mais',
                            onTap: _carregandoMais ? null : _carregarMais,
                          );
                        }
                        final entry = _entries[index - 1];
                        return FxSatelliteListTile(
                          title: winbackAlunoLabel(entry.alunoNome),
                          subtitle: Text(
                            winbackSubtitle(
                              tipo: entry.tipo,
                              mensagem: entry.mensagem,
                            ),
                          ),
                          trailing: Text(
                            winbackWhenLabel(entry.enviadoEm),
                            style: FocuxHubTypography.bodyMuted(
                              color: fxScreenMute(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: entry.alunoId == null
                              ? null
                              : () => _abrirAluno(entry),
                        );
                      },
                    ),
                  ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

class _WinbackFocusCard extends StatelessWidget {
  const _WinbackFocusCard({
    required this.total,
    required this.first,
    required this.isDark,
    required this.onAluno,
    required this.onChat,
    required this.onCobrar,
    required this.onRetencao,
  });

  final int total;
  final WinbackLogEntry first;
  final bool isDark;
  final VoidCallback onAluno;
  final VoidCallback onChat;
  final VoidCallback onCobrar;
  final VoidCallback onRetencao;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final canOpen = first.alunoId != null && first.alunoId! > 0;
    return FxStripCard(
      emphasize: true,
      semanticsLabel:
          '${winbackCountLabel(total)}. Último ${winbackAlunoLabel(first.alunoNome)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Último envio', style: FocuxHubTypography.chip(chrome.mute)),
          const SizedBox(height: 6),
          InkWell(
            onTap: canOpen ? onAluno : null,
            child: Text(
              winbackAlunoLabel(first.alunoNome),
              style: FocuxHubTypography.kpi(
                color: chrome.ink,
                fontSize: FocuxHubTypography.metricLg,
              ),
            ),
          ),
            const SizedBox(height: 6),
            Text(
              '${winbackCountLabel(total)} · ${winbackTipoLabel(first.tipo)}',
              style: FocuxHubTypography.body(
                color: chrome.ink,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: TokensStrip.s3),
            Wrap(
              spacing: TokensStrip.s2,
              runSpacing: TokensStrip.s2,
              children: [
                if (canOpen)
                  DashboardHomeActionChip(
                    label: 'Escrever',
                    accent: Theme.of(context).colorScheme.primary,
                    isDark: isDark,
                    onPressed: onChat,
                  ),
                if (canOpen)
                  DashboardHomeActionChip(
                    label: 'Cobrar',
                    accent: EagleTokens.moneyGreen,
                    isDark: isDark,
                    onPressed: onCobrar,
                  ),
                if (!canOpen)
                  DashboardHomeActionChip(
                    label: 'Saúde da base',
                    accent: Theme.of(context).colorScheme.primary,
                    isDark: isDark,
                    onPressed: onRetencao,
                  ),
              ],
            ),
          ],
        ),
    );
  }
}
