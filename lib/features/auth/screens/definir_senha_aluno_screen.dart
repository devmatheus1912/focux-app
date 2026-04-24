import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/auth_provider.dart';

class DefinirSenhaAlunoScreen extends ConsumerStatefulWidget {
  const DefinirSenhaAlunoScreen({super.key});

  @override
  ConsumerState<DefinirSenhaAlunoScreen> createState() =>
      _DefinirSenhaAlunoScreenState();
}

class _DefinirSenhaAlunoScreenState
    extends ConsumerState<DefinirSenhaAlunoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senhaAtualCtrl = TextEditingController();
  final _novaSenhaCtrl = TextEditingController();
  final _confirmacaoCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _senhaAtualCtrl.dispose();
    _novaSenhaCtrl.dispose();
    _confirmacaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      await ref.read(authProvider.notifier).definirSenhaDefinitivaAluno(
            _senhaAtualCtrl.text,
            _novaSenhaCtrl.text,
          );
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      context.go('/dashboard/aluno');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível definir a nova senha. Verifique os dados.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        title: const Text('Definir senha'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Primeiro acesso detectado',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Por segurança, troque sua senha provisória antes de continuar.',
                    style: TextStyle(
                      color:
                          isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _senhaAtualCtrl,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Senha provisória'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Informe a senha atual' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _novaSenhaCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Nova senha'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe a nova senha';
                      if (v.length < 6) return 'Mínimo de 6 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmacaoCtrl,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Confirmar nova senha'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirme a nova senha';
                      if (v != _novaSenhaCtrl.text) return 'As senhas não conferem';
                      return null;
                    },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      style: const TextStyle(color: EagleTokens.bad),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Salvar nova senha'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
