import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_shell.dart';
import '../widgets/password_strength_meter.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

class RegisterAlunoScreen extends ConsumerStatefulWidget {
  final String? personalSlug;

  const RegisterAlunoScreen({super.key, this.personalSlug});

  @override
  ConsumerState<RegisterAlunoScreen> createState() =>
      _RegisterAlunoScreenState();
}

class _RegisterAlunoScreenState extends ConsumerState<RegisterAlunoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _conviteCtrl = TextEditingController();
  final _senhaFocus = FocusNode();
  bool _loading = false;
  String? _error;
  bool _senhaVisivel = false;
  bool _senhaFocused = false;

  @override
  void initState() {
    super.initState();
    _senhaCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _senhaFocus.addListener(() {
      if (!mounted) return;
      setState(() => _senhaFocused = _senhaFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _conviteCtrl.dispose();
    _senhaFocus.dispose();
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
      await ref
          .read(authProvider.notifier)
          .registerAluno(
            _nomeCtrl.text.trim(),
            _emailCtrl.text.trim(),
            _senhaCtrl.text,
            _conviteCtrl.text.trim(),
            personalSlug: widget.personalSlug,
          );
      if (mounted) {
        HapticFeedback.heavyImpact();
        context.go('/dashboard/aluno');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = 'Erro ao criar conta. Verifique o código de convite.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Criar conta aluno',
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
                    AuthBackButton(
                      onTap: () => context.go('/login?role=aluno'),
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    const AuthRoleHeader(roleLabel: 'ALUNO'),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mail_outline_rounded,
                            color: primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Convite do seu personal',
                            style: TextStyle(
                              color: primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Ativar conta',
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
                      'Use o código que seu personal enviou e crie sua senha.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                    if (widget.personalSlug != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              color: primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Cadastro vinculado ao app do seu personal',
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _InviteCodeField(
                      controller: _conviteCtrl,
                      primary: primary,
                    ),
                    const SizedBox(height: TokensStrip.s5),
                    AuthField(
                      label: 'Nome completo',
                      controller: _nomeCtrl,
                      hintText: 'Maria Souza',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe seu nome.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    AuthField(
                      label: 'E-mail',
                      controller: _emailCtrl,
                      hintText: 'aluno@exemplo.com',
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Informe o e-mail.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    AuthField(
                      label: 'Senha',
                      controller: _senhaCtrl,
                      hintText: 'Mínimo 6 caracteres',
                      icon: Icons.lock_outline_rounded,
                      obscureText: !_senhaVisivel,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      focusNode: _senhaFocus,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Informe a senha.';
                        }
                        if (v.length < 6) return 'Mínimo de 6 caracteres.';
                        return null;
                      },
                      suffix: IconButton(
                        onPressed: () {
                          setState(() => _senhaVisivel = !_senhaVisivel);
                        },
                        icon: Icon(
                          _senhaVisivel
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white.withValues(alpha: 0.72),
                          size: 18,
                        ),
                      ),
                    ),
                    if (_senhaFocused || _senhaCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      PasswordStrengthMeter(
                        password: _senhaCtrl.text,
                        minLength: 6,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: TokensStrip.s4),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFFFB6B6),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    FxLiquidSecondaryButton(
                      label: FocuxBrandCopy.authInviteExistingAccountCta,
                      icon: Icons.login_rounded,
                      onPressed:
                          _loading
                              ? null
                              : () => context.go('/login?role=aluno'),
                    ),
                    const SizedBox(height: 10),
                    FxLiquidPrimaryButton(
                      label: 'Criar conta',
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                    SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
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

class _InviteCodeField extends StatelessWidget {
  const _InviteCodeField({required this.controller, required this.primary});

  final TextEditingController controller;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Código do convite',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.78),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
          ),
          cursorColor: primary,
          validator:
              (v) => v == null || v.trim().isEmpty ? 'Informe o código.' : null,
          decoration: InputDecoration(
            hintText: '• • • • • •',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.52),
              letterSpacing: 6,
            ),
            filled: true,
            fillColor: primary.withValues(alpha: 0.08),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary.withValues(alpha: 0.28)),
            ),
            focusedBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primary, width: 1.5),
            ),
            errorBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF8B8B)),
            ),
            focusedErrorBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF8B8B)),
            ),
            errorStyle: const TextStyle(
              color: Color(0xFFFFB6B6),
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }
}
