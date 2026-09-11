import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/fcm/fcm_tap_route.dart';
import '../../../core/router/role_home.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
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
      ref.read(notificacoesQueryProvider.notifier).state = next;
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
        ref.watch(notificacoesNaoLidasProvider).valueOrNull ??
        (async.valueOrNull?.items.where((item) => !item.lida).length ?? 0);
    final query = ref.watch(notificacoesQueryProvider);

    Future<void> reload() async {
      AnalyticsService.instance.track(ProductEvents.notificacoesRefreshed);
      ref.invalidate(notificacoesProvider);
      ref.invalidate(notificacoesNaoLidasProvider);
      await ref.read(notificacoesProvider.future);
    }

    Future<void> openItem(NotificacaoApp item) async {
      AnalyticsService.instance.track(
        ProductEvents.notificacoesOpened,
        props: {'tipo': item.tipo, 'lida': item.lida},
      );
      if (!item.lida) {
        await repo.marcarLida(item.id);
        ref.invalidate(notificacoesProvider);
        ref.invalidate(notificacoesNaoLidasProvider);
      }
      final route = item.route;
      if (route != null && route.startsWith('/') && context.mounted) {
        final role = ref.read(userRoleProvider);
        final roleStr = role == UserRole.aluno ? 'ALUNO' : 'PERSONAL';
        final sanitized = resolveFcmTapRoute(
          {'route': route, 'type': item.tipo},
          role: roleStr,
        );
        if (sanitized != null && context.mounted) {
          context.push(sanitized);
        }
      }
    }

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
              notificacaoCountLabel(inbox.total),
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
                      'Ficam em destaque. Ler todas zera o sino da Home.',
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
                    await repo.marcarTodasLidas();
                    ref.invalidate(notificacoesProvider);
                    ref.invalidate(notificacoesNaoLidasProvider);
                    if (!context.mounted) return;
                    FeedbackHelper.showSuccess(
                      context,
                      'Todas marcadas como lidas.',
                    );
                  },
                  child: const Text('Ler todas'),
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
                  textInputAction: TextInputAction.search,
                  onChanged: _onQueryChanged,
                  onSubmitted: (value) {
                    _debounce?.cancel();
                    final next = value.trim();
                    if (next == ref.read(notificacoesQueryProvider)) return;
                    ref.read(notificacoesQueryProvider.notifier).state = next;
                  },
                  onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                  decoration: const InputDecoration(
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
            final rows = _buildNotificationRows(items);
            if (rows.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  const SizedBox(height: 48),
                  FxEmptyState(
                    icon: query.isEmpty ? 'circle-check' : 'search',
                    title: notificacaoSearchEmptyTitle(query),
                    subtitle: notificacaoSearchEmptySubtitle(query),
                    action: FxEmptyAction(
                      label: query.isEmpty ? 'Ir para o Hoje' : 'Limpar busca',
                      onTap: query.isEmpty
                          ? () => goPersonalShellTab(context, home)
                          : () {
                              _debounce?.cancel();
                              _searchCtrl.clear();
                              ref.read(notificacoesQueryProvider.notifier).state =
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
                      FxSatelliteListTile(
                        title: notificationHumanTitle(row.item),
                        subtitle: Text(notificationSubtitle(row.item)),
                        trailing: Text(
                          notificationTimeLabel(row.item.criadaEm),
                          style: FocuxHubTypography.bodyMuted(
                            color: fxScreenMute(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        accent: row.item.lida ? null : primary,
                        onTap: () => openItem(row.item),
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
