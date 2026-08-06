import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../widgets/auth_shell.dart';
import '../widgets/password_strength_meter.dart';

class ResetarSenhaScreen extends StatefulWidget {
  final String? token;

  const ResetarSenhaScreen({super.key, this.token});

  @override
  State<ResetarSenhaScreen> createState() => _ResetarSenhaScreenState();
}

class _ResetarSenhaScreenState extends State<ResetarSenhaScreen> {
  static const _minPasswordLength = 8;

  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _message;
  String? _role;
  bool _roleFromQueryApplied = false;

  @override
  void initState() {
    super.initState();
    _tokenController.text = widget.token ?? '';
    _senhaController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_roleFromQueryApplied) return;
    _roleFromQueryApplied = true;
    final role =
        GoRouterState.of(
          context,
        ).uri.queryParameters['role']?.trim().toLowerCase();
    if (role == 'aluno' || role == 'personal') {
      _role = role;
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  String get _loginPath => _role == null ? '/login' : '/login?role=$_role';

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
        if (mounted) context.go(_loginPath);
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
      return 'Sem conexão com o servidor.';
    }
    return 'Token inválido, expirado ou senha recusada.';
  }

  @override
  Widget build(BuildContext context) {
    return fxScreenA11yScope(
      label: 'Nova senha',
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
                      onTap: () => context.go(_loginPath),
                    ),
                    const SizedBox(height: 20),
                    AuthRoleHeader(
                      roleLabel: _role == 'aluno' ? 'ALUNO' : 'PERSONAL',
                      center: true,
                      width: 118,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Nova senha',
                      style: AppTypography.inter(
                        color: heroTealInk(),
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Use o token recebido por e-mail para redefinir sua senha.',
                      style: AppTypography.inter(
                        color: heroTealSurface(0.78),
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
                      hintText: 'Mín. $_minPasswordLength caracteres',
                      icon: Icons.lock_outline_rounded,
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.length < _minPasswordLength) {
                          return 'A senha precisa ter no mínimo $_minPasswordLength caracteres.';
                        }
                        return null;
                      },
                    ),
                    if (_senhaController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      PasswordStrengthMeter(
                        password: _senhaController.text,
                        minLength: _minPasswordLength,
                      ),
                    ],
                    const SizedBox(height: 14),
                    AuthField(
                      label: 'Confirmar senha',
                      controller: _confirmarController,
                      hintText: 'Repita a senha',
                      icon: Icons.lock_reset_rounded,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) {
                        if (value != _senhaController.text) {
                          return 'As senhas não conferem.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: EagleTokens.authErrorSoft,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_message != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: EagleTokens.authSuccessSoft,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FxLiquidPrimaryButton(
                      label: 'Alterar senha',
                      icon: Icons.check_rounded,
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
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
