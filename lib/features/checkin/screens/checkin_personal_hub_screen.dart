import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_grouped_list.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../models/checkin_personal_home.dart';
import '../providers/checkin_provider.dart';
import '../widgets/checkin_personal_help_sheet.dart';

class CheckinPersonalHubScreen extends ConsumerStatefulWidget {
  const CheckinPersonalHubScreen({super.key});

  @override
  ConsumerState<CheckinPersonalHubScreen> createState() =>
      _CheckinPersonalHubScreenState();
}

class _CheckinPersonalHubScreenState
    extends ConsumerState<CheckinPersonalHubScreen> {
  final _openedAt = DateTime.now();
  DateTime? _fetchedAt;
  var _viewTracked = false;
  var _ttvTracked = false;

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(checkinPersonalHomeProvider);
    ref.listen<AsyncValue<CheckinPersonalHomeBundle>>(
      checkinPersonalHomeProvider,
      (_, next) {
        if (!next.isLoading && next.hasValue) {
          setState(() => _fetchedAt = DateTime.now());
        }
      },
    );

    if (homeAsync.hasValue && !_viewTracked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _viewTracked) return;
        _viewTracked = true;
        final home = homeAsync.requireValue;
        AnalyticsService.instance.track(
          ProductEvents.checkinHubViewed,
          props: {
            'hoje': home.checkinsHoje,
            'semana': home.semana.length,
          },
        );
        if (!_ttvTracked) {
          _ttvTracked = true;
          AnalyticsService.instance.track(
            ProductEvents.checkinHubTtv,
            props: {
              'ms': DateTime.now().difference(_openedAt).inMilliseconds,
              'hoje': home.checkinsHoje,
            },
          );
        }
      });
    }

    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Check-ins',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Check-ins',
          subtitle: freshness,
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar os check-ins',
              onTap: () {
                AnalyticsService.instance.track(
                  ProductEvents.checkinHubHelpOpened,
                );
                showCheckinPersonalHelpSheet(context);
              },
            ),
          ],
        ),
        body: homeAsync.when(
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
                onRetry: () => ref.invalidate(checkinPersonalHomeProvider),
              ),
          data: (home) {
            final rows = <_HubRow>[
              for (final item in home.hoje) _HubRow(item: item, section: 'hoje'),
              for (final item in home.semana)
                _HubRow(item: item, section: 'semana'),
            ];
            if (rows.isEmpty) {
              return FxEmptyState(
                icon: 'dumbbell',
                title: 'Nenhum check-in nesta semana',
                subtitle:
                    'Quando o aluno concluir um treino, ele aparece aqui. '
                    'A conta de hoje é a mesma do pulso da Home.',
                action: FxEmptyAction(
                  label: 'Ver alunos',
                  onTap: () => context.go('/alunos'),
                ),
              );
            }
            return RefreshIndicator(
              color: primary,
              onRefresh: () async {
                AnalyticsService.instance.track(
                  ProductEvents.checkinHubRefreshed,
                );
                ref.invalidate(checkinPersonalHomeProvider);
                await ref.read(checkinPersonalHomeProvider.future);
              },
              child: FxSettingsGroupedList(
                header: home.checkinsHoje == 1
                    ? '1 check-in hoje'
                    : '${home.checkinsHoje} check-ins hoje',
                caption: home.semana.isEmpty
                    ? 'Toque no aluno para abrir o 360.'
                    : 'Hoje e os 6 dias anteriores. Toque para abrir o 360.',
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final row = rows[i];
                  final showSection = i == 0 || rows[i - 1].section != row.section;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showSection && row.section == 'semana')
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            FxSettingsLayout.groupPadH,
                            10,
                            FxSettingsLayout.groupPadH,
                            4,
                          ),
                          child: Text(
                            'Últimos 6 dias',
                            style: FxSettingsLayout.sectionHeader(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      FxSettingsTile(
                        fxIcon: 'circle-check',
                        label: row.item.alunoNome,
                        subtitle: row.item.treinoNome,
                        value: row.item.iniciadoEm == null
                            ? ''
                            : fxTimeAgo(row.item.iniciadoEm!),
                        showDivider: i < rows.length - 1,
                        accessory: AlunoAvatar(
                          name: row.item.alunoNome,
                          photoUrl: row.item.fotoUrl,
                          variant: AlunoAvatarVariant.strip,
                        ),
                        semanticsLabel:
                            '${row.item.alunoNome}. ${row.item.treinoNome}',
                        onTap: () => context.push('/alunos/${row.item.alunoId}'),
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

class _HubRow {
  const _HubRow({required this.item, required this.section});

  final CheckinPersonalItem item;
  final String section;
}
