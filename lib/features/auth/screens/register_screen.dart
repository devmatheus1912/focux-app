import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/config/env.dart';
import '../../../core/legal/focux_legal.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/br_phone.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_error_messages.dart';
import '../utils/register_display.dart';
import '../widgets/auth_operational_notice.dart';
import '../widgets/auth_shell.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/password_strength_meter.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

part 'register_screen_actions.part.dart';

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
  final _codeController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _loading = false;
  bool _loadingGoogle = false;
  bool _sendingCode = false;
  bool _codeSent = false;
  bool _showPassword = false;
  bool _passwordFocused = false;
  int _resendSeconds = 0;
  Timer? _resendTimer;
  String? _error;
  bool? _emailDeliveryAvailable;

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
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
    _resendTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _loadCapabilities() async {
    try {
      final caps = await ref.read(authRepositoryProvider).capabilities();
      if (!mounted) return;
      setState(() {
        _emailDeliveryAvailable = caps.passwordResetEmailAvailable;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _emailDeliveryAvailable = null);
    }
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s5,
                    TokensStrip.s2,
                    TokensStrip.s5,
                    0,
                  ),
                  child: AuthStickyRoleBar(
                    roleLabel: 'PERSONAL',
                    onBack: () => context.go('/login?role=personal'),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: authScrollPadding(
                      context,
                      top: TokensStrip.s3,
                      bottomExtra: TokensStrip.s5,
                      ensureFooter: true,
                    ),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Form(
                      key: _formKey,
                      child: AuthFormEntrance(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                      Center(
                        child: FxConversionLockup(
                          width: authLogoWidthFor(
                            context,
                            withTagline: true,
                          ),
                          semanticLabel: 'Focux PERSONAL',
                        ),
                      ),
                      const SizedBox(height: TokensStrip.s4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Criar conta',
                              style: authPageTitleStyle(context),
                            ),
                          ),
                          FxHelpIconButton(
                            tooltip: registerHelpTitle(),
                            onTap: _abrirAjuda,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Comece com sua conta e escolha o plano depois.',
                        style: authSubtitleStyle(
                          color: heroTealSurface(0.82),
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_emailDeliveryAvailable == false) ...[
                        const AuthOperationalNotice(
                          icon: Icons.mail_lock_outlined,
                          title: 'E-mail temporariamente indisponível',
                          text:
                              'Não conseguimos enviar códigos agora. '
                              'Use Entrar com Google ou tente de novo mais tarde.',
                        ),
                        const SizedBox(height: 12),
                      ],
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
                      label: 'Código do e-mail',
                      controller: _codeController,
                      hintText: '6 dígitos',
                      icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().length != 6) {
                          return 'Informe o código de 6 dígitos.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: TokensStrip.s2),
                    FxLiquidSecondaryButton(
                      label:
                          _sendingCode
                              ? registerEnviandoCodigoLabel()
                              : _resendSeconds > 0
                              ? '${registerEnviarCodigoLabel()} (${_resendSeconds}s)'
                              : registerEnviarCodigoLabel(),
                      onPressed:
                          _sendingCode || _resendSeconds > 0
                              ? null
                              : _pedirEnviarCodigo,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _codeSent
                          ? 'Código enviado. Válido por 10 minutos.'
                          : 'Toque em Enviar para receber o código no e-mail.',
                      style: FocuxHubTypography.bodyMuted(
                        color: heroTealSurface(0.72),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                      onFieldSubmitted: (_) => _pedirCriarConta(),
                    ),
                    const SizedBox(height: 22),
                    if (_error != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          style: authInlineErrorStyle(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    FxLiquidPrimaryButton(
                      label: registerCriarLabel(),
                      loading: _loading,
                      loadingLabel: registerCriandoLabel(),
                      onPressed:
                          _loading || _loadingGoogle
                              ? null
                              : _pedirCriarConta,
                    ),
                    FxConversionTextLink(
                      text: '',
                      actionText:
                          FocuxBrandCopy.onboardingExistingAccountCta,
                      onTap: () {
                        if (_loading) return;
                        context.go('/login?role=personal');
                      },
                    ),
                    const SizedBox(height: 16),
                    const _AuthDivider(label: 'ou cadastre com'),
                    const SizedBox(height: 12),
                    GoogleSignInButton(
                      label: 'Cadastrar com Google',
                      isLoading: _loadingGoogle,
                      dark: true,
                      onPressed: _loadingGoogle ? null : _submitGoogle,
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
                      child: Center(
                        child: Text.rich(
                          TextSpan(
                            style: FocuxHubTypography.bodyMuted(
                              color: heroTealSurface(0.78),
                              height: 1.45,
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
                                      ..onTap = () => FocuxLegal.openTerms(),
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
                                          () => FocuxLegal.openPrivacy(),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                      ),
                    ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
            style: FocuxHubTypography.bodyMuted(
              color: heroTealSurface(0.82),
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
