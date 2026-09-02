import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/auth/session_cache_evictor.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../../dashboard/utils/dashboard_home_prefetch.dart';
import '../../alunos/utils/alunos_home_prefetch.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_error_messages.dart';
import '../utils/login_display.dart';
import '../utils/post_login_redirect.dart';
import '../widgets/auth_operational_notice.dart';
import '../widgets/auth_shell.dart';
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
  bool _loading = false;
  bool _loadingGoogle = false;
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
    }
  }

  Future<void> _loadCapabilities() async {
    try {
      final status = await ref.read(authRepositoryProvider).environmentStatus();
      if (!mounted) return;
      final appClientConfigured = Env.googleWebClientId.isNotEmpty;
      setState(() {
        _googleEnabled = appClientConfigured;
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
      final appClientConfigured = Env.googleWebClientId.isNotEmpty;
      setState(() {
        _googleEnabled = appClientConfigured;
        if (appClientConfigured) {
          _googleStatusTitle = null;
          _googleStatusNote = null;
          _googleStatusAction = null;
        } else {
          _googleStatusTitle = 'Google pendente no app';
          _googleStatusNote =
              'Este build ainda nao recebeu o GOOGLE_WEB_CLIENT_ID, entao o botao fica bloqueado mesmo com o backend online.';
          _googleStatusAction =
              'Gerar o build com GOOGLE_WEB_CLIENT_ID e validar em staging.';
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
            child: SingleChildScrollView(
              padding: authScrollPadding(context, top: 40, bottomExtra: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 100,
                ),
                child: Form(
                  key: _formKey,
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
                              const SizedBox(height: 16),
                              AuthField(
                                label: 'E-mail',
                                controller: _emailController,
                                hintText: 'seu@email.com',
                                icon: Icons.person_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
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
                                      style: FocuxHubTypography.chip(primary),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FxSettingsGroup(
                                children: [
                                  FxSettingsTile(
                                    fxIcon: 'route',
                                    label: loginEsqueciLabel(),
                                    value: 'Reset',
                                    picker: true,
                                    onTap:
                                        () => context.go(
                                          loginEsqueciPath(
                                            isAluno: _isAluno,
                                            personalSlug: _personalSlug,
                                          ),
                                        ),
                                  ),
                                  FxSettingsTile(
                                    fxIcon: 'circle-check',
                                    label: loginEntrarLabel(),
                                    value:
                                        _loading
                                            ? loginEntrandoLabel()
                                            : loginRoleQuery(
                                              isAluno: _isAluno,
                                            ),
                                    showDivider: false,
                                    onTap:
                                        _loading || _loadingGoogle
                                            ? () {}
                                            : _submit,
                                  ),
                                ],
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
                              if (_googleEnabled ||
                                  _googleStatusNote != null) ...[
                                const SizedBox(height: 12),
                                const _AuthDivider(label: 'ou continue com'),
                                const SizedBox(height: 12),
                              ],
                              if (_googleEnabled) ...[
                                GoogleSignInButton(
                                  onPressed:
                                      _loadingGoogle ? null : _submitGoogle,
                                  isLoading: _loadingGoogle,
                                  dark: true,
                                ),
                              ],
                              if (_googleStatusNote != null) ...[
                                if (_googleEnabled) const SizedBox(height: 12),
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
                        const SizedBox(height: 18),
                        FxSettingsGroup(
                          children: [
                            FxSettingsTile(
                              fxIcon: 'users',
                              label: loginCriarContaLabel(),
                              value: loginRoleQuery(isAluno: _isAluno),
                              picker: true,
                              showDivider: false,
                              onTap:
                                  () => context.go(
                                    loginRegisterPath(isAluno: _isAluno),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

