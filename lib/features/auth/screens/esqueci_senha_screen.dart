import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/widgets/fx_motion.dart';
import '../data/auth_repository.dart';
import '../widgets/auth_operational_notice.dart';
import '../widgets/auth_shell.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _message;
  String? _error;
  String? _hint;
  bool _isAluno = false;
  bool? _emailDeliveryAvailable;
  AuthEnvironmentStatus? _environmentStatus;

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
  }

  Future<void> _loadCapabilities() async {
    try {
      final status = await AuthRepository(ApiClient()).environmentStatus();
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
      final result = await AuthRepository(ApiClient()).solicitarResetSenha(
        email: _emailController.text.trim(),
        isAluno: _isAluno,
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

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
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
                    AuthBackButton(onTap: () => context.go('/login')),
                    const SizedBox(height: 28),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Icon(Icons.send_rounded, color: primary, size: 30),
                    ),
                    const SizedBox(height: TokensStrip.s5),
                    const Text(
                      'Recuperar senha',
                      style: TextStyle(
                        color: Colors.white,
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
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 14.5,
                          height: 1.55,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAluno = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      !_isAluno
                                          ? Colors.white.withValues(alpha: 0.18)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Personal',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(
                                      alpha: !_isAluno ? 1 : 0.55,
                                    ),
                                    fontWeight:
                                        !_isAluno
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAluno = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _isAluno
                                          ? Colors.white.withValues(alpha: 0.18)
                                          : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Aluno',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(
                                      alpha: _isAluno ? 1 : 0.55,
                                    ),
                                    fontWeight:
                                        _isAluno
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFFFB6B6),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_message != null) ...[
                      Text(
                        _message!,
                        style: const TextStyle(
                          color: Color(0xFF8FE3B3),
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (_hint != null) ...[
                      Text(
                        _hint!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.58),
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
                      child: GestureDetector(
                        onTap: () => context.go('/login'),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Color.fromRGBO(255, 255, 255, 0.4),
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(text: 'Lembrei a senha · '),
                              TextSpan(
                                text: 'Voltar ao login',
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
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
