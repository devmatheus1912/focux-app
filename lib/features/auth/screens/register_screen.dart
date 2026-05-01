import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../widgets/auth_shell.dart';

enum _RegistrationPlan {
  free('FREE', '3 alunos', 'Grátis'),
  premium('PREMIUM', '20 alunos · 5d grátis', 'R\$ 79/mês'),
  enterprise('ENTERPRISE', 'Ilimitado · 5d grátis', 'R\$ 149/mês');

  const _RegistrationPlan(this.title, this.subtitle, this.price);

  final String title;
  final String subtitle;
  final String price;
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  String? _error;
  _RegistrationPlan _selectedPlan = _RegistrationPlan.premium;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    HapticFeedback.mediumImpact();

    try {
      await ref
          .read(authProvider.notifier)
          .register(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (!mounted) {
        return;
      }

      switch (_selectedPlan) {
        case _RegistrationPlan.free:
          context.go('/dashboard/personal');
          break;
        case _RegistrationPlan.premium:
          context.go('/assinatura', extra: 'PREMIUM');
          break;
        case _RegistrationPlan.enterprise:
          context.go('/promo-enterprise');
          break;
      }
    } catch (error) {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = _mapError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 409) {
        return 'Este e-mail já está em uso.';
      }
      if (statusCode == null) {
        return 'Sem conexão com o servidor.';
      }
    }
    return 'Não foi possível criar a conta agora.';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: AuthShell(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 54, 22, 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuthBackButton(onTap: () => context.go('/login')),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const AuthLogoMark(size: 40),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FOCUX',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'PERSONAL',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Criar conta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.7,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Comece grátis. Sem cartão.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 26),
                  AuthField(
                    label: 'Nome completo',
                    controller: _nameController,
                    hintText: 'Seu nome',
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthField(
                    label: 'E-mail',
                    controller: _emailController,
                    hintText: 'seu@email.com',
                    icon: Icons.bolt_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o e-mail.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  AuthField(
                    label: 'Senha',
                    controller: _passwordController,
                    hintText: 'Mín. 8 caracteres',
                    icon: Icons.warning_amber_rounded,
                    obscureText: !_showPassword,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'A senha precisa ter no mínimo 8 caracteres.';
                      }
                      return null;
                    },
                    suffix: IconButton(
                      onPressed: () {
                        setState(() {
                          _showPassword = !_showPassword;
                        });
                      },
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AuthField(
                    label: 'Telefone / WhatsApp',
                    controller: _phoneController,
                    hintText: '(11) 99999-0000',
                    icon: Icons.send_rounded,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ESCOLHA SEU PLANO',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children:
                        _RegistrationPlan.values.map((plan) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right:
                                    plan == _RegistrationPlan.values.last
                                        ? 0
                                        : 8,
                              ),
                              child: Column(
                                children: [
                                  AuthPlanCard(
                                    title: plan.title,
                                    subtitle: plan.subtitle,
                                    price: plan.price,
                                    selected: _selectedPlan == plan,
                                    onTap: () {
                                      setState(() {
                                        _selectedPlan = plan;
                                      });
                                    },
                                  ),
                                  if (plan != _RegistrationPlan.free)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        '5 dias grÃ¡tis',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.6,
                                          ),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 28),
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
                    label: 'Criar minha conta',
                    isLoading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11.5,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(text: 'Ao criar, você concorda com os '),
                          TextSpan(
                            text: 'Termos de uso',
                            style: TextStyle(color: primary),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
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
