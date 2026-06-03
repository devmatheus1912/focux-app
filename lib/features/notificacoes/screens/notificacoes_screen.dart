import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../data/notificacoes_repository.dart';
import '../notificacao_display.dart';
import '../../../core/theme/tokens_strip.dart';

part 'notificacoes_screen_widgets.part.dart';


class NotificacoesScreen extends ConsumerWidget {
  const NotificacoesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final async = ref.watch(notificacoesProvider);
    final repo = ref.read(notificacoesRepositoryProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final actionInk =
        isDark ? primary : BrandPalette.deep(primary);

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

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Notificações',
        subtitle: 'INBOX',
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
                FeedbackHelper.showSnackBar(
                  context,
                  const SnackBar(
                    content: Text('Todas marcadas como lidas.'),
                  ),
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
                padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 12, 16, 120),
                children: const [SkeletonList(count: 5)],
              ),
          error:
              (_, __) => _NotificationsStateCard(
                isDark: isDark,
                primary: primary,
                actionInk: actionInk,
                icon: 'bell',
                title: 'Não foi possível carregar',
                subtitle: 'Puxe para atualizar ou tente novamente.',
              ),
          data: (items) {
            final entries = _buildNotificationEntries(items);
            if (entries.isEmpty) {
              return _NotificationsStateCard(
                isDark: isDark,
                primary: primary,
                actionInk: actionInk,
                icon: 'circle-check',
                title: 'Tudo em ordem',
                subtitle:
                    'Alertas operacionais, mensagens importantes e Radar Focux aparecem aqui.',
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
    );
  }
}

sealed class _NotificationEntry {
  const _NotificationEntry();
  DateTime? get createdAt;
}

