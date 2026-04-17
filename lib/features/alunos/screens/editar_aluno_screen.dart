import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/aluno_repository.dart';

class EditarAlunoScreen extends ConsumerStatefulWidget {
  final Aluno aluno;
  const EditarAlunoScreen({super.key, required this.aluno});

  @override
  ConsumerState<EditarAlunoScreen> createState() => _EditarAlunoScreenState();
}

class _EditarAlunoScreenState extends ConsumerState<EditarAlunoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _telefone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _objetivo;
  String? _genero;
  String? _tipoConsultoria;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.aluno.nome);
    _email = TextEditingController(text: widget.aluno.email);
    _telefone = TextEditingController(text: widget.aluno.telefone ?? '');
    _whatsapp = TextEditingController(text: widget.aluno.whatsapp ?? '');
    _objetivo = TextEditingController(text: widget.aluno.objetivo ?? '');
    _genero = widget.aluno.genero;
    _tipoConsultoria = widget.aluno.tipoConsultoria ?? 'ONLINE';
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _whatsapp.dispose();
    _objetivo.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final repo = AlunoRepository(ref.read(apiClientProvider));
      await repo.atualizarAluno(widget.aluno.id, {
        'nome': _nome.text.trim(),
        'email': _email.text.trim(),
        'telefone': _telefone.text.trim().isEmpty ? null : _telefone.text.trim(),
        'whatsapp': _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
        'objetivo': _objetivo.text.trim().isEmpty ? null : _objetivo.text.trim(),
        'genero': _genero,
        'tipoConsultoria': _tipoConsultoria,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aluno atualizado com sucesso!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Aluno'),
        actions: [
          if (_salvando)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _salvar,
              child: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Informações básicas', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome completo *'),
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'E-mail *'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefone,
                decoration: const InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _whatsapp,
                decoration: const InputDecoration(labelText: 'WhatsApp'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              Text('Perfil do aluno', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _objetivo,
                decoration: const InputDecoration(labelText: 'Objetivo'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _genero,
                decoration: const InputDecoration(labelText: 'Gênero'),
                items: const [
                  DropdownMenuItem(value: 'MASCULINO', child: Text('Masculino')),
                  DropdownMenuItem(value: 'FEMININO', child: Text('Feminino')),
                  DropdownMenuItem(value: 'OUTRO', child: Text('Outro')),
                ],
                onChanged: (v) => setState(() => _genero = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _tipoConsultoria,
                decoration: const InputDecoration(labelText: 'Tipo de consultoria'),
                items: const [
                  DropdownMenuItem(value: 'ONLINE', child: Text('Online')),
                  DropdownMenuItem(value: 'PRESENCIAL', child: Text('Presencial')),
                  DropdownMenuItem(value: 'HIBRIDO', child: Text('Híbrido')),
                ],
                onChanged: (v) => setState(() => _tipoConsultoria = v),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _salvando ? null : _salvar,
                  child: Text(_salvando ? 'Salvando...' : 'Salvar alterações'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
