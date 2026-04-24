import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/lead_repository.dart';

const _origens = ['Instagram', 'Indicação', 'WhatsApp', 'Google', 'Outro'];

class AddLeadScreen extends ConsumerStatefulWidget {
  const AddLeadScreen({super.key});

  @override
  ConsumerState<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends ConsumerState<AddLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _objetivo = TextEditingController();
  final _observacoes = TextEditingController();
  String? _origem;
  bool _saving = false;

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _objetivo.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await LeadRepository(ref.read(apiClientProvider)).criar(
        nome: _nome.text.trim(),
        telefone: _telefone.text.trim(),
        origem: _origem,
        objetivo: _objetivo.text.trim(),
        observacoes: _observacoes.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Novo Lead')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextFormField(
            controller: _nome,
            decoration: const InputDecoration(
                labelText: 'Nome *', border: OutlineInputBorder()),
            validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telefone,
            decoration: const InputDecoration(
                labelText: 'Telefone / WhatsApp', border: OutlineInputBorder()),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _origem,
            decoration: const InputDecoration(
                labelText: 'Origem', border: OutlineInputBorder()),
            items: _origens
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) => setState(() => _origem = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _objetivo,
            decoration: const InputDecoration(
                labelText: 'Objetivo (ex: emagrecer, hipertrofiar)',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _observacoes,
            decoration: const InputDecoration(
                labelText: 'Observações', border: OutlineInputBorder()),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _salvar,
            icon: _saving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save),
            label: Text(_saving ? 'Salvando...' : 'Salvar Lead'),
          ),
        ]),
      ),
    ),
  );
}
