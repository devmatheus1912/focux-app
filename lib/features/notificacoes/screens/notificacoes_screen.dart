import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/role_home.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/notificacoes_repository.dart';
import '../notificacao_display.dart';
import '../widgets/notificacoes_help_sheet.dart';

part 'notificacoes_screen_widgets.part.dart';

class NotificacoesScreen extends ConsumerStatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  ConsumerState<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends ConsumerState<NotificacoesScreen> {
  final _openedAt = DateTime.now();
  DateTime? _fetchedAt;
  var _viewTracked = false;
  var _ttvTracked = false;

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
        context.push(route);
      }
    }

    return fxScreenA11yScope(
      label: 'Notificações',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Notificações',
          subtitle: FxHubFreshness.fromFetchedAt(_fetchedAt),
          onBack: () => safePopOrGo(context, home),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar as notificações',
              onTap: () {
                AnalyticsService.instance.track(
                  ProductEvents.notificacoesHelpOpened,
                );
                showNotificacoesHelpSheet(context);
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
        body: async.when(
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
              return FxEmptyState(
                icon: 'circle-check',
                title: 'Tudo em ordem',
                subtitle:
                    'Alertas, mensagens e o Radar Focux aparecem aqui quando pedem ação.',
              );
            }
            final extra = inbox.hasMore ? 1 : 0;
            return RefreshIndicator(
              color: primary,
              onRefresh: reload,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s6,
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
            );
          },
        ),
      ),
    );
  }
}
