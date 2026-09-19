import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_error.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_error_messages.dart';
import '../utils/post_login_redirect.dart';
import '../widgets/auth_shell.dart';

/// Challenge MFA após login Personal (TOTP ou recovery).
class MfaVerifyScreen extends ConsumerStatefulWidget {
  const MfaVerifyScreen({super.key});

  @override
  ConsumerState<MfaVerifyScreen> createState() => _MfaVerifyScreenState();
}

class _MfaVerifyScreenState extends ConsumerState<MfaVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _useRecovery = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final challenge = ref.read(mfaChallengeProvider);
    final mfaToken = challenge?.mfaToken.trim();
    if (mfaToken == null || mfaToken.isEmpty) {
      context.go('/login');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      await ref.read(authProvider.notifier).verifyMfa(
            mfaToken: mfaToken,
            code: _codeController.text.trim(),
          );
      if (!mounted) return;
      ref.read(mfaChallengeProvider.notifier).state = null;
      final from = challenge?.returnTo;
      final dest =
          (from != null && from.isNotEmpty)
              ? (safePostLoginPath(from, isAluno: false) ??
                  '/dashboard/personal')
              : '/dashboard/personal';
      context.go(dest);
    } catch (error) {
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      final message = mapMfaVerifyError(error);
      // Token da challenge expirou/inválido → login. Código errado → fica na tela.
      if (_isMfaChallengeGone(error, message)) {
        ref.read(mfaChallengeProvider.notifier).state = null;
        context.go('/login');
        return;
      }
      _codeController.clear();
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Só volta ao login quando a challenge em si morreu — não quando o TOTP errou.
  bool _isMfaChallengeGone(Object error, String message) {
    final codigo = ApiError.from(error)?.codigo;
    if (codigo == 'MFA_TOKEN_INVALIDO') return true;
    if (codigo == 'MFA_CODIGO_INVALIDO') return false;
    final lower = message.toLowerCase();
    if (lower.contains('expirou') || lower.contains('expirado')) return true;
    if (error is DioException) {
      return error.response?.statusCode == 410;
    }
    return false;
  }

  void _backToLogin() {
    ref.read(mfaChallengeProvider.notifier).state = null;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final challenge = ref.watch(mfaChallengeProvider);
    if (challenge == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
    }

    final primary = Theme.of(context).colorScheme.primary;
    return fxScreenA11yScope(
      label: 'Verificação em duas etapas',
      child: Scaffold(
        body: AuthShell(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: authScrollPadding(
                context,
                top: 32,
                bottomExtra: 24,
                ensureFooter: true,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: AuthGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Verificação em duas etapas',
                        style: authPageTitleStyle(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _useRecovery
                            ? 'Digite um código de recuperação (AAAA-BBBB).'
                            : 'Abra o autenticador e digite o código de 6 dígitos.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: primary.withValues(alpha: 0.78),
                            ),
                      ),
                      const SizedBox(height: 20),
                      AuthField(
                        label:
                            _useRecovery
                                ? 'Código de recuperação'
                                : 'Código',
                        controller: _codeController,
                        hintText: _useRecovery ? 'AAAA-BBBB' : '123456',
                        icon: Icons.security,
                        keyboardType:
                            _useRecovery
                                ? TextInputType.text
                                : TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        inputFormatters:
                            _useRecovery
                                ? [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9\-]'),
                                  ),
                                  LengthLimitingTextInputFormatter(12),
                                ]
                                : [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (_useRecovery) {
                            if (raw.length < 8) {
                              return 'Informe o código de recuperação.';
                            }
                            return null;
                          }
                          if (raw.length != 6) {
                            return 'Informe os 6 dígitos.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed:
                              _loading
                                  ? null
                                  : () => setState(() {
                                        _useRecovery = !_useRecovery;
                                        _codeController.clear();
                                        _error = null;
                                      }),
                          child: Text(
                            _useRecovery
                                ? 'Usar código do autenticador'
                                : 'Usar código de recuperação',
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: authInlineErrorStyle(),
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s3),
                      ],
                      FxLiquidPrimaryButton(
                        label: 'Verificar',
                        loading: _loading,
                        loadingLabel: 'Verificando…',
                        onPressed: _loading ? null : _submit,
                      ),
                      const SizedBox(height: 12),
                      FxConversionTextLink(
                        text: '',
                        actionText: 'Voltar ao login',
                        onTap: _loading ? null : _backToLogin,
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
