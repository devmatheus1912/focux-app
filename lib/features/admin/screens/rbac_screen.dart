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
import '../../auth/providers/auth_provider.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class PermissaoModel {
  final int id;
  final int personalOwnerId;
  final int usuarioConvidadoId;
  final String recurso;
  final String nivelAcesso;

  PermissaoModel({
    required this.id,
    required this.personalOwnerId,
    required this.usuarioConvidadoId,
    required this.recurso,
    required this.nivelAcesso,
  });

  factory PermissaoModel.fromJson(Map<String, dynamic> j) => PermissaoModel(
    id: j['id'],
    personalOwnerId: j['personalOwnerId'],
    usuarioConvidadoId: j['usuarioConvidadoId'],
    recurso: j['recurso'],
    nivelAcesso: j['nivelAcesso'],
  );
}

// ─── Providers ────────────────────────────────────────────────────────────────

final permissoesProvider = FutureProvider<List<PermissaoModel>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.dio.get('/api/rbac/permissoes');
  return (res.data as List).map((e) => PermissaoModel.fromJson(e)).toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class RbacScreen extends ConsumerStatefulWidget {
  const RbacScreen({super.key});

  @override
  ConsumerState<RbacScreen> createState() => _RbacScreenState();
}

class _RbacScreenState extends ConsumerState<RbacScreen> {
  @override
  Widget build(BuildContext context) {
    final permissoesAsync = ref.watch(permissoesProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Controle de Acessos',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Controle de Acessos',
          subtitle: 'Permissões da equipe (RBAC)',
          actions: [
            IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Conceder novo acesso',
              onPressed: () => _showConcederAcesso(context, ref),
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
                title: 'Nenhuma permissão especial concedida',
                subtitle:
                    'Conceda acessos pontuais para assistentes da sua equipe.',
                action: FxEmptyAction(
                  label: 'Conceder acesso',
                  onTap: () => _showConcederAcesso(context, ref),
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
                          p.nivelAcesso == 'ADMIN'
                              ? EagleTokens.bad.withValues(alpha: 0.1)
                              : primary.withValues(alpha: 0.1),
                      child: Icon(
                        p.nivelAcesso == 'ADMIN'
                            ? Icons.security
                            : Icons.vpn_key,
                        color:
                            p.nivelAcesso == 'ADMIN'
                                ? EagleTokens.bad
                                : primary,
                      ),
                    ),
                    title: Text(
                      'Recurso: ${p.recurso}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'ID Assistente: ${p.usuarioConvidadoId} • Nível: ${p.nivelAcesso}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: EagleTokens.bad,
                      ),
                      tooltip: 'Revogar acesso',
                      onPressed:
                          () => _revogarAcesso(
                            ref,
                            p.usuarioConvidadoId,
                            p.recurso,
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

  void _showConcederAcesso(BuildContext context, WidgetRef ref) {
    final usuarioIdCtrl = TextEditingController();
    String recursoSelecionado = 'FINANCEIRO';
    String nivelSelecionado = 'READ';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (ctx) => StatefulBuilder(
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
                      'Conceder Acesso',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    TextField(
                      controller: usuarioIdCtrl,
                      decoration: FxInputDeco.build(
                        context,
                        'ID do Usuário/Assistente',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    DropdownButtonFormField<String>(
                      initialValue: recursoSelecionado,
                      decoration: FxInputDeco.build(context, 'Recurso'),
                      items: const [
                        DropdownMenuItem(
                          value: 'FINANCEIRO',
                          child: Text('Financeiro'),
                        ),
                        DropdownMenuItem(
                          value: 'TREINOS',
                          child: Text('Treinos'),
                        ),
                        DropdownMenuItem(
                          value: 'ALUNOS',
                          child: Text('Alunos e CRM'),
                        ),
                        DropdownMenuItem(
                          value: 'CONFIG',
                          child: Text('Configurações'),
                        ),
                      ],
                      onChanged: (v) => setState(() => recursoSelecionado = v!),
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    DropdownButtonFormField<String>(
                      initialValue: nivelSelecionado,
                      decoration: FxInputDeco.build(context, 'Nível de Acesso'),
                      items: const [
                        DropdownMenuItem(
                          value: 'READ',
                          child: Text('Leitura (READ)'),
                        ),
                        DropdownMenuItem(
                          value: 'WRITE',
                          child: Text('Edição (WRITE)'),
                        ),
                        DropdownMenuItem(
                          value: 'ADMIN',
                          child: Text('Administrador (ADMIN)'),
                        ),
                      ],
                      onChanged: (v) => setState(() => nivelSelecionado = v!),
                    ),
                    const SizedBox(height: TokensStrip.s5),
                    FxLiquidPrimaryButton(
                      label: 'Salvar',
                      onPressed: () async {
                        if (usuarioIdCtrl.text.isEmpty) return;
                        final api = ref.read(apiClientProvider);
                        await api.dio.post(
                          '/api/rbac/permissoes',
                          data: {
                            'usuarioConvidadoId': int.parse(usuarioIdCtrl.text),
                            'recurso': recursoSelecionado,
                            'nivelAcesso': nivelSelecionado,
                          },
                        );
                        ref.invalidate(permissoesProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  void _revogarAcesso(WidgetRef ref, int usuarioId, String recurso) async {
    final api = ref.read(apiClientProvider);
    await api.dio.delete(
      '/api/rbac/permissoes/$recurso?usuarioConvidadoId=$usuarioId',
    );
    ref.invalidate(permissoesProvider);
  }
}
