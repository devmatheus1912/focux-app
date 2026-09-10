import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/rbac_repository.dart';
import '../models/permissao_rbac.dart';

final rbacRepositoryProvider = Provider(
  (ref) => RbacRepository(ref.read(apiClientProvider)),
);

final permissoesRbacProvider = FutureProvider<List<PermissaoRbac>>((ref) async {
  return ref.read(rbacRepositoryProvider).listar();
});

class RbacScreen extends ConsumerWidget {
  const RbacScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissoesAsync = ref.watch(permissoesRbacProvider);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final accent = BrandPalette.softened(primary);
    final mute = chrome.mute;
    final line = chrome.line;

    return fxScreenA11yScope(
      label: 'Controle de acessos',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Controle de acessos',
          subtitle: 'Permissões operacionais',
          onBack: () {
            HapticFeedback.selectionClick();
            safePopOrGo(context, '/perfil');
          },
          actions: [
            FxHelpIconButton(
              tooltip: 'Como funcionam as permissões',
              onTap:
                  () => showFxHelpSheet(
                    context,
                    title: 'Controle de acessos',
                    subtitle: 'Recurso + nível. Só o dono altera.',
                    tips: const [
                      FxHelpTip(
                        'Conceder',
                        'Escolha recurso e nível. Nada muda sozinho.',
                        icon: 'key',
                      ),
                      FxHelpTip(
                        'Revogar',
                        'Abra a linha e confirme. Ação destrutiva.',
                        icon: 'alert-triangle',
                      ),
                    ],
                  ),
            ),
            Semantics(
              button: true,
              label: 'Conceder permissão',
              child: IconButton(
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Conceder permissão',
                onPressed: () => _showConcederPermissao(context, ref),
              ),
            ),
          ],
        ),
        body: permissoesAsync.when(
          loading: () => const SkeletonList(count: 5),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: chrome.isDark,
                primary: accent,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(permissoesRbacProvider),
                title: 'Não carregamos as permissões',
              ),
          data: (permissoes) {
            if (permissoes.isEmpty) {
              return FxEmptyState(
                icon: 'users',
                title: 'Nenhuma permissão configurada',
                subtitle:
                    'Defina níveis de acesso por recurso (Alunos, Financeiro, Treinos…).',
                action: FxEmptyAction(
                  label: 'Conceder permissão',
                  onTap: () => _showConcederPermissao(context, ref),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                FxSettingsLayout.pageInset,
                FxSettingsLayout.pageInset,
                FxSettingsLayout.groupGap * 2,
              ),
              children: [
                FxSettingsGroup(
                  header: 'Permissões',
                  caption: 'Toque para ajustar o nível ou revogar.',
                  children: [
                    for (var i = 0; i < permissoes.length; i++)
                      FxSettingsTile(
                        icon:
                            permissoes[i].nivel == 'ADMIN'
                                ? Icons.security_outlined
                                : Icons.vpn_key_outlined,
                        label: permissoes[i].recurso,
                        value: permissoes[i].nivel,
                        mute: mute,
                        line: line,
                        showDivider: i < permissoes.length - 1,
                        onTap:
                            () => _showGerenciarPermissao(
                              context,
                              ref,
                              permissoes[i],
                            ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _revogarPermissao(
    BuildContext context,
    WidgetRef ref,
    String recurso,
  ) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Revogar $recurso?',
      message: 'Quem usava este acesso perde na hora.',
      confirmLabel: 'Revogar',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(rbacRepositoryProvider).revogar(recurso);
      ref.invalidate(permissoesRbacProvider);
      if (context.mounted) {
        FeedbackHelper.showSuccess(context, 'Permissão revogada');
      }
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _showGerenciarPermissao(
    BuildContext context,
    WidgetRef ref,
    PermissaoRbac permissao,
  ) async {
    var nivel = permissao.nivel;
    await showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;
        final mute = ShellChrome.forDark(isDark).mute;
        final line = ShellChrome.forDark(isDark).line;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return FxHomeSheetSurface(
              isDark: isDark,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FxHomeSheetHandle(isDark: isDark),
                  SizedBox(height: TokensStrip.s4),
                  FxHomeSheetHeader(
                    isDark: isDark,
                    title: permissao.recurso,
                    subtitle: 'Ajuste o nível ou revogue o acesso.',
                    leading: Icon(
                      Icons.vpn_key_outlined,
                      color: primary,
                      size: 18,
                    ),
                  ),
                  SizedBox(height: TokensStrip.s3),
                  FxSettingsGroup(
                    children: [
                      FxSettingsTile(
                        icon: Icons.tune_outlined,
                        label: 'Nível',
                        value: nivel,
                        mute: mute,
                        line: line,
                        picker: true,
                        showDivider: false,
                        onTap: () async {
                          final picked = await showFxInsetPickerSheet<String>(
                            ctx,
                            title: 'Nível',
                            selected: nivel,
                            items: [
                              for (final n in permissoesRbacNiveis)
                                FxInsetPickerSheetItem(value: n, label: n),
                            ],
                          );
                          if (picked == null) return;
                          setState(() => nivel = picked);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: TokensStrip.s4),
                  FxLiquidPrimaryButton(
                    label: 'Salvar nível',
                    onPressed:
                        nivel == permissao.nivel
                            ? null
                            : () async {
                              try {
                                await ref
                                    .read(rbacRepositoryProvider)
                                    .conceder(
                                      recurso: permissao.recurso,
                                      nivel: nivel,
                                    );
                                ref.invalidate(permissoesRbacProvider);
                                if (ctx.mounted) {
                                  FxHomeSheetChrome.dismissAndPop(ctx);
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  FeedbackHelper.showError(
                                    ctx,
                                    friendlyError(e),
                                  );
                                }
                              }
                            },
                  ),
                  TextButton(
                    onPressed: () async {
                      FxHomeSheetChrome.dismissAndPop(ctx);
                      if (context.mounted) {
                        await _revogarPermissao(
                          context,
                          ref,
                          permissao.recurso,
                        );
                      }
                    },
                    child: Text(
                      'Revogar acesso',
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showConcederPermissao(BuildContext context, WidgetRef ref) {
    var recursoSelecionado = permissoesRbacRecursos.first;
    var nivelSelecionado = permissoesRbacNiveis.first;

    showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;
        final mute = ShellChrome.forDark(isDark).mute;
        final line = ShellChrome.forDark(isDark).line;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return FxHomeSheetSurface(
              isDark: isDark,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FxHomeSheetHandle(isDark: isDark),
                  SizedBox(height: TokensStrip.s4),
                  FxHomeSheetHeader(
                    isDark: isDark,
                    title: 'Conceder permissão',
                    subtitle: 'Escolha o recurso e o nível de acesso.',
                    leading: Icon(
                      Icons.vpn_key_outlined,
                      color: primary,
                      size: 18,
                    ),
                  ),
                  SizedBox(height: TokensStrip.s3),
                  FxSettingsGroup(
                    children: [
                      FxSettingsTile(
                        icon: Icons.folder_outlined,
                        label: 'Recurso',
                        value: recursoSelecionado,
                        mute: mute,
                        line: line,
                        picker: true,
                        onTap: () async {
                          final picked = await showFxInsetPickerSheet<String>(
                            ctx,
                            title: 'Recurso',
                            selected: recursoSelecionado,
                            items: [
                              for (final r in permissoesRbacRecursos)
                                FxInsetPickerSheetItem(value: r, label: r),
                            ],
                          );
                          if (picked == null) return;
                          setState(() => recursoSelecionado = picked);
                        },
                      ),
                      FxSettingsTile(
                        icon: Icons.tune_outlined,
                        label: 'Nível',
                        value: nivelSelecionado,
                        mute: mute,
                        line: line,
                        picker: true,
                        showDivider: false,
                        onTap: () async {
                          final picked = await showFxInsetPickerSheet<String>(
                            ctx,
                            title: 'Nível',
                            selected: nivelSelecionado,
                            items: [
                              for (final n in permissoesRbacNiveis)
                                FxInsetPickerSheetItem(value: n, label: n),
                            ],
                          );
                          if (picked == null) return;
                          setState(() => nivelSelecionado = picked);
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: TokensStrip.s4),
                  FxLiquidPrimaryButton(
                    label: 'Salvar',
                    onPressed: () async {
                      try {
                        await ref
                            .read(rbacRepositoryProvider)
                            .conceder(
                              recurso: recursoSelecionado,
                              nivel: nivelSelecionado,
                            );
                        ref.invalidate(permissoesRbacProvider);
                        if (ctx.mounted) {
                          FxHomeSheetChrome.dismissAndPop(ctx);
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          FeedbackHelper.showError(ctx, friendlyError(e));
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
