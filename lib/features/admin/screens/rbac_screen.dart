import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
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
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Controle de Acessos',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Controle de Acessos',
          subtitle: 'Permissões operacionais do personal',
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Conceder permissão',
              onPressed: () => _showConcederPermissao(context, ref),
            ),
          ],
        ),
        body: permissoesAsync.when(
          loading: () => const Center(child: FxLoading()),
          error:
              (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(TokensStrip.s5),
                  child: Text(friendlyError(e), textAlign: TextAlign.center),
                ),
              ),
          data: (permissoes) {
            if (permissoes.isEmpty) {
              return FxEmptyState(
                icon: 'shield',
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
                        p.nivel == 'ADMIN'
                            ? Icons.security
                            : Icons.vpn_key,
                        color:
                            p.nivel == 'ADMIN' ? EagleTokens.bad : primary,
                      ),
                    ),
                    title: Text(
                      p.recurso,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('Nível: ${p.nivel}'),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: EagleTokens.bad,
                      ),
                      tooltip: 'Revogar permissão',
                      onPressed: () => _revogarPermissao(context, ref, p.recurso),
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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                20,
                16,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Conceder permissão',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  DropdownButtonFormField<String>(
                    initialValue: recursoSelecionado,
                    decoration: FxInputDeco.build(context, 'Recurso'),
                    items:
                        permissoesRbacRecursos
                            .map(
                              (r) => DropdownMenuItem(value: r, child: Text(r)),
                            )
                            .toList(),
                    onChanged:
                        (v) => setState(() => recursoSelecionado = v!),
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  DropdownButtonFormField<String>(
                    initialValue: nivelSelecionado,
                    decoration: FxInputDeco.build(context, 'Nível'),
                    items:
                        permissoesRbacNiveis
                            .map(
                              (n) => DropdownMenuItem(
                                value: n,
                                child: Text(n),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => nivelSelecionado = v!),
                  ),
                  const SizedBox(height: TokensStrip.s5),
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
