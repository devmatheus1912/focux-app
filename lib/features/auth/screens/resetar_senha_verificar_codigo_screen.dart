import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_otp_field.dart';
import '../widgets/auth_shell.dart';

class ResetarSenhaVerificarCodigoScreen extends ConsumerStatefulWidget {
  const ResetarSenhaVerificarCodigoScreen({super.key});

  @override
  ConsumerState<ResetarSenhaVerificarCodigoScreen> createState() =>
      _ResetarSenhaVerificarCodigoScreenState();
}

class _ResetarSenhaVerificarCodigoScreenState
    extends ConsumerState<ResetarSenhaVerificarCodigoScreen>
    with AuthOtpResendTimer {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;
  late String _email;
  late bool _isAluno;
  String? _personalSlug;
  bool _queryApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_queryApplied) return;
    _queryApplied = true;
    final params = GoRouterState.of(context).uri.queryParameters;
    _email = params['email']?.trim() ?? '';
    final role = params['role']?.trim().toLowerCase();
    _isAluno = role == 'aluno';
    final slug = params['p']?.trim();
    if (slug != null && slug.isNotEmpty) {
      _personalSlug = slug;
    }
    startResendCooldown(0);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String get _loginPath => '/login?role=${_isAluno ? 'aluno' : 'personal'}';

  Future<void> _resend() async {
    if (_email.isEmpty) return;
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).solicitarResetSenha(
        email: _email,
        isAluno: _isAluno,
        personalSlug: _isAluno ? _personalSlug : null,
      );
      if (!mounted) return;
      startResendCooldown();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _mapError(error));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      final nonce = await ref.read(authRepositoryProvider).validarResetCodigo(
        email: _email,
        codigo: _codeController.text.trim(),
        isAluno: _isAluno,
        personalSlug: _isAluno ? _personalSlug : null,
      );
      if (!mounted) return;
      final role = _isAluno ? 'aluno' : 'personal';
      final slugQuery =
          _personalSlug != null && _personalSlug!.isNotEmpty
              ? '&p=${Uri.encodeComponent(_personalSlug!)}'
              : '';
      context.go('/resetar-senha?resetNonce=$nonce&role=$role$slugQuery');
    } catch (error) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _error = _mapError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == null) return 'Sem conexão com o servidor.';
      if (status == 429) {
        return 'Muitas tentativas. Aguarde e peça um novo código.';
      }
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    }
    return 'Código inválido ou expirado.';
  }

  @override
  Widget build(BuildContext context) {
    return fxScreenA11yScope(
      label: 'Verificar código de recuperação',
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          body: AuthShell(
            child: SingleChildScrollView(
              padding: authScrollPadding(context, top: 48, bottomExtra: 28),
              child: Form(
                key: _formKey,
                child: AuthFormEntrance(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthBackButton(
                        showLabel: true,
                        onTap: () => context.go('/esqueci-senha?role=${_isAluno ? 'aluno' : 'personal'}'),
                      ),
                      const SizedBox(height: 16),
                      AuthRoleHeader(
                        roleLabel: _isAluno ? 'ALUNO' : 'PERSONAL',
                        center: true,
                        width: authLogoWidthFor(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Digite o código',
                        style: authPageTitleStyle(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enviamos 6 dígitos para $_email. Válido por 10 minutos.',
                        style: authSubtitleStyle().copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      AuthOtpField(
                        controller: _codeController,
                        resendSeconds: resendSeconds,
                        sending: _resending,
                        disabled: _email.isEmpty,
                        onResend: _resend,
                        resendLabel: 'Reenviar',
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: authInlineErrorStyle(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FxLiquidPrimaryButton(
                        label: 'Continuar',
                        icon: Icons.arrow_forward_rounded,
                        loading: _loading,
                        onPressed: _loading ? null : _submit,
                      ),
                      const SizedBox(height: TokensStrip.s3),
                      TextButton(
                        onPressed: () => context.go(_loginPath),
                        child: Text(
                          'Voltar ao login',
                          style: FocuxHubTypography.body(
                            color: heroTealSurface(0.85),
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
