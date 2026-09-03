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
import '../providers/auth_provider.dart';
import '../utils/auth_error_messages.dart';
import '../utils/definir_senha_display.dart';
import '../widgets/auth_shell.dart';
import '../widgets/password_strength_meter.dart';

part 'definir_senha_aluno_screen_actions.part.dart';

class DefinirSenhaAlunoScreen extends ConsumerStatefulWidget {
  const DefinirSenhaAlunoScreen({super.key});

  @override
  ConsumerState<DefinirSenhaAlunoScreen> createState() =>
      _DefinirSenhaAlunoScreenState();
}

class _DefinirSenhaAlunoScreenState
    extends ConsumerState<DefinirSenhaAlunoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senhaAtualCtrl = TextEditingController();
  final _novaSenhaCtrl = TextEditingController();
  final _confirmacaoCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _showSenhaAtual = false;
  bool _showNovaSenha = false;

  @override
  void initState() {
    super.initState();
    _novaSenhaCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _senhaAtualCtrl.dispose();
    _novaSenhaCtrl.dispose();
    _confirmacaoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return fxScreenA11yScope(
      label: definirSenhaHelpTitle(),
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
                    roleLabel: 'ALUNO',
                    onBack:
                        () => authUnfocusAndLeave(context, '/login?role=aluno'),
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
                                  semanticLabel: 'Focux ALUNO',
                                  aluno: true,
                                ),
                              ),
                              const SizedBox(height: TokensStrip.s4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      definirSenhaHelpTitle(),
                                      style: authPageTitleStyle(context),
                                    ),
                                  ),
                                  FxHelpIconButton(
                                    tooltip: definirSenhaHelpTitle(),
                                    onTap: _abrirAjuda,
                                  ),
                                ],
                              ),
                              const SizedBox(height: TokensStrip.s2),
                              Text(
                                definirSenhaSubtitle(),
                                style: authSubtitleStyle().copyWith(
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: TokensStrip.s5),
                              AuthField(
                                label: 'Senha provisória',
                                controller: _senhaAtualCtrl,
                                hintText: 'A senha temporária do convite',
                                icon: Icons.key_rounded,
                                obscureText: !_showSenhaAtual,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.password],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Informe a senha provisória';
                                  }
                                  return null;
                                },
                                suffix: IconButton(
                                  onPressed: () {
                                    setState(
                                      () => _showSenhaAtual = !_showSenhaAtual,
                                    );
                                  },
                                  icon: Icon(
                                    _showSenhaAtual
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: heroTealSurface(0.82),
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(height: TokensStrip.s3),
                              AuthField(
                                label: 'Nova senha',
                                controller: _novaSenhaCtrl,
                                hintText:
                                    'Mín. $kDefinirSenhaMinLength caracteres',
                                icon: Icons.lock_outline_rounded,
                                obscureText: !_showNovaSenha,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                validator: (value) {
                                  if (value == null ||
                                      value.length < kDefinirSenhaMinLength) {
                                    return 'A senha precisa ter no mínimo $kDefinirSenhaMinLength caracteres.';
                                  }
                                  return null;
                                },
                                suffix: IconButton(
                                  onPressed: () {
                                    setState(
                                      () => _showNovaSenha = !_showNovaSenha,
                                    );
                                  },
                                  icon: Icon(
                                    _showNovaSenha
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: heroTealSurface(0.82),
                                    size: 18,
                                  ),
                                ),
                              ),
                              if (_novaSenhaCtrl.text.isNotEmpty) ...[
                                const SizedBox(height: TokensStrip.s2),
                                PasswordStrengthMeter(
                                  password: _novaSenhaCtrl.text,
                                  minLength: kDefinirSenhaMinLength,
                                ),
                              ],
                              const SizedBox(height: TokensStrip.s3),
                              AuthField(
                                label: 'Confirmar nova senha',
                                controller: _confirmacaoCtrl,
                                hintText: 'Repita a senha',
                                icon: Icons.lock_reset_rounded,
                                obscureText: !_showNovaSenha,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                onFieldSubmitted: (_) => _pedirSalvar(),
                                validator: (value) {
                                  if (value != _novaSenhaCtrl.text) {
                                    return 'As senhas não conferem.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: TokensStrip.s4),
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
                                label: definirSenhaSalvarLabel(),
                                loading: _loading,
                                loadingLabel: definirSenhaSalvandoLabel(),
                                onPressed: _loading ? null : _pedirSalvar,
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
