import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';

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

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Controle de Acessos (RBAC)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Conceder novo acesso',
            onPressed: () => _showConcederAcesso(context, ref),
          ),
        ],
      ),
      body: permissoesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (permissoes) {
          if (permissoes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 64, color: const Color(0xFF9CA3AF)),
                  const SizedBox(height: 16),
                  const Text('Nenhuma permissão especial concedida.', style: TextStyle(color: EagleTokens.inkMute)),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: permissoes.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (ctx, i) {
              final p = permissoes[i];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: p.nivelAcesso == 'ADMIN' ? EagleTokens.bad.withValues(alpha: 0.1) : EagleTokens.brand.withValues(alpha: 0.1),
                    child: Icon(
                      p.nivelAcesso == 'ADMIN' ? Icons.security : Icons.vpn_key,
                      color: p.nivelAcesso == 'ADMIN' ? EagleTokens.bad : EagleTokens.brand,
                    ),
                  ),
                  title: Text('Recurso: ${p.recurso}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('ID Assistente: ${p.usuarioConvidadoId} • Nível: ${p.nivelAcesso}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: EagleTokens.bad),
                    onPressed: () => _revogarAcesso(ref, p.usuarioConvidadoId, p.recurso),
                  ),
                ),
              );
            },
          );
        },
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
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Conceder Acesso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: usuarioIdCtrl,
                decoration: const InputDecoration(labelText: 'ID do Usuário/Assistente', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: recursoSelecionado,
                decoration: const InputDecoration(labelText: 'Recurso', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'FINANCEIRO', child: Text('Financeiro')),
                  DropdownMenuItem(value: 'TREINOS', child: Text('Treinos')),
                  DropdownMenuItem(value: 'ALUNOS', child: Text('Alunos e CRM')),
                  DropdownMenuItem(value: 'CONFIG', child: Text('Configurações')),
                ],
                onChanged: (v) => setState(() => recursoSelecionado = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: nivelSelecionado,
                decoration: const InputDecoration(labelText: 'Nível de Acesso', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'READ', child: Text('Leitura (READ)')),
                  DropdownMenuItem(value: 'WRITE', child: Text('Edição (WRITE)')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('Administrador (ADMIN)')),
                ],
                onChanged: (v) => setState(() => nivelSelecionado = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (usuarioIdCtrl.text.isEmpty) return;
                  final api = ref.read(apiClientProvider);
                  await api.dio.post('/api/rbac/permissoes', data: {
                    'usuarioConvidadoId': int.parse(usuarioIdCtrl.text),
                    'recurso': recursoSelecionado,
                    'nivelAcesso': nivelSelecionado,
                  });
                  ref.invalidate(permissoesProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _revogarAcesso(WidgetRef ref, int usuarioId, String recurso) async {
    final api = ref.read(apiClientProvider);
    await api.dio.delete('/api/rbac/permissoes/$recurso?usuarioConvidadoId=$usuarioId');
    ref.invalidate(permissoesProvider);
  }
}
