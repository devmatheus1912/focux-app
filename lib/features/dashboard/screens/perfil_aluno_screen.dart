import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../auth/providers/auth_provider.dart';

class PerfilAlunoScreen extends ConsumerStatefulWidget {
  const PerfilAlunoScreen({super.key});

  @override
  ConsumerState<PerfilAlunoScreen> createState() => _PerfilAlunoScreenState();
}

class _PerfilAlunoScreenState extends ConsumerState<PerfilAlunoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _objetivo = TextEditingController();
  final _genero = TextEditingController();
  final _tipoConsultoria = TextEditingController();
  final _peso = TextEditingController();
  final _altura = TextEditingController();
  final _dataNascimento = TextEditingController();
  String? _fotoUrl;
  bool _loaded = false;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _whatsapp.dispose();
    _objetivo.dispose();
    _genero.dispose();
    _tipoConsultoria.dispose();
    _peso.dispose();
    _altura.dispose();
    _dataNascimento.dispose();
    super.dispose();
  }

  void _fill(dynamic aluno) {
    if (_loaded) return;
    _loaded = true;
    _nome.text = aluno.nome;
    _email.text = aluno.email;
    _telefone.text = aluno.telefone ?? '';
    _whatsapp.text = aluno.whatsapp ?? '';
    _objetivo.text = aluno.objetivo ?? '';
    _genero.text = aluno.genero ?? '';
    _tipoConsultoria.text = aluno.tipoConsultoria ?? '';
    _peso.text = aluno.peso?.toString() ?? '';
    _altura.text = aluno.altura?.toString() ?? '';
    _dataNascimento.text = aluno.dataNascimento ?? '';
    _fotoUrl = aluno.fotoUrl;
  }

  Future<void> _pickFoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 86);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final url = await MediaUploadService(ref.read(apiClientProvider)).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: 'alunos/fotos',
        resourceType: 'image',
      );
      setState(() => _fotoUrl = url);
      await _save(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar foto: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save({bool silent = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(alunoRepositoryProvider).atualizarMe({
        'nome': _nome.text.trim(),
        'email': _email.text.trim(),
        'telefone': _telefone.text.trim(),
        'whatsapp': _whatsapp.text.trim(),
        'objetivo': _objetivo.text.trim(),
        'genero': _genero.text.trim(),
        'tipoConsultoria': _tipoConsultoria.text.trim(),
        'peso': double.tryParse(_peso.text.trim().replaceAll(',', '.')),
        'altura': double.tryParse(_altura.text.trim().replaceAll(',', '.')),
        'dataNascimento': _dataNascimento.text.trim(),
        'fotoUrl': _fotoUrl,
      });
      ref.invalidate(alunoMeProvider);
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(alunoMeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        title: const Text('Meu perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/dashboard/aluno'),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salvar'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (aluno) {
          _fill(aluno);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundImage: _fotoUrl != null && _fotoUrl!.isNotEmpty
                              ? NetworkImage(_fotoUrl!)
                              : null,
                          backgroundColor: EagleTokens.brandSoft,
                          child: _fotoUrl == null || _fotoUrl!.isEmpty
                              ? Text(aluno.nome.isNotEmpty ? aluno.nome[0].toUpperCase() : 'A',
                                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800))
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: IconButton.filled(
                            onPressed: _uploading ? null : _pickFoto,
                            icon: _uploading
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.camera_alt, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _Field(controller: _nome, label: 'Nome', icon: Icons.person_outline, requiredField: true),
                  _Field(controller: _email, label: 'Email', icon: Icons.email_outlined, requiredField: true),
                  _Field(controller: _telefone, label: 'Telefone', icon: Icons.phone_outlined),
                  _Field(controller: _whatsapp, label: 'WhatsApp', icon: Icons.chat_outlined),
                  _Field(controller: _objetivo, label: 'Objetivo', icon: Icons.flag_outlined, maxLines: 2),
                  _Field(controller: _genero, label: 'Genero', icon: Icons.badge_outlined),
                  _Field(controller: _tipoConsultoria, label: 'Tipo consultoria', icon: Icons.fitness_center),
                  Row(
                    children: [
                      Expanded(child: _Field(controller: _peso, label: 'Peso kg', icon: Icons.monitor_weight_outlined, keyboardType: TextInputType.number)),
                      const SizedBox(width: 10),
                      Expanded(child: _Field(controller: _altura, label: 'Altura m', icon: Icons.height, keyboardType: TextInputType.number)),
                    ],
                  ),
                  _Field(controller: _dataNascimento, label: 'Nascimento AAAA-MM-DD', icon: Icons.cake_outlined),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text('Salvar perfil', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Esses dados ajudam o personal a ajustar treino, contato e acompanhamento.',
                    style: TextStyle(color: ink.withValues(alpha: 0.58), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool requiredField;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.requiredField = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        validator: requiredField
            ? (value) => value == null || value.trim().isEmpty ? 'Obrigatorio.' : null
            : null,
      ),
    );
  }
}
