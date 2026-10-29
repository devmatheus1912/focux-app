import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/api_error.dart';
import '../../../core/config/env.dart';
import '../../../core/storage/personal_slug_store.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../features/perfil/providers/perfil_provider.dart';
import '../../dashboard/utils/dashboard_home_prefetch.dart';
import '../../dashboard/utils/aluno_dashboard_home_prefetch.dart';
import '../../alunos/utils/alunos_home_prefetch.dart';
import '../providers/auth_provider.dart';
import '../data/auth_repository.dart';
import '../services/apple_sign_in_service.dart';
import '../services/google_sign_in_service.dart';
import '../utils/auth_error_messages.dart';
import '../utils/google_sign_in_availability.dart';
import '../utils/auth_http_debug.dart';
import '../utils/login_display.dart';
import '../utils/post_login_redirect.dart';
import '../widgets/auth_operational_notice.dart';
import '../widgets/auth_shell.dart';
import '../widgets/auth_legal_consent_text.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../services/biometria_login.dart';
import '../widgets/auth_biometria_sheet.dart';
import '../widgets/auth_social_button.dart';
import '../widgets/auth_social_stack.dart';
import '../widgets/auth_text_link.dart';

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
  // Aluno sem código conhecido (ou que pediu "Trocar"): mostra o campo.
  bool _editandoCodigo = false;
  BiometriaTipo? _biometria;
  bool _viaBiometria = false;
  bool _roleFromQueryApplied = false;
  String? _personalSlug;

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
    _carregarBiometria();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _resetPublicAuthBranding(),
    );
  }

  void _resetPublicAuthBranding() {
    ref.read(logoUrlProvider.notifier).value = null;
    ref.read(hideFocuxBrandingProvider.notifier).value = false;
    ref.read(personalNameProvider.notifier).value = null;
    ref.read(appDisplayNameProvider.notifier).value = null;
    ref.read(sloganProvider.notifier).value = null;
    ref.read(primaryColorProvider.notifier).value = EagleTokens.brand;
    ref.read(secondaryColorProvider.notifier).value =
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
    } else {
      // Sem p= na URL: tenta ler slug salvo de sessão anterior.
      // Se encontrar, auto-seleciona role aluno para o aluno não precisar
      // trocar manualmente após logout (gap-3 fix).
      // ignore: unawaited_futures
      PersonalSlugStore.read().then((stored) {
        if (!mounted || stored == null || stored.isEmpty) return;
        if (_slugController.text.trim().isNotEmpty) return;
        setState(() {
          _isAluno = true;
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
    // Apple aparece sempre que o aparelho suporta (guideline 4.8), sem
    // depender de chamada ao backend.
    final appleOnDevice = await AppleSignInService.isAvailableOnDevice();
    AuthEnvironmentStatus? status;
    try {
      status = await ref.read(authRepositoryProvider).environmentStatus();
    } catch (_) {}
    if (!mounted) return;
    final appClientConfigured = googleSignInConfiguredInApp();
    setState(() {
      _appleEnabled = appleOnDevice;
      _googleEnabled = appClientConfigured;
      _googleStatusTitle = null;
      _googleStatusNote = null;
      _googleStatusAction = null;
      if (!kDebugMode) return;
      if (!appClientConfigured) {
        _googleStatusTitle = 'Google pendente no app';
        _googleStatusNote = Env.googleWebClientId.isEmpty
            ? 'Este build ainda nao recebeu o GOOGLE_WEB_CLIENT_ID, entao o botao fica bloqueado mesmo com o backend online.'
            : 'No iPhone, o build precisa do GOOGLE_IOS_CLIENT_ID (OAuth iOS, nao Web).';
        _googleStatusAction = Env.googleWebClientId.isEmpty
            ? 'Gerar o build com GOOGLE_WEB_CLIENT_ID e validar em staging.'
            : 'Regenerar o IPA com GOOGLE_IOS_CLIENT_ID e URL scheme no Info.plist.';
      } else if (status != null && !status.googleSignInReady) {
        final issue = status.firstIssueFor('google');
        _googleStatusTitle = issue?.title ?? 'Google pendente no ambiente';
        _googleStatusNote =
            issue?.detail.isNotEmpty == true
                ? issue!.detail
                : 'Login Google ainda nao esta pronto neste ambiente.';
        _googleStatusAction = issue?.action;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    // Aluno só entra em conta criada pelo personal (e-mail + senha).
    final showApple = _appleEnabled && !_isAluno;
    final showGoogle = _googleEnabled && !_isAluno;
    final showGoogleNote = _googleStatusNote != null && !_isAluno;
    final ocupado = _loading || _loadingGoogle || _loadingApple;
    final codigoConhecido = _effectivePersonalSlug != null;
    final mostrarCampoCodigo = _isAluno && (!codigoConhecido || _editandoCodigo);
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
                  top: 24,
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 2),
                              AuthLoginBrandHeader(isAluno: _isAluno),
                              const SizedBox(height: TokensStrip.s6),
                              if (_isAluno && codigoConhecido && !_editandoCodigo)
                                _contextoAluno(),
                              if (mostrarCampoCodigo) ...[
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
                                    if (value == null || value.trim().isEmpty) {
                                      return loginSlugMissingError();
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                              AuthField(
                                label: 'E-mail',
                                controller: _emailController,
                                hintText: 'seu@email.com',
                                icon: Icons.person_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
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
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _submit(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Informe a senha.';
                                  }
                                  return null;
                                },
                                suffix: IconButton(
                                  tooltip:
                                      _showPassword
                                          ? 'Ocultar senha'
                                          : 'Mostrar senha',
                                  onPressed:
                                      () => setState(
                                        () => _showPassword = !_showPassword,
                                      ),
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: heroTealSurface(0.82),
                                    size: 20,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: AuthTextLink(
                                  label: loginEsqueciLabel(),
                                  fontSize: 13.5,
                                  onTap:
                                      () => authUnfocusAndGo(
                                        context,
                                        loginEsqueciPath(
                                          isAluno: _isAluno,
                                          personalSlug: _effectivePersonalSlug,
                                        ),
                                      ),
                                ),
                              ),
                              if (_error != null) ...[
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: authInlineErrorStyle(),
                                  ),
                                ),
                                const SizedBox(height: TokensStrip.s3),
                              ],
                              FxLiquidPrimaryButton(
                                label: loginEntrarLabel(),
                                loading: _loading,
                                loadingLabel: loginEntrandoLabel(),
                                onPressed: ocupado ? null : _submit,
                              ),
                              if (_biometria != null) ...[
                                const SizedBox(height: TokensStrip.s3),
                                AuthSocialButton(
                                  key: const ValueKey('login-biometria'),
                                  label: 'Entrar com ${_biometria!.rotulo}',
                                  leading: Icon(
                                    _biometria == BiometriaTipo.faceId
                                        ? Icons.face_unlock_outlined
                                        : Icons.fingerprint_rounded,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                  onPressed: ocupado ? null : _entrarComBiometria,
                                ),
                              ],
                              if (showApple || showGoogle || showGoogleNote) ...[
                                const SizedBox(height: TokensStrip.s4),
                                const FxConversionDivider(label: 'ou'),
                                const SizedBox(height: TokensStrip.s4),
                              ],
                              if (showApple || showGoogle)
                                AuthSocialStack(
                                  mostrarApple: showApple,
                                  mostrarGoogle: showGoogle,
                                  carregandoApple: _loadingApple,
                                  carregandoGoogle: _loadingGoogle,
                                  onApple:
                                      _loadingApple || _loading || _loadingGoogle
                                          ? null
                                          : _submitApple,
                                  onGoogle:
                                      _loadingGoogle || _loading || _loadingApple
                                          ? null
                                          : _submitGoogle,
                                ),
                              if (showApple || showGoogle) ...[
                                const SizedBox(height: TokensStrip.s3),
                                AuthLegalConsentText(primary: primary),
                              ],
                              if (showGoogleNote) ...[
                                if (showGoogle) const SizedBox(height: 12),
                                AuthOperationalNotice(
                                  icon: Icons.g_mobiledata_rounded,
                                  title:
                                      _googleStatusTitle ??
                                      'Google pendente no ambiente',
                                  text: _googleStatusNote!,
                                  action: _googleStatusAction,
                                ),
                              ],
                              const SizedBox(height: TokensStrip.s5),
                              ..._rodape(),
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

  /// "Treinando com {código} · Trocar": o aluno já está com o personal certo.
  Widget _contextoAluno() {
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
      child: Row(
        key: const ValueKey('login-contexto-aluno'),
        children: [
          Expanded(
            child: Semantics(
              container: true,
              child: Text.rich(
                TextSpan(
                  text: '${loginAlunoContexto()} ',
                  children: [
                    TextSpan(
                      text: _effectivePersonalSlug,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: heroTealSurface(0.82), fontSize: 14),
              ),
            ),
          ),
          AuthTextLink(
            label: loginTrocarLabel(),
            onTap: () => setState(() => _editandoCodigo = true),
          ),
        ],
      ),
    );
  }

  /// Rodapé: criar conta/ativar, caminho do aluno e ajuda.
  List<Widget> _rodape() {
    return [
      AuthFraseComLink(
        frase: loginRodapeTexto(isAluno: _isAluno),
        acao: loginRodapeAcao(isAluno: _isAluno),
        onTap:
            () => authUnfocusAndGo(
              context,
              loginRegisterPath(
                isAluno: _isAluno,
                personalSlug: _effectivePersonalSlug,
              ),
            ),
      ),
      if (_isAluno)
        Center(
          child: AuthTextLink(
            label: loginSouPersonalLabel(),
            onTap: _virarPersonal,
          ),
        )
      else
        AuthFraseComLink(
          frase: loginAlunoSemLinkTexto(),
          acao: loginDigitarCodigoLabel(),
          onTap:
              () => setState(() {
                _isAluno = true;
                _editandoCodigo = true;
              }),
        ),
      Center(
        child: AuthTextLink(
          label: loginAjudaLabel(),
          fontSize: 13.5,
          onTap: _abrirAjuda,
        ),
      ),
    ];
  }

  void _virarPersonal() {
    // ignore: unawaited_futures
    PersonalSlugStore.save(null);
    setState(() {
      _isAluno = false;
      _editandoCodigo = false;
      _personalSlug = null;
      _slugController.clear();
      _error = null;
    });
  }
}
