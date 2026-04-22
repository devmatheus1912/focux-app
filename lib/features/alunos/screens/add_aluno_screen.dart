import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      final novoAluno = await ref.read(alunoRepositoryProvider).criar(
        nome: _nomeCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        objetivo: _objetivoCtrl.text.trim(),
        whatsapp: _whatsappCtrl.text.trim(),
        genero: _genero,
        tipoConsultoria: _tipoConsultoria,
      );
      if (mounted) {
        if (novoAluno.senhaProvisoria != null) {
          _showSenhaBottomSheet(novoAluno);
        } else {
          context.pop(true);
        }
      }
    } catch (e) {
      setState(() { _error = 'Erro ao cadastrar aluno. Verifique os dados.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _showSenhaBottomSheet(final aluno) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24).copyWith(bottom: 24 + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: EagleTokens.success, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Aluno cadastrado com sucesso!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'O sistema gerou uma senha provisória de 6 dígitos. Compartilhe-a com o aluno para o primeiro acesso:',
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                aluno.senhaProvisoria!,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final texto = 'Olá ${aluno.nome.split(' ').first}! Seu perfil no Focux foi criado.\n\nAcesse com seu e-mail: ${aluno.email}\nSenha provisória: ${aluno.senhaProvisoria}\n\nLembre-se de alterar a senha no primeiro acesso!';
                  Clipboard.setData(ClipboardData(text: texto));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mensagem copiada para a área de transferência!')),
                  );
                  Navigator.of(ctx).pop();
                  if (mounted) context.pop(true);
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar mensagem de convite'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (mounted) context.pop(true);
                },
                child: const Text('Fechar (Já enviei)'),
              ),
            ),
          ],
        ),
      ),
    );
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
