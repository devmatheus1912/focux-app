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
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/notificacoes_repository.dart';
import '../notificacao_display.dart';

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
  var _soNaoLidas = false;
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
    _debounce = Timer(const Duration(milliseconds: 350), () {
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
    final unreadCount =
        ref.watch(notificacoesNaoLidasProvider).value ??
        (async.value?.items.where((item) => !item.lida).length ?? 0);
    final query = ref.watch(notificacoesQueryProvider);

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

    Future<void> openItem(NotificacaoApp item) async {
      AnalyticsService.instance.track(
        ProductEvents.notificacoesOpened,
        props: {'tipo': item.tipo, 'lida': item.lida},
      );
      if (!item.lida) {
        try {
          await repo.marcarLida(item.id);
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

    Future<void> apagar(NotificacaoApp item) async {
      setState(() => _ocultas.add(item.id));
      final controller = FeedbackHelper.showSnackBar(
        context,
        SnackBar(
          content: const Text('Notificação apagada.'),
          duration: const Duration(seconds: 4),
          persist: false,
          action: SnackBarAction(label: 'Desfazer', onPressed: () {}),
        ),
      );
      final reason = await controller?.closed;
      if (reason == SnackBarClosedReason.action) {
        if (mounted) setState(() => _ocultas.remove(item.id));
        return;
      }
      try {
        await repo.apagar(item.id);
      } catch (e) {
        if (!mounted) return;
        setState(() => _ocultas.remove(item.id));
        FeedbackHelper.showError(this.context, friendlyError(e));
        return;
      }
      if (!mounted) return;
      if (item.lida) {
        ref.invalidate(notificacoesProvider);
      } else {
        afterRead();
      }
    }

    Future<void> limparLidas() async {
      final ok = await showFxConfirmSheet(
        context,
        title: 'Limpar lidas?',
        message: 'As notificações já lidas saem da lista. As não lidas ficam.',
        confirmLabel: 'Limpar lidas',
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

    final lidasCount =
        async.value?.items
            .where((n) => n.lida && !_ocultas.contains(n.id))
            .length ??
        0;

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return fxScreenA11yScope(
      label: 'Notificações',
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
          title: 'Notificações',
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
            FxHelpIconButton(
              tooltip: 'Como usar as notificações',
              onTap: () {
                AnalyticsService.instance.track(
                  ProductEvents.notificacoesHelpOpened,
                );
                showFxHelpSheet(
                  context,
                  title: 'Notificações',
                  subtitle: 'O que pediu ação. O destino abre no toque.',
                  tips: const [
                    FxHelpTip('Como calculamos', notificacaoComoCalculamos),
                    FxHelpTip(
                      'Lista',
                      'Hoje, ontem e anteriores. Toque abre o aluno, o treino ou o aviso.',
                    ),
                    FxHelpTip(
                      'Não lidas',
                      'Têm ponto e título em negrito. Ler todas zera o sino da Home.',
                    ),
                    FxHelpTip(
                      'Apagar',
                      'Arraste para a esquerda para apagar uma. Limpar lidas tira todas as já vistas.',
                    ),
                  ],
                );
              },
            ),
            if (unreadCount > 0)
              Semantics(
                button: true,
                label: 'Marcar todas as notificações como lidas',
                child: TextButton(
                  onPressed: () async {
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
                      'Todas marcadas como lidas.',
                    );
                  },
                  child: const Text('Ler todas'),
                ),
              ),
            if (lidasCount > 0)
              IconButton(
                tooltip: 'Limpar lidas',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: limparLidas,
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
                  textInputAction: TextInputAction.search,
                  onChanged: _onQueryChanged,
                  onSubmitted: (value) {
                    _debounce?.cancel();
                    final next = value.trim();
                    if (next == ref.read(notificacoesQueryProvider)) return;
                    ref.read(notificacoesQueryProvider.notifier).value = next;
                  },
                  onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                  decoration: const InputDecoration(
                    filled: false,
                    isDense: true,
                    hintText: 'Buscar aviso',
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
              child: Row(
                children: [
                  FxToggleChip(
                    label: 'Todas',
                    selected: !_soNaoLidas,
                    isDark: isDark,
                    onTap: () => setState(() => _soNaoLidas = false),
                  ),
                  const SizedBox(width: TokensStrip.s2),
                  FxToggleChip(
                    key: const ValueKey('notificacoes-filtro-nao-lidas'),
                    label: notificacaoFiltroNaoLidasLabel(unreadCount),
                    selected: _soNaoLidas,
                    isDark: isDark,
                    onTap: () => setState(() => _soNaoLidas = true),
                  ),
                ],
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
              notificacoesVisiveis(
                items,
                ocultas: _ocultas,
                soNaoLidas: _soNaoLidas,
              ),
            );
            if (rows.isEmpty) {
              final verTodas = query.isEmpty && _soNaoLidas;
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
                      soNaoLidas: _soNaoLidas,
                    ),
                    subtitle: notificacaoVazioSubtitle(
                      query: query,
                      soNaoLidas: _soNaoLidas,
                    ),
                    action: FxEmptyAction(
                      label: verTodas
                          ? 'Ver todas'
                          : query.isEmpty
                          ? 'Ir para o Hoje'
                          : 'Limpar busca',
                      onTap: verTodas
                          ? () => setState(() => _soNaoLidas = false)
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
                itemCount: rows.length + extra,
                itemBuilder: (context, i) {
                  if (i >= rows.length) {
                    return FxSatelliteListTile(
                      title: inbox.loadingMore
                          ? 'Carregando…'
                          : 'Carregar mais',
                      subtitle: inbox.loadingMore
                          ? null
                          : Text(
                            'Mais ${inbox.total - items.length} nesta caixa.',
                          ),
                      onTap: inbox.loadingMore
                          ? null
                          : () => ref
                              .read(notificacoesProvider.notifier)
                              .loadMore(),
                    );
                  }
                  final row = rows[i];
                  final showDay =
                      i == 0 || rows[i - 1].dayGroup != row.dayGroup;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showDay)
                        Padding(
                          padding: EdgeInsets.only(
                            top: i == 0 ? 0 : TokensStrip.s3,
                            bottom: TokensStrip.s2,
                          ),
                          child: DashboardSectionHeader(title: row.dayGroup),
                        ),
                      Dismissible(
                        key: ValueKey('notificacao-${row.item.id}'),
                        direction: DismissDirection.endToStart,
                        background: const _ApagarFundo(),
                        onDismissed: (_) => apagar(row.item),
                        child: _NotificacaoTile(
                          item: row.item,
                          temDestino: destinoDe(row.item) != null,
                          onTap: () => openItem(row.item),
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
