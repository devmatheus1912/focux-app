import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';

class EditarPerfilScreen extends ConsumerStatefulWidget {
  final PerfilPersonal perfil;

  const EditarPerfilScreen({super.key, required this.perfil});

  @override
  ConsumerState<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends ConsumerState<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _crefCtrl;
  late final TextEditingController _especialidadeCtrl;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.perfil.nome);
    _crefCtrl = TextEditingController(text: widget.perfil.cref ?? '');
    _especialidadeCtrl = TextEditingController(text: widget.perfil.especialidade ?? '');
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _crefCtrl.dispose();
    _especialidadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(perfilRepositoryProvider).atualizar(
        nome: _nomeCtrl.text.trim(),
        cref: _crefCtrl.text.trim().isEmpty ? null : _crefCtrl.text.trim(),
        especialidade: _especialidadeCtrl.text.trim().isEmpty ? null : _especialidadeCtrl.text.trim(),
      );
      if (mounted) context.pop(true);
    } catch (e) {
      setState(() { _error = 'Erro ao salvar. Tente novamente.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil')),
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
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                  validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _crefCtrl,
                  decoration: const InputDecoration(
                    labelText: 'CREF (opcional)',
                    hintText: 'Ex: 012345-G/SP',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _especialidadeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Especialidade (opcional)',
                    hintText: 'Ex: Musculação, Funcional...',
                  ),
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
                      : const Text('Salvar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
