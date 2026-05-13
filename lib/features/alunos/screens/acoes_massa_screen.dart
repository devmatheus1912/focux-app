import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/aluno_repository.dart';
import '../providers/alunos_provider.dart';
import '../../../core/widgets/fx_loading.dart';

class AcoesMassaScreen extends ConsumerStatefulWidget {
  const AcoesMassaScreen({super.key});

  @override
  ConsumerState<AcoesMassaScreen> createState() => _AcoesMassaScreenState();
}

class _AcoesMassaScreenState extends ConsumerState<AcoesMassaScreen> {
  final Set<int> _selecionados = {};
  bool _processando = false;

  void _toggleSelecionado(int id) {
    setState(() {
      if (_selecionados.contains(id)) {
        _selecionados.remove(id);
      } else {
        _selecionados.add(id);
      }
    });
  }

  void _toggleTodos(List<Aluno> alunos) {
    setState(() {
      if (_selecionados.length == alunos.length) {
        _selecionados.clear();
      } else {
        _selecionados.addAll(alunos.map((a) => a.id));
      }
    });
  }

  void _mostrarAcoes(BuildContext context) {
    if (_selecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um aluno')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => _BottomSheetAcoes(
        qtd: _selecionados.length,
        onMarcarPagos: () {
          Navigator.pop(sheetContext);
          _marcarPagos();
        },
        onAtualizarStatus: (status) {
          Navigator.pop(sheetContext);
          _atualizarStatus(status);
        },
        onExcluir: () {
          Navigator.pop(sheetContext);
          _confirmarExclusao(context);
        },
      ),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir alunos?'),
        content: Text('${_selecionados.length} aluno(s) serão excluídos permanentemente. Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar == true) _excluirSelecionados();
  }

  Future<void> _excluirSelecionados() async {
    setState(() => _processando = true);
    final repo = AlunoRepository(ref.read(apiClientProvider));
    int sucesso = 0;
    int falha = 0;
    for (final id in _selecionados) {
      try {
        await repo.excluirAluno(id);
        sucesso++;
      } catch (e) {
        debugPrint('[Focux] Error: $e');
        falha++;
      }
    }
    if (mounted) {
      ref.invalidate(alunosProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$sucesso excluído(s)${falha > 0 ? ', $falha erro(s)' : ''}'),
        ),
      );
      setState(() => _selecionados.clear());
    }
    if (mounted) setState(() => _processando = false);
  }

  Future<void> _marcarPagos() async {
    setState(() => _processando = true);
    try {
      await ref.read(apiClientProvider).dio.post(
        '/api/financeiro/mensalidades/lote-pago',
        data: {'alunoIds': _selecionados.toList()},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selecionados.length} aluno(s) marcado(s) como pagos')),
        );
        setState(() => _selecionados.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
    if (mounted) setState(() => _processando = false);
  }

  Future<void> _atualizarStatus(String novoStatus) async {
    setState(() => _processando = true);
    final repo = AlunoRepository(ref.read(apiClientProvider));
    int sucesso = 0;
    int falha = 0;
    for (final id in _selecionados) {
      try {
        await repo.atualizarAluno(id, {'status': novoStatus});
        sucesso++;
      } catch (e) { debugPrint('[Focux] Error: $e');
        falha++;
      }
    }
    if (mounted) {
      ref.invalidate(alunosProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$sucesso atualizado(s)${falha > 0 ? ', $falha erro(s)' : ''}'),
        ),
      );
      setState(() => _selecionados.clear());
    }
    if (mounted) setState(() => _processando = false);
  }

  @override
  Widget build(BuildContext context) {
    final alunosAsync = ref.watch(alunosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ações em Massa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => safePopOrGo(context, '/alunos'),
        ),
        actions: [
          alunosAsync.whenOrNull(
            data: (alunos) => TextButton(
              onPressed: () => _toggleTodos(alunos),
              child: Text(
                _selecionados.length == alunos.length ? 'Desmarcar todos' : 'Selecionar todos',
              ),
            ),
          ) ?? const SizedBox(),
        ],
      ),
      body: alunosAsync.when(
        loading: () => const FxLoading(),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (alunos) => alunos.isEmpty
            ? const Center(child: Text('Nenhum aluno cadastrado.'))
            : Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: alunos.length,
                    itemBuilder: (_, i) {
                      final a = alunos[i];
                      final sel = _selecionados.contains(a.id);
                      return CheckboxListTile(
                        value: sel,
                        onChanged: (_) => _toggleSelecionado(a.id),
                        title: Text(a.nome),
                        subtitle: Text('${a.email} · ${a.status}'),
                        secondary: CircleAvatar(child: Text(a.nome[0].toUpperCase())),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                  if (_processando)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x44000000),
                        child: FxLoading(),
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _processando ? null : () => _mostrarAcoes(context),
        icon: const Icon(Icons.bolt),
        label: Text(_selecionados.isEmpty
            ? 'Aplicar ação'
            : 'Aplicar (${_selecionados.length})'),
      ),
    );
  }
}

class _BottomSheetAcoes extends StatefulWidget {
  final int qtd;
  final VoidCallback onMarcarPagos;
  final void Function(String) onAtualizarStatus;
  final VoidCallback onExcluir;

  const _BottomSheetAcoes({
    required this.qtd,
    required this.onMarcarPagos,
    required this.onAtualizarStatus,
    required this.onExcluir,
  });

  @override
  State<_BottomSheetAcoes> createState() => _BottomSheetAcoesState();
}

class _BottomSheetAcoesState extends State<_BottomSheetAcoes> {
  String _statusSelecionado = 'ATIVO';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.qtd} aluno(s) selecionado(s)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: widget.onMarcarPagos,
            icon: const Icon(Icons.attach_money),
            label: const Text('Marcar mensalidade como paga'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text('Atualizar status', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _statusSelecionado,
            decoration: const InputDecoration(labelText: 'Novo status', border: OutlineInputBorder()),
            items: ['ATIVO', 'INATIVO', 'BLOQUEADO']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _statusSelecionado = v!),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => widget.onAtualizarStatus(_statusSelecionado),
            icon: const Icon(Icons.update),
            label: const Text('Aplicar status'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: widget.onExcluir,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Excluir selecionados', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
