import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/aluno_repository.dart';
import '../providers/alunos_provider.dart';

class AlunosListScreen extends ConsumerWidget {
  const AlunosListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alunosAsync = ref.watch(alunosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alunos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final criado = await context.push<bool>('/alunos/novo');
          if (criado == true) ref.invalidate(alunosProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: alunosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (alunos) => alunos.isEmpty
            ? const Center(child: Text('Nenhum aluno cadastrado ainda.'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(alunosProvider),
                child: ListView.builder(
                  itemCount: alunos.length,
                  itemBuilder: (context, i) => _AlunoTile(aluno: alunos[i]),
                ),
              ),
      ),
    );
  }
}

class _AlunoTile extends StatelessWidget {
  final Aluno aluno;

  const _AlunoTile({required this.aluno});

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final Color chipColor;
    final String chipLabel;

    if (aluno.statusFinanceiro == 'INADIMPLENTE') {
      dotColor = const Color(0xFFE53935);
      chipColor = const Color(0xFFE53935);
      chipLabel = 'Inadimplente';
    } else if (aluno.status == 'INATIVO') {
      dotColor = const Color(0xFFFFA726);
      chipColor = const Color(0xFFFFA726);
      chipLabel = 'Inativo';
    } else {
      dotColor = const Color(0xFF43A047);
      chipColor = const Color(0xFF43A047);
      chipLabel = 'Ativo';
    }

    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(child: Text(aluno.nome[0].toUpperCase())),
          Positioned(
            right: -2, top: -2,
            child: Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                color: dotColor, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
      title: Row(children: [
        Flexible(child: Text(aluno.nome)),
        if (aluno.emRisco) ...[
          const SizedBox(width: 4),
          const Icon(Icons.trending_down, size: 14, color: Colors.orange),
        ],
      ]),
      subtitle: Text(aluno.email),
      trailing: Chip(
        label: Text(chipLabel),
        backgroundColor: chipColor.withValues(alpha: 0.12),
        labelStyle: TextStyle(color: chipColor, fontWeight: FontWeight.w500),
      ),
      onTap: () => context.push('/alunos/${aluno.id}'),
    );
  }
}
