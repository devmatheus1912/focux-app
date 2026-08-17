import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
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
  DateTime? _fetchedAt;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(notificacoesProvider);
    ref.listen<AsyncValue<List<NotificacaoApp>>>(notificacoesProvider, (
      _,
      next,
    ) {
      if (!next.isLoading && next.hasValue) {
        setState(() => _fetchedAt = DateTime.now());
      }
    });
    final repo = ref.read(notificacoesRepositoryProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final actionInk = isDark ? primary : BrandPalette.deep(primary);
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    Future<void> reload() async {
      ref.invalidate(notificacoesProvider);
      ref.invalidate(notificacoesNaoLidasProvider);
    }

    Future<void> openItem(NotificacaoApp item) async {
      if (!item.lida) {
        await repo.marcarLida(item.id);
        await reload();
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
          subtitle: freshnessLabel ?? 'INBOX',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            Semantics(
              button: true,
              label: 'Marcar todas as notificações como lidas',
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: actionInk),
                onPressed: () async {
                  await repo.marcarTodasLidas();
                  await reload();
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
        body: RefreshIndicator(
          onRefresh: reload,
          child: async.when(
            loading:
                () => ListView(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s4,
                    12,
                    16,
                    120,
                  ),
                  children: const [SkeletonList(count: 5)],
                ),
            error:
                (e, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.55,
                      child: FxErrorState(
                        chromeOnDark: isDark,
                        primary: primary,
                        title: FocuxMicrocopy.naoFoiPossivelCarregar,
                        message: friendlyError(e),
                        onRetry: reload,
                      ),
                    ),
                  ],
                ),
            data: (items) {
              final entries = _buildNotificationEntries(items);
              if (entries.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 48),
                    FxEmptyState(
                      icon: 'circle-check',
                      title: 'Tudo em ordem',
                      subtitle:
                          'Alertas operacionais, mensagens importantes e Radar Focux aparecem aqui.',
                    ),
                  ],
                );
              }

              final showQuietFooter = entries.length <= 2;
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 10, 16, 120),
                itemCount: entries.length + (showQuietFooter ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == entries.length) {
                    return _QuietFooter(
                      isDark: isDark,
                      primary: primary,
                      actionInk: actionInk,
                    );
                  }

                  final entry = entries[index];
                  final group = _groupLabel(entry.createdAt);
                  final previousGroup =
                      index == 0
                          ? null
                          : _groupLabel(entries[index - 1].createdAt);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (index == 0 || group != previousGroup)
                        Semantics(
                          header: true,
                          label: 'Notificações de $group',
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(2, 8, 0, 8),
                            child: Text(
                              group.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color:
                                    isDark
                                        ? EagleTokens.darkInkMute
                                        : TokensStrip.textSecondary,
                                letterSpacing: 0.9,
                              ),
                            ),
                          ),
                        ),
                      switch (entry) {
                        _SingleNotificationEntry(:final item) =>
                          _NotificationTile(
                            item: item,
                            isDark: isDark,
                            primary: primary,
                            actionInk: actionInk,
                            onTap: () => openItem(item),
                          ),
                        _RadarNotificationEntry(:final items) =>
                          _RadarNotificationGroup(
                            items: items,
                            isDark: isDark,
                            primary: primary,
                            actionInk: actionInk,
                            onOpen: openItem,
                          ),
                      },
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

sealed class _NotificationEntry {
  const _NotificationEntry();
  DateTime? get createdAt;
}
