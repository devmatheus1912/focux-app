import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String _tipoLogin = 'personal';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      if (_tipoLogin == 'aluno') {
        await ref.read(authProvider.notifier).loginAluno(
          _emailCtrl.text.trim(),
          _senhaCtrl.text,
        );
        if (mounted) context.go('/dashboard/aluno');
      } else {
        await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _senhaCtrl.text,
        );
        if (mounted) context.go('/dashboard/personal');
      }
    } catch (e) {
      String msg = 'Email ou senha incorretos.';
      if (e is DioException) {
        final status = e.response?.statusCode;
        if (status == null) msg = 'Sem conexão com o servidor.';
        else if (status != 401) msg = 'Erro $status: ${e.response?.data?['message'] ?? e.message}';
      }
      setState(() { _error = msg; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'FOCUX',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Plataforma para Personal Trainers',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Center(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'personal', label: Text('Personal')),
                      ButtonSegment(value: 'aluno', label: Text('Aluno')),
                    ],
                    selected: {_tipoLogin},
                    onSelectionChanged: (v) => setState(() {
                      _tipoLogin = v.first;
                      _error = null;
                    }),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? 'Informe o e-mail' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senhaCtrl,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                  validator: (v) => v == null || v.isEmpty ? 'Informe a senha' : null,
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
                      : const Text('Entrar'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    if (_tipoLogin == 'aluno') {
                      context.go('/register/aluno');
                    } else {
                      context.go('/register');
                    }
                  },
                  child: const Text('Criar conta'),
                ),
                TextButton(
                  onPressed: () => context.push('/esqueci-senha'),
                  child: const Text('Esqueci minha senha'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
