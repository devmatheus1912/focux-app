import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
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
import '../utils/reset_senha_display.dart';
import '../widgets/auth_shell.dart';
import '../widgets/password_strength_meter.dart';

part 'resetar_senha_screen_actions.part.dart';

class ResetarSenhaScreen extends ConsumerStatefulWidget {
  final String? resetNonce;

  const ResetarSenhaScreen({super.key, this.resetNonce});

  @override
  ConsumerState<ResetarSenhaScreen> createState() => _ResetarSenhaScreenState();
}

class _ResetarSenhaScreenState extends ConsumerState<ResetarSenhaScreen> {
  static const _minPasswordLength = 8;

  final _formKey = GlobalKey<FormState>();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  String? _error;
  String? _message;
  String? _role;
  bool _roleFromQueryApplied = false;
  String? _resetNonce;
  String? _personalSlug;
  Timer? _goLoginTimer;

  @override
  void initState() {
    super.initState();
    _resetNonce = widget.resetNonce;
    _senhaController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_roleFromQueryApplied) return;
    _roleFromQueryApplied = true;
    final params = GoRouterState.of(context).uri.queryParameters;
    final role = params['role']?.trim().toLowerCase();
    if (role == 'aluno' || role == 'personal') {
      _role = role;
    }
    _resetNonce ??= params['resetNonce'];
    final slug = params['p']?.trim();
    if (slug != null && slug.isNotEmpty) {
      _personalSlug = slug;
    }
  }

  @override
  void dispose() {
    _goLoginTimer?.cancel();
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasNonce = resetSenhaHasNonce(_resetNonce);
    return fxScreenA11yScope(
      label: resetSenhaHelpTitle(),
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
                    onBack: () => authUnfocusAndLeave(context, _loginPath),
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
                      child: AutofillGroup(
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
                                      resetSenhaHelpTitle(),
                                      style: authPageTitleStyle(context),
                                    ),
                                  ),
                                  FxHelpIconButton(
                                    tooltip: resetSenhaHelpTitle(),
                                    onTap: _abrirAjuda,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                resetSenhaSubtitle(hasNonce: hasNonce),
                                style: authSubtitleStyle().copyWith(
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: 28),
                              AuthField(
                                label: 'Nova senha',
                                controller: _senhaController,
                                hintText: 'Mín. $_minPasswordLength caracteres',
                                icon: Icons.lock_outline_rounded,
                                obscureText: !_showPassword,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                validator: (value) {
                                  if (value == null ||
                                      value.length < _minPasswordLength) {
                                    return 'A senha precisa ter no mínimo $_minPasswordLength caracteres.';
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
                                obscureText: !_showPassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                onFieldSubmitted: (_) => _pedirAlterar(),
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
                                    style: authInlineErrorStyle(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              if (_message != null) ...[
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _message!,
                                    style: authInlineSuccessStyle(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              FxLiquidPrimaryButton(
                                label: resetSenhaAlterarLabel(),
                                loading: _loading,
                                loadingLabel: resetSenhaAlterandoLabel(),
                                onPressed:
                                    _loading || !hasNonce
                                        ? null
                                        : _pedirAlterar,
                              ),
                              if (!hasNonce)
                                FxConversionTextLink(
                                  text: '',
                                  actionText: resetSenhaValidarCodigoLabel(),
                                  onTap:
                                      () => authUnfocusAndGo(
                                        context,
                                        _esqueciPath,
                                      ),
                                ),
                            ],
                          ),
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
