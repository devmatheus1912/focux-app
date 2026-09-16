import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/api_error.dart';
import '../../../core/auth/session_cache_evictor.dart';
import '../../../core/config/env.dart';
import '../../../core/storage/personal_slug_store.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../../dashboard/utils/dashboard_home_prefetch.dart';
import '../../alunos/utils/alunos_home_prefetch.dart';
import '../providers/auth_provider.dart';
import '../data/auth_repository.dart';
import '../services/apple_sign_in_service.dart';
import '../services/google_sign_in_service.dart';
import '../utils/auth_error_messages.dart';
import '../utils/login_display.dart';
import '../utils/post_login_redirect.dart';
import '../widgets/auth_operational_notice.dart';
import '../widgets/auth_shell.dart';
import '../widgets/apple_sign_in_button.dart';
import '../widgets/google_sign_in_button.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

part 'login_screen_actions.part.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _slugController = TextEditingController();
  bool _loading = false;
  bool _loadingGoogle = false;
  bool _loadingApple = false;
  bool _appleEnabled = false;
  bool _showPassword = false;
  bool _googleEnabled = false;
  String? _googleStatusTitle;
  String? _googleStatusNote;
  String? _googleStatusAction;
  String? _error;
  // BUG-39: role toggle — personal or aluno
  bool _isAluno = false;
  bool _roleFromQueryApplied = false;
  String? _personalSlug;

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _resetPublicAuthBranding(),
    );
  }

  void _resetPublicAuthBranding() {
    ref.read(logoUrlProvider.notifier).state = null;
    ref.read(hideFocuxBrandingProvider.notifier).state = false;
    ref.read(personalNameProvider.notifier).state = null;
    ref.read(appDisplayNameProvider.notifier).state = null;
    ref.read(sloganProvider.notifier).state = null;
    ref.read(primaryColorProvider.notifier).state = EagleTokens.brand;
    ref.read(secondaryColorProvider.notifier).state =
        BrandPalette.defaultSecondary;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_roleFromQueryApplied) return;
    _roleFromQueryApplied = true;
    final params = GoRouterState.of(context).uri.queryParameters;
    final role = params['role']?.trim().toLowerCase();
    if (role == 'aluno') {
      _isAluno = true;
    } else if (role == 'personal') {
      _isAluno = false;
    }
    final slug = params['p']?.trim();
    if (slug != null && slug.isNotEmpty) {
      _personalSlug = slug;
      _slugController.text = slug;
      // ignore: unawaited_futures
      PersonalSlugStore.save(slug);
    } else if (_isAluno) {
      // ignore: unawaited_futures
      PersonalSlugStore.read().then((stored) {
        if (!mounted || stored == null || stored.isEmpty) return;
        if (_slugController.text.trim().isNotEmpty) return;
        setState(() {
          _personalSlug = stored;
          _slugController.text = stored;
        });
      });
    }
  }

  String? get _effectivePersonalSlug {
    final fromField = _slugController.text.trim();
    if (fromField.isNotEmpty) return fromField;
    final fromQuery = _personalSlug?.trim();
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  Future<void> _loadCapabilities() async {
    try {
      final status = await ref.read(authRepositoryProvider).environmentStatus();
      bool capsApple = false;
      try {
        final caps = await ref.read(authRepositoryProvider).capabilities();
        capsApple = caps.appleSignInEnabled;
      } catch (_) {}
      if (!mounted) return;
      final appleOffered = resolveAppleSignInOffered(
        capabilitiesEnabled: capsApple,
        environmentStatus: status,
      );
      final appClientConfigured = Env.googleWebClientId.isNotEmpty;
      // Ambos sociais quando o ambiente permite — iPhone também usa Gmail.
      final showGoogle = appClientConfigured;
      setState(() {
        _appleEnabled =
            appleOffered && AppleSignInService.isSupportedPlatform;
        _googleEnabled = showGoogle;
        if (!appClientConfigured) {
          _googleStatusTitle = 'Google pendente no app';
          _googleStatusNote =
              'Este build ainda nao recebeu o GOOGLE_WEB_CLIENT_ID, entao o botao fica bloqueado mesmo com o backend online.';
          _googleStatusAction =
              'Gerar o build com GOOGLE_WEB_CLIENT_ID e validar em staging.';
        } else if (status.googleSignInReady) {
          _googleStatusTitle = null;
          _googleStatusNote = null;
          _googleStatusAction = null;
        } else {
          final issue = status.firstIssueFor('google');
          _googleStatusTitle = issue?.title ?? 'Google pendente no ambiente';
          _googleStatusNote =
              issue?.detail.isNotEmpty == true
                  ? issue!.detail
                  : 'Login Google ainda nao esta pronto neste ambiente.';
          _googleStatusAction = issue?.action;
        }
      });
    } catch (_) {
      if (!mounted) return;
      AuthEnvironmentStatus? status;
      bool capsApple = false;
      try {
        status = await ref.read(authRepositoryProvider).environmentStatus();
      } catch (_) {}
      try {
        final caps = await ref.read(authRepositoryProvider).capabilities();
        capsApple = caps.appleSignInEnabled;
      } catch (_) {}
      if (!mounted) return;
      final appleOffered = resolveAppleSignInOffered(
        capabilitiesEnabled: capsApple,
        environmentStatus: status,
      );
      final appClientConfigured = Env.googleWebClientId.isNotEmpty;
      final showGoogle = appClientConfigured;
      setState(() {
        _appleEnabled =
            appleOffered && AppleSignInService.isSupportedPlatform;
        _googleEnabled = showGoogle;
        if (showGoogle) {
          _googleStatusTitle = null;
          _googleStatusNote = null;
          _googleStatusAction = null;
        } else if (!appClientConfigured) {
          _googleStatusTitle = 'Google pendente no app';
          _googleStatusNote =
              'Este build ainda nao recebeu o GOOGLE_WEB_CLIENT_ID, entao o botao fica bloqueado mesmo com o backend online.';
          _googleStatusAction =
              'Gerar o build com GOOGLE_WEB_CLIENT_ID e validar em staging.';
        } else {
          _googleStatusTitle = null;
          _googleStatusNote = null;
          _googleStatusAction = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return fxScreenA11yScope(
      label: 'Entrar no Focux',
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          body: AuthShell(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scrollPad = authScrollPadding(
                  context,
                  top: 40,
                  bottomExtra: 24,
                  ensureFooter: true,
                );
                final minBody = (constraints.maxHeight - scrollPad.vertical)
                    .clamp(0.0, constraints.maxHeight);
                return SingleChildScrollView(
                  padding: scrollPad,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minBody),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: AuthFormEntrance(
                          child: Column(
                            children: [
                              const SizedBox(height: 2),
                              AuthLoginBrandHeader(isAluno: _isAluno),
                              const SizedBox(height: 14),
                              AuthGlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            loginEntrarLabel(),
                                            style: authPageTitleStyle(context),
                                          ),
                                        ),
                                        FxHelpIconButton(
                                          tooltip: loginHelpTitle(),
                                          onTap: _abrirAjuda,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    AuthRoleToggle(
                                      isAluno: _isAluno,
                                      onPersonalTap: () {
                                        if (_isAluno) {
                                          HapticFeedback.selectionClick();
                                          setState(() => _isAluno = false);
                                        }
                                      },
                                      onAlunoTap: () {
                                        if (!_isAluno) {
                                          HapticFeedback.selectionClick();
                                          setState(() => _isAluno = true);
                                        }
                                      },
                                    ),
                                    if (_isAluno) ...[
                                      const SizedBox(height: 16),
                                      AuthField(
                                        label: loginSlugFieldLabel(),
                                        controller: _slugController,
                                        hintText: loginSlugFieldHint(),
                                        icon: Icons.link_rounded,
                                        textInputAction: TextInputAction.next,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[a-zA-Z0-9\-_]'),
                                          ),
                                        ],
                                        validator: (value) {
                                          if (!_isAluno) return null;
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return loginSlugMissingError();
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    AuthField(
                                      label: 'E-mail',
                                      controller: _emailController,
                                      hintText: 'seu@email.com',
                                      icon: Icons.person_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Informe o e-mail.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    AuthField(
                                      label: 'Senha',
                                      controller: _passwordController,
                                      hintText: '••••••••',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: !_showPassword,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onFieldSubmitted: (_) => _submit(),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Informe a senha.';
                                        }
                                        return null;
                                      },
                                      suffix: Semantics(
                                        button: true,
                                        label:
                                            _showPassword
                                                ? 'Ocultar senha'
                                                : 'Mostrar senha',
                                        child: TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _showPassword = !_showPassword;
                                            });
                                          },
                                          child: Text(
                                            _showPassword ? 'Ocultar' : 'Ver',
                                            style: FocuxHubTypography.chip(
                                              primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: TokensStrip.s2),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: FxConversionTextLink(
                                        text: '',
                                        actionText: loginEsqueciLabel(),
                                        onTap:
                                            () => authUnfocusAndGo(
                                              context,
                                              loginEsqueciPath(
                                                isAluno: _isAluno,
                                                personalSlug:
                                                    _effectivePersonalSlug,
                                              ),
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
                                      label: loginEntrarLabel(),
                                      loading: _loading,
                                      loadingLabel: loginEntrandoLabel(),
                                      onPressed:
                                          _loading || _loadingGoogle || _loadingApple
                                              ? null
                                              : _submit,
                                    ),
                                    if (_appleEnabled ||
                                        _googleEnabled ||
                                        _googleStatusNote != null) ...[
                                      const SizedBox(height: 12),
                                      const FxConversionDivider(
                                        label: 'ou continue com',
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (_appleEnabled) ...[
                                      AppleSignInButton(
                                        onPressed:
                                            _loadingApple || _loading || _loadingGoogle
                                                ? null
                                                : _submitApple,
                                        isLoading: _loadingApple,
                                      ),
                                      if (_googleEnabled) const SizedBox(height: 10),
                                    ],
                                    if (_googleEnabled) ...[
                                      GoogleSignInButton(
                                        onPressed:
                                            _loadingGoogle
                                                ? null
                                                : _submitGoogle,
                                        isLoading: _loadingGoogle,
                                        dark: true,
                                      ),
                                    ],
                                    if (_googleStatusNote != null) ...[
                                      if (_googleEnabled)
                                        const SizedBox(height: 12),
                                      AuthOperationalNotice(
                                        icon: Icons.g_mobiledata_rounded,
                                        title:
                                            _googleStatusTitle ??
                                            'Google pendente no ambiente',
                                        text: _googleStatusNote!,
                                        action: _googleStatusAction,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: TokensStrip.s4),
                              FxConversionTextLink(
                                text: 'Não tem conta? ',
                                actionText: loginCriarContaLabel(),
                                onTap:
                                    () => authUnfocusAndGo(
                                      context,
                                      loginRegisterPath(
                                        isAluno: _isAluno,
                                        personalSlug: _effectivePersonalSlug,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
