import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../widgets/auth_shell.dart';

class ResetarSenhaScreen extends StatefulWidget {
  final String? token;

  const ResetarSenhaScreen({super.key, this.token});

  @override
  State<ResetarSenhaScreen> createState() => _ResetarSenhaScreenState();
}

class _ResetarSenhaScreenState extends State<ResetarSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _tokenController.text = widget.token ?? '';
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    HapticFeedback.mediumImpact();

    try {
      await ApiClient().dio.post(
        '/api/auth/resetar-senha',
        data: {
          'token': _tokenController.text.trim(),
          'novaSenha': _senhaController.text,
        },
      );
      if (!mounted) return;
      setState(() => _message = 'Senha alterada. Entre novamente.');
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) context.go('/login');
      });
    } catch (error) {
      HapticFeedback.heavyImpact();
      setState(() => _error = _mapError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapError(Object error) {
    if (error is DioException && error.response?.statusCode == null) {
      return 'Sem conexao com o servidor.';
    }
    return 'Token invalido, expirado ou senha recusada.';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: AuthShell(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 60, 22, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthBackButton(
                    showLabel: true,
                    onTap: () => context.go('/login'),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Nova senha',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Use o token recebido por email para redefinir sua senha.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 14.5,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AuthField(
                    label: 'Token',
                    controller: _tokenController,
                    hintText: 'TOKEN',
                    icon: Icons.key_rounded,
                    textInputAction: TextInputAction.next,
                    validator:
                        (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Informe o token.'
                                : null,
                  ),
                  const SizedBox(height: 14),
                  AuthField(
                    label: 'Nova senha',
                    controller: _senhaController,
                    hintText: 'minimo 6 caracteres',
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Minimo 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  AuthField(
                    label: 'Confirmar senha',
                    controller: _confirmarController,
                    hintText: 'repita a senha',
                    icon: Icons.lock_reset_rounded,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      if (value != _senhaController.text) {
                        return 'As senhas nao conferem.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFFFB6B6),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_message != null) ...[
                    Text(
                      _message!,
                      style: const TextStyle(
                        color: Color(0xFF8FE3B3),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  AuthPrimaryButton(
                    label: 'Alterar senha',
                    icon: Icons.check_rounded,
                    isLoading: _loading,
                    onPressed: _submit,
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
