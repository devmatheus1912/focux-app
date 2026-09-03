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
import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_error_messages.dart';
import '../utils/esqueci_senha_display.dart';
import '../widgets/auth_operational_notice.dart';
import '../widgets/auth_shell.dart';

part 'esqueci_senha_screen_actions.part.dart';

class EsqueciSenhaScreen extends ConsumerStatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  ConsumerState<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends ConsumerState<EsqueciSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _isAluno = false;
  bool _roleFromQueryApplied = false;
  String? _personalSlug;
  bool? _emailDeliveryAvailable;
  AuthEnvironmentStatus? _environmentStatus;

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
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
      setState(() {
        _environmentStatus = status;
        _emailDeliveryAvailable = status.passwordResetReady;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _emailDeliveryAvailable = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final issue = _environmentStatus?.firstIssueFor('password_reset');
    return fxScreenA11yScope(
      label: esqueciHelpTitle(),
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scrollPad = authScrollPadding(
                        context,
                        top: TokensStrip.s3,
                        bottomExtra: TokensStrip.s4,
                        ensureFooter: true,
                      );
                      final minBody = (constraints.maxHeight -
                              scrollPad.vertical)
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
                                            esqueciHelpTitle(),
                                            style: authPageTitleStyle(context),
                                          ),
                                        ),
                                        FxHelpIconButton(
                                          tooltip: esqueciHelpTitle(),
                                          onTap: _abrirAjuda,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 320,
                                      ),
                                      child: Text(
                                        'Digite seu e-mail e enviamos um código de 6 dígitos para redefinir sua senha.',
                                        style: authSubtitleStyle(
                                          color: heroTealSurface(0.82),
                                        ).copyWith(height: 1.55),
                                      ),
                                    ),
                                    const SizedBox(height: TokensStrip.s5),
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
                                    const SizedBox(height: 18),
                                    AuthField(
                                      label: 'E-mail cadastrado',
                                      controller: _emailController,
                                      hintText: 'seu@email.com',
                                      icon: Icons.person_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      onFieldSubmitted: (_) => _pedirEnviar(),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Informe o e-mail.';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: TokensStrip.s4),
                                    if (_emailDeliveryAvailable == false) ...[
                                      AuthOperationalNotice(
                                        icon: Icons.mark_email_unread_outlined,
                                        title: esqueciEnvironmentTitle(
                                          issue?.title,
                                        ),
                                        text: esqueciEnvironmentWarning(
                                          hasIssue: issue != null,
                                          issueDetail: issue?.detail,
                                        ),
                                        action: esqueciEnvironmentAction(
                                          issueAction: issue?.action,
                                          nextActions:
                                              _environmentStatus?.nextActions ??
                                              const [],
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                    ],
                                    if (_error != null) ...[
                                      Semantics(
                                        liveRegion: true,
                                        child: Text(
                                          _error!,
                                          style: authInlineErrorStyle(),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                    ],
                                    FxLiquidPrimaryButton(
                                      label: esqueciEnviarLabel(),
                                      loading: _loading,
                                      loadingLabel: esqueciEnviandoLabel(),
                                      onPressed: _loading ? null : _pedirEnviar,
                                    ),
                                    FxConversionTextLink(
                                      text: '',
                                      actionText: esqueciVoltarLoginLabel(),
                                      onTap: () {
                                        if (_loading) return;
                                        authUnfocusAndGo(context, _loginPath);
                                      },
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
