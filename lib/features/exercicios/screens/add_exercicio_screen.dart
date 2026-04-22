import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/exercicios_provider.dart';

const _gruposMusculares = [
  'PEITO', 'COSTAS', 'OMBROS', 'BICEPS',
  'TRICEPS', 'PERNAS', 'ABDOMEN', 'CARDIO',
];

const _categoriasExercicio = [
  'Musculação',
  'Mobilidade',
  'Lutas',
  'Yoga',
  'Funcional',
  'Cardio',
  'Outro',
];

class AddExercicioScreen extends ConsumerStatefulWidget {
  const AddExercicioScreen({super.key});

  @override
  ConsumerState<AddExercicioScreen> createState() => _AddExercicioScreenState();
}

class _AddExercicioScreenState extends ConsumerState<AddExercicioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  String? _musculoAlvo;
  String? _categoria;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _tagsCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(exercicioRepositoryProvider).criar(
        nome: _nomeCtrl.text.trim(),
        descricao: _descricaoCtrl.text.trim(),
        musculoAlvo: _musculoAlvo,
        categoria: _categoria,
        tags: _tagsCtrl.text.trim(),
        observacoes: _obsCtrl.text.trim(),
      );
      if (mounted) context.pop(true);
    } catch (e) {
      setState(() { _error = 'Erro ao cadastrar exercício.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Exercício')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nomeCtrl,
                  decoration: const InputDecoration(labelText: 'Nome do exercício'),
                  validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _musculoAlvo,
                  decoration: const InputDecoration(labelText: 'Músculo alvo'),
                  items: _gruposMusculares
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _musculoAlvo = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _categoria,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: _categoriasExercicio
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoria = v),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tagsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tags (opcional)',
                    hintText: 'Ex: #EmCasa,#SemEquipamento',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descricaoCtrl,
                  decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _obsCtrl,
                  decoration: const InputDecoration(labelText: 'Observações (opcional)'),
                  maxLines: 3,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: EagleTokens.danger)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Cadastrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
