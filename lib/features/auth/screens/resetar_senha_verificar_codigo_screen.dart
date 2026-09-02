import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_error_messages.dart';
import '../utils/esqueci_senha_display.dart';
import '../utils/login_display.dart';
import '../utils/reset_codigo_display.dart';
import '../widgets/auth_otp_field.dart';
import '../widgets/auth_shell.dart';

part 'resetar_senha_verificar_codigo_screen_actions.part.dart';

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

  @override
  Widget build(BuildContext context) {
    return fxScreenA11yScope(
      label: resetCodigoHelpTitle(),
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
                    roleLabel: _isAluno ? 'ALUNO' : 'PERSONAL',
                    onBack: () => context.go(_esqueciPath),
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
                                semanticLabel:
                                    _isAluno
                                        ? 'Focux ALUNO'
                                        : 'Focux PERSONAL',
                                aluno: _isAluno,
                              ),
                            ),
                            const SizedBox(height: TokensStrip.s4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    resetCodigoHelpTitle(),
                                    style: authPageTitleStyle(context),
                                  ),
                                ),
                                FxHelpIconButton(
                                  tooltip: resetCodigoHelpTitle(),
                                  onTap: _abrirAjuda,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enviamos 6 dígitos para ${resetCodigoEmailHint(_email)}. '
                              'Válido por 10 minutos.',
                              style: authSubtitleStyle().copyWith(height: 1.5),
                            ),
                            const SizedBox(height: 24),
                            AuthOtpField(
                              controller: _codeController,
                              resendSeconds: resendSeconds,
                              sending: _resending,
                              disabled: _email.isEmpty,
                              onResend: () {
                                unawaited(_pedirReenviar());
                              },
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
                              label: resetCodigoContinuarLabel(),
                              loading: _loading,
                              loadingLabel: resetCodigoContinuandoLabel(),
                              onPressed:
                                  _loading ? null : _pedirContinuar,
                            ),
                            FxConversionTextLink(
                              text: '',
                              actionText: resetCodigoVoltarLoginLabel(),
                              onTap: () {
                                if (_loading) return;
                                context.go(_loginPath);
                              },
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
