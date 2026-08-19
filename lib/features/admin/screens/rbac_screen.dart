import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
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

    return fxScreenA11yScope(
      label: 'Controle de Acessos',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Controle de Acessos',
          subtitle: 'Permissões operacionais do personal',
          actions: [
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
                primary: primary,
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
            return ListView.builder(
              itemCount: permissoes.length,
              padding: const EdgeInsets.all(TokensStrip.s4),
              itemBuilder: (ctx, i) {
                final p = permissoes[i];
                return fxListTileCardShell(
                  context: ctx,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          p.nivel == 'ADMIN'
                              ? EagleTokens.bad.withValues(alpha: 0.1)
                              : primary.withValues(alpha: 0.1),
                      child: Icon(
                        p.nivel == 'ADMIN' ? Icons.security : Icons.vpn_key,
                        color: p.nivel == 'ADMIN' ? EagleTokens.bad : primary,
                      ),
                    ),
                    title: Text(
                      p.recurso,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: chrome.ink,
                      ),
                    ),
                    subtitle: Text(
                      'Nível: ${p.nivel}',
                      style: TextStyle(color: chrome.mute),
                    ),
                    trailing: Semantics(
                      button: true,
                      label: 'Revogar permissão de ${p.recurso}',
                      child: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: EagleTokens.bad,
                        ),
                        tooltip: 'Revogar permissão',
                        onPressed:
                            () => _revogarPermissao(context, ref, p.recurso),
                      ),
                    ),
                  ),
                );
              },
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
    try {
      await ref.read(rbacRepositoryProvider).revogar(recurso);
      ref.invalidate(permissoesRbacProvider);
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  void _showConcederPermissao(BuildContext context, WidgetRef ref) {
    var recursoSelecionado = permissoesRbacRecursos.first;
    var nivelSelecionado = permissoesRbacNiveis.first;

    showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final primary = Theme.of(ctx).colorScheme.primary;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return FxHomeSheetSurface(
              isDark: isDark,
              maxHeight:
                  MediaQuery.sizeOf(ctx).height *
                  FxHomeSheetChrome.maxHeightFactor,
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
                  DropdownButtonFormField<String>(
                    initialValue: recursoSelecionado,
                    decoration: FxInputDeco.build(context, 'Recurso'),
                    items:
                        permissoesRbacRecursos
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => recursoSelecionado = v!),
                  ),
                  SizedBox(height: TokensStrip.s4),
                  DropdownButtonFormField<String>(
                    initialValue: nivelSelecionado,
                    decoration: FxInputDeco.build(context, 'Nível'),
                    items:
                        permissoesRbacNiveis
                            .map(
                              (n) => DropdownMenuItem(value: n, child: Text(n)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => nivelSelecionado = v!),
                  ),
                  SizedBox(height: TokensStrip.s5),
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
                        if (ctx.mounted) Navigator.pop(ctx);
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
