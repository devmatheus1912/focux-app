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
import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_operational_notice.dart';
import '../widgets/auth_shell.dart';

class EsqueciSenhaScreen extends ConsumerStatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  ConsumerState<EsqueciSenhaScreen> createState() =>
      _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends ConsumerState<EsqueciSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _message;
  String? _error;
  String? _hint;
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

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _message = null;
      _hint = null;
    });

    HapticFeedback.mediumImpact();

    try {
      await ref
          .read(authRepositoryProvider)
          .solicitarResetSenha(
            email: _emailController.text.trim(),
            isAluno: _isAluno,
            personalSlug: _isAluno ? _personalSlug : null,
          );

      if (!mounted) {
        return;
      }

      final role = _isAluno ? 'aluno' : 'personal';
      final email = Uri.encodeComponent(_emailController.text.trim());
      final slug =
          _personalSlug != null && _personalSlug!.isNotEmpty
              ? '&p=${Uri.encodeComponent(_personalSlug!)}'
              : '';
      context.go('/resetar-senha/verificar-codigo?email=$email&role=$role$slug');
    } catch (error) {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = _mapError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == null) {
        return 'Sem conexão com o servidor.';
      }
    }
    return 'Não foi possível enviar o código agora.';
  }

  String _resetEnvironmentWarning() {
    final issue = _environmentStatus?.firstIssueFor('password_reset');
    if (issue != null) {
      return issue.detail.isEmpty
          ? 'O pedido de reset será registrado, mas a entrega do link depende da configuração de e-mail.'
          : issue.detail;
    }
    return 'Envio de e-mail ainda não está ativo neste ambiente. O pedido será registrado, mas a entrega depende da configuração SMTP.';
  }

  String _resetEnvironmentTitle() {
    return _environmentStatus?.firstIssueFor('password_reset')?.title ??
        'E-mail de recuperação pendente';
  }

  String? _resetEnvironmentAction() {
    final issue = _environmentStatus?.firstIssueFor('password_reset');
    if (issue?.action.isNotEmpty == true) {
      return issue!.action;
    }
    final actions =
        _environmentStatus?.nextActions
            .where((action) => action.toLowerCase().contains('smtp'))
            .toList() ??
        const [];
    if (actions.isNotEmpty) {
      return actions.first;
    }
    return 'Configurar SMTP no ambiente real antes da publicação.';
  }

  String get _loginPath => '/login?role=${_isAluno ? 'aluno' : 'personal'}';

  @override
  Widget build(BuildContext context) {
    return fxScreenA11yScope(
      label: 'Recuperar senha',
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
                    roleLabel: _isAluno ? 'ALUNO' : 'PERSONAL',
                    onBack: () => context.go(_loginPath),
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
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: minBody),
                          child: Form(
                            key: _formKey,
                            child: AuthFormEntrance(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                    Text(
                      'Recuperar senha',
                      style: authPageTitleStyle(context),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
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
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o e-mail.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    if (_emailDeliveryAvailable == false) ...[
                      AuthOperationalNotice(
                        icon: Icons.mark_email_unread_outlined,
                        title: _resetEnvironmentTitle(),
                        text: _resetEnvironmentWarning(),
                        action: _resetEnvironmentAction(),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (_error != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(_error!, style: authInlineErrorStyle()),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_message != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _message!,
                          style: authInlineSuccessStyle(),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_hint != null) ...[
                      Text(
                        _hint!,
                        style: FocuxHubTypography.bodyMuted(
                          color: heroTealSurface(0.82),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    FxLiquidPrimaryButton(
                      label: 'Enviar código',
                      icon: Icons.send_rounded,
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                    // Sem Spacer: o corpo vive num scroll com altura ilimitada
                    // (flex aqui quebra o layout). Padrão igual ao login.
                    const SizedBox(height: TokensStrip.s5),
                    Center(
                      child: AuthTextLink(
                        text: 'Lembrei a senha · ',
                        actionText: 'Voltar ao login',
                        onTap: () => context.go(_loginPath),
                        fontSize: 13,
                        textColor: heroTealSurface(0.78),
                      ),
                    ),
                                ],
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
