import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'comunidade_provider.dart';
import '../../core/theme/design_tokens.dart';

class ComunidadeScreen extends StatefulWidget {
  const ComunidadeScreen({super.key});

  @override
  State<ComunidadeScreen> createState() => _ComunidadeScreenState();
}

class _ComunidadeScreenState extends State<ComunidadeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ComunidadeProvider>().fetchGrupos());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComunidadeProvider>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Comunidades')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
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
                      style: ElevatedButton.styleFrom(backgroundColor: EagleTokens.primary),
                      onPressed: () {
                        provider.entrarGrupo(grupo.id).then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bem-vindo ao grupo!')));
                        });
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
