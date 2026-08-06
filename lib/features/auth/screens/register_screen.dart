import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/utils/br_phone.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_shell.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/password_strength_meter.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? referralCodigo;

  const RegisterScreen({super.key, this.referralCodigo});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _loading = false;
  bool _loadingGoogle = false;
  bool _showPassword = false;
  bool _passwordFocused = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      if (mounted) setState(() {});
    });
    _passwordFocus.addListener(() {
      if (!mounted) return;
      setState(() => _passwordFocused = _passwordFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _passwordFocus.dispose();
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
            referralCodigo: widget.referralCodigo,
            telefone: BrPhone.normalizeOrNull(_phoneController.text),
          );

      if (!mounted) {
        return;
      }

      ref.invalidate(perfilProvider);
      context.go('/assinatura');
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

  Future<void> _submitGoogle() async {
    if (_loading || _loadingGoogle) return;

    setState(() {
      _loadingGoogle = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final isAndroid = !kIsWeb && Platform.isAndroid;
      final google = GoogleSignIn(
        clientId: isAndroid ? null : Env.googleWebClientId,
        serverClientId: Env.googleWebClientId,
        scopes: const ['email', 'profile'],
      );
      try {
        await google.signOut();
      } catch (_) {}

      final account = await google.signIn();
      if (account == null) return;

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google nao retornou idToken.');
      }

      await ref
          .read(authProvider.notifier)
          .loginGoogle(idToken: idToken, isAluno: false);

      if (!mounted) return;
      ref.invalidate(perfilProvider);
      context.go('/assinatura');
    } catch (error) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      setState(() => _error = _mapGoogleError(error));
    } finally {
      if (mounted) setState(() => _loadingGoogle = false);
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

  String _mapGoogleError(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final body = error.response?.data;
      if (statusCode == 401 || statusCode == 404) {
        return 'Nao foi possivel cadastrar com Google.';
      }
      if (statusCode == 409) {
        return 'Este Google ja esta vinculado a uma conta.';
      }
      if (statusCode == 503) {
        return 'Google ainda nao esta configurado neste ambiente.';
      }
      if (statusCode == null) return 'Sem conexao com o servidor.';
      final msg =
          (body is Map && body['message'] is String)
              ? body['message'] as String
              : null;
      return msg != null && msg.isNotEmpty
          ? msg
          : 'Erro $statusCode no cadastro Google.';
    }
    if (error is StateError) {
      return 'Google nao devolveu idToken. Verifique SHA-1 e google-services.json.';
    }
    return 'Nao foi possivel cadastrar com Google: $error';
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return fxScreenA11yScope(
      label: 'Criar conta personal',
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: fxTransparent,
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
                    AuthBackButton(
                      onTap: () => context.go('/login?role=personal'),
                    ),
                    const SizedBox(height: 10),
                    const AuthRoleHeader(
                      roleLabel: 'PERSONAL',
                      center: true,
                      width: 118,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Criar conta',
                      style: AppTypography.inter(
                        color: heroTealInk(),
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.7,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Comece com sua conta e escolha o plano depois.',
                      style: AppTypography.inter(
                        color: heroTealSurface(0.82),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 10),
                    AuthField(
                      label: 'E-mail',
                      controller: _emailController,
                      hintText: 'seu@email.com',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o e-mail.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    AuthField(
                      label: 'Senha',
                      controller: _passwordController,
                      hintText: 'Mín. 8 caracteres',
                      icon: Icons.lock_outline_rounded,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.next,
                      focusNode: _passwordFocus,
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
                          color: heroTealSurface(0.82),
                          size: 18,
                        ),
                      ),
                    ),
                    if (_passwordFocused ||
                        _passwordController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      PasswordStrengthMeter(password: _passwordController.text),
                    ],
                    const SizedBox(height: 10),
                    AuthField(
                      label: 'Telefone / WhatsApp',
                      controller: _phoneController,
                      hintText: '(11) 99999-0000',
                      icon: Icons.phone_iphone_rounded,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [BrPhone.formatter()],
                      validator: BrPhone.validateOptional,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 22),
                    if (_error != null) ...[
                      Text(
                        _error!,
                        style: TextStyle(
                          color: EagleTokens.authErrorSoft,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FxLiquidPrimaryButton(
                      label: 'Criar minha conta',
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                    const SizedBox(height: 10),
                    FxLiquidSecondaryButton(
                      label: FocuxBrandCopy.onboardingExistingAccountCta,
                      icon: Icons.login_rounded,
                      onPressed:
                          _loading
                              ? null
                              : () => context.go('/login?role=personal'),
                    ),
                    const SizedBox(height: 16),
                    const _AuthDivider(label: 'ou cadastre com'),
                    const SizedBox(height: 12),
                    GoogleSignInButton(
                      label: 'Cadastrar com Google',
                      isLoading: _loadingGoogle,
                      onPressed: _loadingGoogle ? null : _submitGoogle,
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          style: AppTypography.inter(
                            color: heroTealSurface(0.78),
                            fontSize: 11.5,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                              text: 'Ao criar, você concorda com os ',
                            ),
                            TextSpan(
                              text: 'Termos de uso',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap =
                                        () => launchUrl(
                                          Uri.parse(
                                            'https://focux-backend-production.up.railway.app/termos.html',
                                          ),
                                          mode: LaunchMode.externalApplication,
                                        ),
                            ),
                            const TextSpan(text: ' e a '),
                            TextSpan(
                              text: 'Política de privacidade',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                              recognizer:
                                  TapGestureRecognizer()
                                    ..onTap =
                                        () => launchUrl(
                                          Uri.parse(
                                            'https://focux-backend-production.up.railway.app/privacidade.html',
                                          ),
                                          mode: LaunchMode.externalApplication,
                                        ),
                            ),
                            const TextSpan(text: '.'),
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
      ),
    );
  }
}

class _AuthDivider extends StatelessWidget {
  final String label;

  const _AuthDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: heroTealSurface(0.22), height: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: AppTypography.inter(
              color: heroTealSurface(0.82),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: heroTealSurface(0.22), height: 1),
        ),
      ],
    );
  }
}
