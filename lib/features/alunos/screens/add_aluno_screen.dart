import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/alunos_provider.dart';

const _generos = ['Masculino', 'Feminino', 'Outro'];
const _tiposConsultoria = ['ONLINE', 'PRESENCIAL', 'HIBRIDO'];
const _tiposConsultoriaLabel = ['Online', 'Presencial', 'Híbrido'];

class AddAlunoScreen extends ConsumerStatefulWidget {
  const AddAlunoScreen({super.key});

  @override
  ConsumerState<AddAlunoScreen> createState() => _AddAlunoScreenState();
}

class _AddAlunoScreenState extends ConsumerState<AddAlunoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  String? _genero;
  String? _tipoConsultoria;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _objetivoCtrl.dispose();
    _whatsappCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(alunoRepositoryProvider).criar(
        nome: _nomeCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        objetivo: _objetivoCtrl.text.trim(),
        whatsapp: _whatsappCtrl.text.trim(),
        genero: _genero,
        tipoConsultoria: _tipoConsultoria,
      );
      if (mounted) context.pop(true);
    } catch (e) {
      setState(() { _error = 'Erro ao cadastrar aluno. Verifique os dados.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Aluno')),
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
                  decoration: const InputDecoration(labelText: 'Nome completo'),
                  validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? 'Informe o e-mail' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _objetivoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Objetivo (opcional)',
                    hintText: 'Ex: Hipertrofia, Emagrecimento...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _whatsappCtrl,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp (opcional)',
                    hintText: 'Ex: (11) 99999-9999',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _genero,
                  decoration: const InputDecoration(labelText: 'Gênero (opcional)'),
                  items: _generos
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _genero = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _tipoConsultoria,
                  decoration: const InputDecoration(labelText: 'Tipo de consultoria (opcional)'),
                  items: List.generate(
                    _tiposConsultoria.length,
                    (i) => DropdownMenuItem(
                      value: _tiposConsultoria[i],
                      child: Text(_tiposConsultoriaLabel[i]),
                    ),
                  ),
                  onChanged: (v) => setState(() => _tipoConsultoria = v),
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
                      : const Text('Cadastrar Aluno'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
