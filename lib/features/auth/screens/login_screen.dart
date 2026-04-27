import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  String? _error;
  // BUG-39: role toggle — personal or aluno
  bool _isAluno = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _loading = true; _error = null; });
    HapticFeedback.mediumImpact();

    try {
      if (_isAluno) {
        // BUG-39: aluno uses dedicated endpoint
        await ref.read(authProvider.notifier).loginAluno(
          _emailController.text.trim(), _passwordController.text,
        );
        if (!mounted) return;
        // BUG-40: redirect based on role + requiresPasswordChange
        final requiresChange = ref.read(authProvider.notifier).requiresPasswordChange;
        context.go(requiresChange ? '/aluno/definir-senha' : '/dashboard/aluno');
      } else {
        await ref.read(authProvider.notifier).login(
          _emailController.text.trim(), _passwordController.text,
        );
        if (!mounted) return;
        context.go('/dashboard/personal');
      }
    } catch (error) {
      HapticFeedback.heavyImpact();
      setState(() { _error = _mapError(error); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == null) return 'Sem conexão com o servidor.';
      if (statusCode == 401) return 'Email ou senha incorretos.';
    }
    return 'Não foi possível entrar agora.';
  }

  void _showGoogleInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Login com Google ainda não está disponível neste build.',
        ),
      ),
    );
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
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 100,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 6),
                    const AuthLogoMark(size: 72),
                    const SizedBox(height: 14),
                    const AuthWordmark(
                      titleSize: 26,
                      subtitleSize: 12,
                      taglineSize: 12,
                    ),
                    const SizedBox(height: 36),
                    AuthGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Entrar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 18),
                          // BUG-39: role toggle
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              Expanded(child: GestureDetector(
                                onTap: () => setState(() => _isAluno = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isAluno ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('Personal', textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: !_isAluno ? 1.0 : 0.5),
                                      fontWeight: !_isAluno ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 13,
                                    )),
                                ),
                              )),
                              Expanded(child: GestureDetector(
                                onTap: () => setState(() => _isAluno = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isAluno ? Colors.white.withValues(alpha: 0.18) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('Aluno', textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: _isAluno ? 1.0 : 0.5),
                                      fontWeight: _isAluno ? FontWeight.w700 : FontWeight.w500,
                                      fontSize: 13,
                                    )),
                                ),
                              )),
                            ]),
                          ),
                          const SizedBox(height: 18),
                          AuthField(
                            label: 'E-mail',
                            controller: _emailController,
                            hintText: 'seu@email.com',
                            icon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe o e-mail.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            label: 'Senha',
                            controller: _passwordController,
                            hintText: '••••••••',
                            icon: Icons.lock_outline_rounded,
                            obscureText: !_showPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe a senha.';
                              }
                              return null;
                            },
                            suffix: TextButton(
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                              child: Text(
                                _showPassword ? 'Ocultar' : 'Ver',
                                style: const TextStyle(
                                  color: Color(0xFF7CC0FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.go('/esqueci-senha'),
                              child: const Text(
                                'Esqueci minha senha',
                                style: TextStyle(
                                  color: Color(0xFF7CC0FF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFFFB6B6),
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          AuthPrimaryButton(
                            label: 'Entrar',
                            onPressed: _submit,
                            isLoading: _loading,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  height: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'ou continue com',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          AuthSecondaryButton(
                            label: 'Google',
                            icon: Icons.search_rounded,
                            onPressed: _showGoogleInfo,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.5),
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(text: 'Não tem conta? '),
                            TextSpan(
                              text: 'Criar conta grátis',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
