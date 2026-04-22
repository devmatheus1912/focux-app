import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'plano_sucesso_provider.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/feedback_helper.dart';

class PlanoSucessoScreen extends StatefulWidget {
  final int alunoId;
  const PlanoSucessoScreen({super.key, required this.alunoId});

  @override
  State<PlanoSucessoScreen> createState() => _PlanoSucessoScreenState();
}

class _PlanoSucessoScreenState extends State<PlanoSucessoScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PlanoSucessoProvider>().fetchPlano(widget.alunoId));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanoSucessoProvider>();
    
    if (provider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plano de Sucesso')),
        body: const SkeletonList(count: 3),
      );
    }

    final plano = provider.plano;
    if (plano == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Plano de Sucesso')),
        body: const EmptyStateWidget(
          icon: Icons.flag_outlined,
          title: 'Nenhum Plano Ativo',
          description: 'Este aluno ainda não possui um plano de sucesso definido pelo personal.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plano de Sucesso'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: EagleTokens.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Objetivo: ${plano.objetivoPrincipal}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Status: ${plano.status}', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Marcos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...plano.marcos.map((marco) => CheckboxListTile(
            title: Text(marco.titulo, style: TextStyle(decoration: marco.atingido ? TextDecoration.lineThrough : null)),
            value: marco.atingido,
            onChanged: marco.atingido ? null : (val) {
              if (val == true) {
                provider.atingirMarco(marco.id).then((_) {
                  FeedbackHelper.showSuccess(context, 'Marco atingido! Bom trabalho.');
                }).catchError((_) {
                  FeedbackHelper.showError(context, 'Erro ao atualizar o marco.');
                });
              }
            },
          )),
        ],
      ),
    );
  }
}
