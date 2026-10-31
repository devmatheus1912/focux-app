import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/fcm/fcm_tap_route.dart';
import '../../../core/router/role_home.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/notificacoes_repository.dart';
import '../notificacao_display.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/pt.dart';

part 'notificacoes_screen_widgets.part.dart';

class NotificacoesScreen extends ConsumerStatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  ConsumerState<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends ConsumerState<NotificacoesScreen> {
  final _openedAt = DateTime.now();
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  DateTime? _fetchedAt;
  final _ocultas = <int>{};
  var _viewTracked = false;
  var _ttvTracked = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(Duration(milliseconds: 350), () {
      final next = value.trim();
      if (next == ref.read(notificacoesQueryProvider)) return;
      ref.read(notificacoesQueryProvider.notifier).value = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificacoesProvider);
    ref.listen<AsyncValue<NotificacoesInbox>>(notificacoesProvider, (
      _,
      next,
    ) {
      if (!next.isLoading && next.hasValue) {
        setState(() => _fetchedAt = DateTime.now());
      }
    });

    if (async.hasValue && !_viewTracked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _viewTracked) return;
        _viewTracked = true;
        final inbox = async.requireValue;
        final unread = inbox.items.where((item) => !item.lida).length;
        AnalyticsService.instance.track(
          ProductEvents.notificacoesViewed,
          props: {
            'count': inbox.total,
            'loaded': inbox.items.length,
            'unread': unread,
          },
        );
        if (!_ttvTracked) {
          _ttvTracked = true;
          AnalyticsService.instance.track(
            ProductEvents.notificacoesTtv,
            props: {
              'ms': DateTime.now().difference(_openedAt).inMilliseconds,
              'unread': unread,
            },
          );
        }
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final repo = ref.read(notificacoesRepositoryProvider);
    final home = roleHomePath(ref);
    final query = ref.watch(notificacoesQueryProvider);
    final soNaoLidas = ref.watch(notificacoesSoNaoLidasProvider);
    final inboxAtual = async.value;
    final listaCompleta =
        inboxAtual != null && !inboxAtual.hasMore && query.isEmpty;
    final unreadCount = notificacaoNaoLidasDaTela(
      servidor:
          ref.watch(notificacoesNaoLidasProvider).value ??
          (inboxAtual?.items.where((item) => !item.lida).length ?? 0),
      naLista: inboxAtual == null
          ? null
          : _buildNotificationRows(
              notificacoesVisiveis(inboxAtual.items, ocultas: _ocultas),
            ).where((row) => row.temNaoLida).length,
      listaCompleta: listaCompleta,
    );
    final mostrarBusca =
        query.isNotEmpty ||
        (inboxAtual?.total ?? 0) > notificacaoBuscaAPartirDe;

    Future<void> reload() async {
      AnalyticsService.instance.track(ProductEvents.notificacoesRefreshed);
      ref.invalidate(notificacoesProvider);
      ref.invalidate(notificacoesNaoLidasProvider);
      await ref.read(notificacoesProvider.future);
    }

    void afterRead() {
      ref.invalidate(notificacoesProvider);
      ref.invalidate(notificacoesNaoLidasProvider);
      // O sino da Home lê o BFF cacheado; sem isso ele fica com a contagem velha.
      if (ref.read(userRoleProvider) == UserRole.aluno) {
        invalidateAlunoDashboardHome(ref);
      } else {
        invalidatePersonalDashboardHome(ref);
      }
    }

    String? destinoDe(NotificacaoApp item) {
      final route = item.route;
      if (route == null || !route.startsWith('/')) return null;
      final role = ref.read(userRoleProvider);
      final sanitized = resolveFcmTapRoute(
        {'route': route, 'type': item.tipo},
        role: role == UserRole.aluno ? 'ALUNO' : 'PERSONAL',
      );
      // Rota que só volta para a Home não é destino: o toque apenas marca como lida.
      if (sanitized == null || sanitized == home) return null;
      return sanitized;
    }

    Future<void> openItem(_HubRow row) async {
      final item = row.item;
      AnalyticsService.instance.track(
        ProductEvents.notificacoesOpened,
        props: {'tipo': item.tipo, 'lida': item.lida},
      );
      if (row.temNaoLida) {
        try {
          await Future.wait(row.idsNaoLidos.map(repo.marcarLida));
          afterRead();
        } catch (_) {
          // Abrir o destino importa mais que o estado de leitura.
        }
      }
      final destino = destinoDe(item);
      if (destino != null && context.mounted) {
        context.push(destino);
      }
    }

    Future<void> apagar(_HubRow row) async {
      final ids = row.iguais.map((n) => n.id).toList();
      setState(() => _ocultas.addAll(ids));
      final desfeito = await FeedbackHelper.showUndo(
        context,
        ptS.notificacoesNotificacaoApagada,
      );
      if (desfeito) {
        if (mounted) setState(() => _ocultas.removeAll(ids));
        return;
      }
      try {
        await Future.wait(ids.map(repo.apagar));
      } catch (e) {
        if (!mounted) return;
        setState(() => _ocultas.removeAll(ids));
        FeedbackHelper.showError(this.context, friendlyError(e));
        return;
      }
      if (!mounted) return;
      if (row.temNaoLida) {
        afterRead();
      } else {
        ref.invalidate(notificacoesProvider);
      }
    }

    Future<void> limparLidas() async {
      final ok = await showFxConfirmSheet(
        context,
        title: ptS.notificacoesLimparLidas,
        message: ptS.notificacoesAsNotificacoesJaLidasSaem,
        confirmLabel: ptS.notificacoesLimparLidas2,
        icon: Icons.delete_sweep_outlined,
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      final int removidas;
      try {
        removidas = await repo.apagarLidas();
      } catch (e) {
        if (context.mounted) {
          FeedbackHelper.showError(context, friendlyError(e));
        }
        return;
      }
      ref.invalidate(notificacoesProvider);
      if (!context.mounted) return;
      FeedbackHelper.showSuccess(context, notificacaoRemovidasLabel(removidas));
    }

    void abrirAjuda() {
      AnalyticsService.instance.track(ProductEvents.notificacoesHelpOpened);
      showFxHelpSheet(
        context,
        title: ptS.notifications,
        subtitle: ptS.notificacoesOQuePediuAcaoO,
        tips: [
          FxHelpTip(ptS.alunoHomeAjudaCalculoTitulo, notificacaoComoCalculamos),
          FxHelpTip(
            ptS.notificacoesLista,
            ptS.notificacoesHojeOntemEstaSemanaE,
          ),
          FxHelpTip(
            ptS.notificacaoNaoLidas3,
            ptS.notificacoesTemPontoETituloEm,
          ),
          FxHelpTip(
            ptS.notificacoesApagar,
            ptS.notificacoesArrasteParaAEsquerdaPara,
          ),
        ],
      );
    }

    final lidasCount =
        async.value?.items
            .where((n) => n.lida && !_ocultas.contains(n.id))
            .length ??
        0;

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return fxScreenA11yScope(
      label: ptS.notifications,
      child: PopScope(
        canPop: !keyboardOpen && !_searchFocus.hasFocus,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (keyboardOpen || _searchFocus.hasFocus) {
            FxKeyboardDismissScope.dismiss();
            return;
          }
          FxKeyboardDismissScope.dismiss();
          safePopOrGo(context, home);
        },
        child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: ptS.notifications,
          subtitle: async.maybeWhen(
            data: (inbox) => FxHubFreshness.joinCount(
              notificacaoNaoLidasLabel(unreadCount),
              FxHubFreshness.fromFetchedAt(_fetchedAt),
            ),
            orElse: () => FxHubFreshness.fromFetchedAt(_fetchedAt),
          ),
          onBack: () {
            FxKeyboardDismissScope.dismiss();
            safePopOrGo(context, home);
          },
          actions: [
            if (unreadCount > 0)
              Semantics(
                button: true,
                label: ptS.notificacoesMarcarTodasAsNotificacoesComo,
                child: FxTonalButton(label: ptS.notificacoesLerTodas, onPressed: () async {
                    AnalyticsService.instance.track(
                      ProductEvents.notificacoesMarkedAllRead,
                      props: {'unread': unreadCount},
                    );
                    try {
                      await repo.marcarTodasLidas();
                    } catch (e) {
                      if (context.mounted) {
                        FeedbackHelper.showError(context, friendlyError(e));
                      }
                      return;
                    }
                    afterRead();
                    if (!context.mounted) return;
                    FeedbackHelper.showSuccess(
                      context,
                      ptS.notificacoesTodasMarcadasComoLidas,
                    );
                  }, compact: true),
              ),
            IconButton(
              tooltip: ptS.agendaAlunoMaisOpcoes,
              icon: const Icon(Icons.more_horiz_rounded),
              onPressed: () async {
                final escolha = await showFxGroupedActionSheet<String>(
                  context,
                  titulo: ptS.notifications,
                  grupos: [
                    FxActionGroup<String>(null, [
                      FxActionItem(
                        valor: 'ajuda',
                        rotulo: ptS.notificacoesComoUsarAsNotificacoes,
                        icone: Icons.help_outline_rounded,
                      ),
                      if (lidasCount > 0)
                        FxActionItem(
                          valor: 'limpar',
                          rotulo: ptS.notificacoesLimparLidas2,
                          icone: Icons.delete_sweep_outlined,
                        ),
                    ]),
                  ],
                );
                if (!context.mounted) return;
                if (escolha == 'limpar') await limparLidas();
                if (escolha == 'ajuda') abrirAjuda();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (mostrarBusca) Padding(
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
                  textInputAction: TextInputAction.search,
                  onChanged: _onQueryChanged,
                  onSubmitted: (value) {
                    _debounce?.cancel();
                    final next = value.trim();
                    if (next == ref.read(notificacoesQueryProvider)) return;
                    ref.read(notificacoesQueryProvider.notifier).value = next;
                  },
                  onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                  decoration: InputDecoration(
                    filled: false,
                    isDense: true,
                    hintText: ptS.notificacoesBuscarAviso,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, size: 20),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TokensStrip.s4,
                0,
                TokensStrip.s4,
                TokensStrip.s1,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FxChoiceStrip<bool>(
                  key: const ValueKey('notificacoes-filtros'),
                  itens: [
                    FxChoiceItem(value: false, label: ptS.financeiroFiltroTodas),
                    FxChoiceItem(
                      value: true,
                      label: notificacaoFiltroNaoLidasLabel(unreadCount),
                    ),
                  ],
                  selecionado: soNaoLidas,
                  onSelecionar: (v) =>
                      ref.read(notificacoesSoNaoLidasProvider.notifier).value = v,
                ),
              ),
            ),
            Expanded(
              child: async.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                child: SkeletonList(count: 6),
              ),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: reload,
              ),
          data: (inbox) {
            final items = inbox.items;
            final rows = _buildNotificationRows(
              notificacoesVisiveis(items, ocultas: _ocultas),
            );
            if (rows.isEmpty) {
              final verTodas = query.isEmpty && soNaoLidas;
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  const SizedBox(height: 48),
                  FxEmptyState(
                    icon: query.isEmpty ? 'circle-check' : 'search',
                    title: notificacaoVazioTitle(
                      query: query,
                      soNaoLidas: soNaoLidas,
                    ),
                    subtitle: notificacaoVazioSubtitle(
                      query: query,
                      soNaoLidas: soNaoLidas,
                    ),
                    action: FxEmptyAction(
                      label: verTodas
                          ? ptS.notificacoesVerTodas
                          : query.isEmpty
                          ? ptS.notificacoesIrParaOHoje
                          : ptS.notificacoesLimparBusca,
                      onTap: verTodas
                          ? () => ref.read(notificacoesSoNaoLidasProvider.notifier).value = false
                          : query.isEmpty
                          ? () => goToRoleHome(context, ref)
                          : () {
                              _debounce?.cancel();
                              _searchCtrl.clear();
                              ref.read(notificacoesQueryProvider.notifier).value =
                                  '';
                            },
                    ),
                  ),
                ],
              );
            }
            final dias = <String, List<_HubRow>>{};
            for (final row in rows) {
              dias.putIfAbsent(row.dayGroup, () => []).add(row);
            }
            final grupos = dias.entries.toList();
            final extra = inbox.hasMore ? 1 : 0;
            return RefreshIndicator(
              color: primary,
              onRefresh: reload,
              child: FxContentWidthLimiter(
                child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                itemCount: grupos.length + extra,
                itemBuilder: (context, i) {
                  if (i >= grupos.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: TokensStrip.s3),
                      child: FxSatelliteListTile(
                        title: inbox.loadingMore
                            ? ptS.agendaAlunoCarregando
                            : ptS.retencaoCarregarMais,
                        subtitle: inbox.loadingMore
                            ? null
                            : Text(
                              ptS.notificacoesMaisNestaCaixa(inbox.total - items.length),
                            ),
                        onTap: inbox.loadingMore
                            ? null
                            : () => ref
                                .read(notificacoesProvider.notifier)
                                .loadMore(),
                      ),
                    );
                  }
                  final chrome = ShellChrome.of(context);
                  final grupo = grupos[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: i == 0 ? 0 : TokensStrip.s3,
                          bottom: TokensStrip.s2,
                        ),
                        child: DashboardSectionHeader(title: grupo.key),
                      ),
                      Ink(
                        decoration: chrome.panel(radius: TokensStrip.rCard),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(TokensStrip.rCard),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (n, row) in grupo.value.indexed) ...[
                                if (n > 0)
                                  Divider(
                                    height: 1,
                                    indent: TokensStrip.s3,
                                    endIndent: TokensStrip.s3,
                                    color: chrome.line,
                                  ),
                                Dismissible(
                                  key: ValueKey('notificacao-${row.item.id}'),
                                  direction: DismissDirection.endToStart,
                                  background: const _ApagarFundo(),
                                  onDismissed: (_) => apagar(row),
                                  child: _NotificacaoTile(
                                    item: row.item,
                                    temDestino: destinoDe(row.item) != null,
                                    onTap: () => openItem(row),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              ),
            );
          },
        ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}
