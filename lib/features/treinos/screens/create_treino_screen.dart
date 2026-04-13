import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/treinos_provider.dart';

const _niveis = ['INICIANTE', 'INTERMEDIARIO', 'AVANCADO'];

class CreateTreinoScreen extends ConsumerStatefulWidget {
  const CreateTreinoScreen({super.key});

  @override
  ConsumerState<CreateTreinoScreen> createState() => _CreateTreinoScreenState();
}

class _CreateTreinoScreenState extends ConsumerState<CreateTreinoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController();
  String? _nivel;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _objetivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(treinoRepositoryProvider).criar(
        _nomeCtrl.text.trim(),
        _descricaoCtrl.text.trim(),
        _objetivoCtrl.text.trim(),
        _nivel,
      );
      if (mounted) context.pop(true);
    } catch (e) {
      setState(() { _error = 'Erro ao criar treino.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Treino')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nomeCtrl,
                  decoration: const InputDecoration(labelText: 'Nome do treino'),
                  validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _nivel,
                  decoration: const InputDecoration(labelText: 'Nível'),
                  items: _niveis.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                  onChanged: (v) => setState(() => _nivel = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _objetivoCtrl,
                  decoration: const InputDecoration(labelText: 'Objetivo (opcional)'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descricaoCtrl,
                  decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                  maxLines: 3,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Criar Treino'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
