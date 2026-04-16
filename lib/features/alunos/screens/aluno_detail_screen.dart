import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/alunos_provider.dart';
import '../../anamnese/screens/anamnese_screen.dart';
import '../../avaliacao/screens/avaliacao_screen.dart';
import '../../alimentar/screens/alimentar_screen.dart';
import '../../ia/screens/ia_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../relatorio/screens/relatorio_screen.dart';

class AlunoDetailScreen extends ConsumerWidget {
  final int alunoId;
  const AlunoDetailScreen({super.key, required this.alunoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alunoAsync = ref.watch(alunoProvider(alunoId));
    return Scaffold(
      appBar: AppBar(title: const Text('Aluno')),
      body: alunoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (aluno) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: CircleAvatar(radius: 40,
              child: Text(aluno.nome[0].toUpperCase(), style: const TextStyle(fontSize: 32)))),
            const SizedBox(height: 12),
            Center(child: Text(aluno.nome, style: Theme.of(context).textTheme.headlineSmall)),
            Center(child: Text(aluno.email, style: const TextStyle(color: Colors.grey))),
            const SizedBox(height: 16),
            Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              _InfoRow(label: 'Status', value: aluno.status),
              if (aluno.objetivo != null && aluno.objetivo!.isNotEmpty)
                _InfoRow(label: 'Objetivo', value: aluno.objetivo!),
            ]))),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _MenuBtn(icon: Icons.assignment, label: 'Anamnese',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AnamneseScreen(alunoId: alunoId)))),
            _MenuBtn(icon: Icons.monitor_weight, label: 'Avaliação Física',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AvaliacaoScreen(alunoId: alunoId)))),
            _MenuBtn(icon: Icons.restaurant_menu, label: 'Plano Alimentar',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AlimentarScreen(alunoId: alunoId)))),
            _MenuBtn(icon: Icons.bar_chart, label: 'Relatório de Aderência',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => RelatorioScreen(alunoId: alunoId, alunoNome: aluno.nome)))),
            _MenuBtn(icon: Icons.auto_awesome, label: 'Gerar Treino/Dieta com IA',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => IaScreen(alunoId: alunoId)))),
            _MenuBtn(icon: Icons.chat, label: 'Chat',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChatScreen(alunoId: alunoId, alunoNome: aluno.nome)))),
          ]),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.grey)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    ]),
  );
}

class _MenuBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _MenuBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(leading: Icon(icon), title: Text(label),
      trailing: const Icon(Icons.chevron_right), onTap: onTap),
  );
}
