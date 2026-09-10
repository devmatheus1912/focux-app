import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/brand/focux_brand_copy.dart';
import '../../../core/storage/personal_slug_store.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_error_messages.dart';
import '../widgets/auth_shell.dart';
import '../widgets/password_strength_meter.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

class RegisterAlunoScreen extends ConsumerStatefulWidget {
  final String? personalSlug;
  final String? conviteToken;

  const RegisterAlunoScreen({
    super.key,
    this.personalSlug,
    this.conviteToken,
  });

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
    final token = widget.conviteToken?.trim();
    if (token != null && token.isNotEmpty) {
      _conviteCtrl.text = token;
    }
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
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
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
        final slug = widget.personalSlug?.trim();
        if (slug != null && slug.isNotEmpty) {
          await PersonalSlugStore.save(slug);
        }
        if (!mounted) return;
        HapticFeedback.heavyImpact();
        unawaited(
          AnalyticsService.instance.track(
            ProductEvents.signupSuccess,
            props: {'role': 'aluno', 'method': 'convite'},
          ),
        );
        context.go('/dashboard/aluno');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.signupFailure,
          props: {'role': 'aluno', 'method': 'convite'},
        ),
      );
      setState(() {
        _error = mapRegisterAlunoError(e);
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
                    roleLabel: 'ALUNO',
                    onBack:
                        () => authUnfocusAndLeave(
                          context,
                          widget.personalSlug == null ||
                                  widget.personalSlug!.trim().isEmpty
                              ? '/login?role=aluno'
                              : '/login?role=aluno&p=${Uri.encodeComponent(widget.personalSlug!.trim())}',
                        ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: authScrollPadding(
                      context,
                      top: TokensStrip.s3,
                      bottomExtra: 28,
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
                                  semanticLabel: 'Focux ALUNO',
                                  aluno: true,
                                ),
                              ),
                              const SizedBox(height: TokensStrip.s4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: TokensStrip.s2,
                                ),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(
                                    TokensStrip.rButton,
                                  ),
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
                                    const SizedBox(width: TokensStrip.s2),
                                    Text(
                                      'Convite do seu personal',
                                      style: FocuxHubTypography.chip(primary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: TokensStrip.s4),
                              Text(
                                'Ativar conta',
                                style: authPageTitleStyle(context),
                              ),
                              const SizedBox(height: TokensStrip.s2),
                              Text(
                                'Use o código que seu personal enviou e crie sua senha.',
                                style: authSubtitleStyle(),
                              ),
                              if (widget.personalSlug != null) ...[
                                const SizedBox(height: TokensStrip.s3),
                                DecoratedBox(
                                  decoration: fxStripCardDecoration(
                                    context,
                                    glowStrength: 0.08,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
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
                                            style: FocuxHubTypography.cardTitle(
                                              color: primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: TokensStrip.s5),
                              _InviteCodeField(
                                controller: _conviteCtrl,
                                primary: primary,
                              ),
                              const SizedBox(height: 10),
                              AuthField(
                                label: 'Nome completo',
                                controller: _nomeCtrl,
                                hintText: 'Maria Souza',
                                icon: Icons.person_outline_rounded,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.name],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe seu nome.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              AuthField(
                                label: 'E-mail',
                                controller: _emailCtrl,
                                hintText: 'aluno@exemplo.com',
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Informe o e-mail.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              AuthField(
                                label: 'Senha',
                                controller: _senhaCtrl,
                                hintText: 'Mín. 8 caracteres',
                                icon: Icons.lock_outline_rounded,
                                obscureText: !_senhaVisivel,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                onFieldSubmitted: (_) => _submit(),
                                focusNode: _senhaFocus,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Informe a senha.';
                                  }
                                  if (v.length < 8) {
                                    return 'A senha precisa ter no mínimo 8 caracteres.';
                                  }
                                  return null;
                                },
                                suffix: IconButton(
                                  onPressed: () {
                                    setState(
                                      () => _senhaVisivel = !_senhaVisivel,
                                    );
                                  },
                                  icon: Icon(
                                    _senhaVisivel
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: heroTealSurface(0.82),
                                    size: 18,
                                  ),
                                ),
                              ),
                              if (_senhaFocused ||
                                  _senhaCtrl.text.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                PasswordStrengthMeter(
                                  password: _senhaCtrl.text,
                                  minLength: 8,
                                ),
                              ],
                              if (_error != null) ...[
                                const SizedBox(height: 10),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _error!,
                                    style: authInlineErrorStyle(),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                              FxLiquidPrimaryButton(
                                label: 'Criar conta',
                                loading: _loading,
                                onPressed: _loading ? null : _submit,
                              ),
                              FxConversionTextLink(
                                text: '',
                                actionText:
                                    FocuxBrandCopy.authInviteExistingAccountCta,
                                onTap: () {
                                  if (_loading) return;
                                  final slug = widget.personalSlug?.trim();
                                  authUnfocusAndGo(
                                    context,
                                    slug == null || slug.isEmpty
                                        ? '/login?role=aluno'
                                        : '/login?role=aluno&p=${Uri.encodeComponent(slug)}',
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
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
          style: FocuxHubTypography.bodyMuted(
            color: Colors.white.withValues(alpha: 0.78),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          style: FocuxHubTypography.metric(
            color: Colors.white,
            fontSize: FocuxHubTypography.metricEm,
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
              borderSide: BorderSide(color: EagleTokens.authErrorBorder),
            ),
            focusedErrorBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: EagleTokens.authErrorBorder),
            ),
            errorStyle: TextStyle(
              color: EagleTokens.authErrorSoft,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }
}
