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
    final ativo = aluno.status == 'ATIVO';
    return ListTile(
      leading: CircleAvatar(
        child: Text(aluno.nome[0].toUpperCase()),
      ),
      title: Text(aluno.nome),
      subtitle: Text(aluno.email),
      trailing: Chip(
        label: Text(ativo ? 'Ativo' : 'Inativo'),
        backgroundColor: ativo
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.15),
        labelStyle: TextStyle(color: ativo ? Colors.green.shade700 : Colors.grey),
      ),
      onTap: () => context.push('/alunos/${aluno.id}'),
    );
  }
}
