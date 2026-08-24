import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_shell.dart';
import '../widgets/password_strength_meter.dart';

class ResetarSenhaScreen extends ConsumerStatefulWidget {
  final String? resetNonce;

  const ResetarSenhaScreen({super.key, this.resetNonce});

  @override
  ConsumerState<ResetarSenhaScreen> createState() =>
      _ResetarSenhaScreenState();
}

class _ResetarSenhaScreenState extends ConsumerState<ResetarSenhaScreen> {
  static const _minPasswordLength = 8;

  final _formKey = GlobalKey<FormState>();
  final _senhaController = TextEditingController();
  final _confirmarController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _message;
  String? _role;
  bool _roleFromQueryApplied = false;
  String? _resetNonce;

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
  }

  bool get _usesPresetCredential =>
      _resetNonce != null && _resetNonce!.isNotEmpty;

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  String get _loginPath => _role == null ? '/login' : '/login?role=$_role';

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    HapticFeedback.mediumImpact();

    try {
      await ref.read(authRepositoryProvider).confirmarResetSenha(
        resetNonce: _resetNonce,
        novaSenha: _senhaController.text,
      );
      if (!mounted) return;
      setState(() => _message = 'Senha alterada. Entre novamente.');
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) context.go(_loginPath);
      });
    } catch (error) {
      HapticFeedback.heavyImpact();
      setState(() => _error = _mapError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapError(Object error) {
    if (error is DioException && error.response?.statusCode == null) {
      return 'Sem conexão com o servidor.';
    }
    return 'Código ou senha recusados. Solicite um novo código se expirou.';
  }

  @override
  Widget build(BuildContext context) {
    final subtitle =
        _resetNonce != null && _resetNonce!.isNotEmpty
            ? 'Código validado. Escolha uma nova senha segura.'
            : 'Valide o código enviado por e-mail antes de definir a senha.';

    return fxScreenA11yScope(
      label: 'Nova senha',
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          body: AuthShell(
            child: SingleChildScrollView(
              padding: authScrollPadding(context, top: 48, bottomExtra: 28),
              child: Form(
                key: _formKey,
                child: AuthFormEntrance(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthBackButton(
                        showLabel: true,
                        onTap: () => context.go(_loginPath),
                      ),
                      const SizedBox(height: 16),
                      AuthRoleHeader(
                        roleLabel: _role == 'aluno' ? 'ALUNO' : 'PERSONAL',
                        center: true,
                        width: authLogoWidthFor(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nova senha',
                        style: authPageTitleStyle(context),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        subtitle,
                        style: authSubtitleStyle().copyWith(height: 1.55),
                      ),
                      const SizedBox(height: 28),
                      AuthField(
                        label: 'Nova senha',
                        controller: _senhaController,
                        hintText: 'Mín. $_minPasswordLength caracteres',
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null ||
                              value.length < _minPasswordLength) {
                            return 'A senha precisa ter no mínimo $_minPasswordLength caracteres.';
                          }
                          return null;
                        },
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
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) {
                          if (value != _senhaController.text) {
                            return 'As senhas não conferem.';
                          }
                          return null;
                        },
                      ),
                      if (!_usesPresetCredential) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed:
                              () => context.go('/esqueci-senha?role=${_role ?? 'personal'}'),
                          child: Text(
                            'Preciso validar o código primeiro',
                            style: FocuxHubTypography.body(
                              color: heroTealSurface(0.9),
                            ).copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
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
                        label: 'Alterar senha',
                        icon: Icons.check_rounded,
                        loading: _loading,
                        onPressed: _loading || !_usesPresetCredential ? null : _submit,
                      ),
                    ],
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
