import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
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
    if (!_formKey.currentState!.validate()) {
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
      final result = await ref
          .read(authRepositoryProvider)
          .solicitarResetSenha(
            email: _emailController.text.trim(),
            isAluno: _isAluno,
            personalSlug: _isAluno ? _personalSlug : null,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _message = result.mensagem;
        _hint =
            result.deliveryAvailable
                ? 'Verifique sua caixa de entrada e spam.'
                : 'Recuperação por e-mail não está configurada neste ambiente ainda.';
      });
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
    return 'Não foi possível enviar o link agora.';
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
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                22,
                48,
                22,
                24 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AuthBackButton(onTap: () => context.go(_loginPath)),
                    const SizedBox(height: 28),
                    AuthRoleHeader(
                      roleLabel: _isAluno ? 'ALUNO' : 'PERSONAL',
                      center: true,
                      width: 118,
                    ),
                    const SizedBox(height: TokensStrip.s5),
                    Text(
                      'Recuperar senha',
                      style: AppTypography.inter(
                        color: heroTealInk(),
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Text(
                        'Digite seu e-mail e vamos enviar um link pra redefinir sua senha.',
                        style: AppTypography.inter(
                          color: heroTealSurface(0.78),
                          fontSize: 14.5,
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
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
                    const SizedBox(height: TokensStrip.s5),
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
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: EagleTokens.authErrorSoft,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_message != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: EagleTokens.authSuccessSoft,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_hint != null) ...[
                      Text(
                        _hint!,
                        style: AppTypography.inter(
                          color: heroTealSurface(0.78),
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    FxLiquidPrimaryButton(
                      label: 'Enviar link de recuperação',
                      icon: Icons.send_rounded,
                      loading: _loading,
                      onPressed: _loading ? null : _submit,
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: AuthTextLink(
                        text: 'Lembrei a senha · ',
                        actionText: 'Voltar ao login',
                        onTap: () => context.go(_loginPath),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
