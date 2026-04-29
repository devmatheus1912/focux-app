import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'comunidade_provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/feedback_helper.dart';

class ComunidadeScreen extends StatefulWidget {
  const ComunidadeScreen({super.key});

  @override
  State<ComunidadeScreen> createState() => _ComunidadeScreenState();
}

class _ComunidadeScreenState extends State<ComunidadeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ComunidadeProvider>().fetchGrupos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComunidadeProvider>();
    final primary = Theme.of(context).colorScheme.primary;
    
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,title: const Text('Comunidades')),
      body: provider.isLoading
          ? const SkeletonList(count: 4)
          : provider.grupos.isEmpty 
              ? const EmptyStateWidget(
                  icon: Icons.groups_outlined,
                  title: 'Sem Comunidades',
                  description: 'Nenhum grupo ativo foi encontrado.',
                )
              : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.grupos.length,
              itemBuilder: (context, index) {
                final grupo = provider.grupos[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(grupo.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(grupo.descricao),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primary),
                      onPressed: () async {
                        try {
                          await provider.entrarGrupo(grupo.id);
                          if (!context.mounted) return;
                          FeedbackHelper.showSuccess(context, 'Bem-vindo ao grupo!');
                        } catch (_) {
                          if (!context.mounted) return;
                          FeedbackHelper.showError(context, 'Erro ao entrar no grupo.');
                        }
                      },
                      child: const Text('Entrar', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
