import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/storage/personal_slug_store.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/utils/add_aluno_display.dart';
import '../data/auth_repository.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_error_messages.dart';
import '../widgets/auth_legal_consent_text.dart';
import '../widgets/auth_shell.dart';
import '../widgets/password_strength_meter.dart';

/// `/aluno/ativar/:token` — link que o personal mandou: cria a senha e entra.
class AtivarAlunoScreen extends ConsumerStatefulWidget {
  const AtivarAlunoScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<AtivarAlunoScreen> createState() => _AtivarAlunoScreenState();
}

class _AtivarAlunoScreenState extends ConsumerState<AtivarAlunoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  AtivacaoAluno? _ativacao;
  bool _validando = true;
  bool _enviando = false;
  bool _senhaVisivel = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _senhaCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _validar());
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _validar() async {
    setState(() {
      _validando = true;
      _erro = null;
    });
    AtivacaoAluno? ativacao;
    try {
      final token = widget.token.trim();
      if (token.isNotEmpty) {
        ativacao = await ref
            .read(authRepositoryProvider)
            .validarAtivacao(token);
      }
    } catch (_) {
      ativacao = null;
    }
    if (!mounted) return;
    final slug = ativacao?.personalSlug?.trim();
    if (ativacao?.valido == true && slug != null && slug.isNotEmpty) {
      await PersonalSlugStore.save(slug);
    }
    if (!mounted) return;
    setState(() {
      _ativacao = ativacao;
      _validando = false;
    });
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    HapticFeedback.mediumImpact();
    try {
      await ref
          .read(authProvider.notifier)
          .ativarAluno(
            token: widget.token.trim(),
            senha: _senhaCtrl.text,
            email: _ativacao?.precisaEmail == true ? _emailCtrl.text : null,
          );
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.signupSuccess,
          props: {'role': 'aluno', 'method': 'link_ativacao'},
        ),
      );
      context.go('/dashboard/aluno');
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _erro = mapRegisterAlunoError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String get _loginPath {
    final slug = _ativacao?.personalSlug?.trim();
    if (slug == null || slug.isEmpty) return '/login?role=aluno';
    return '/login?role=aluno&p=${Uri.encodeComponent(slug)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return fxScreenA11yScope(
      label: s.ativarA11y,
      child: Scaffold(
        body: AuthShell(
          child:
              _validando
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FxLoading(),
                        const SizedBox(height: TokensStrip.s4),
                        Text(s.ativarValidando),
                      ],
                    ),
                  )
                  : _ativacao?.valido == true
                  ? _form(context, s, _ativacao!)
                  : _invalido(context, s),
        ),
      ),
    );
  }

  Widget _invalido(BuildContext context, S s) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FxErrorState(
              chromeOnDark: true,
              primary: Theme.of(context).colorScheme.primary,
              title: s.ativarInvalidoTitulo,
              message: s.ativarInvalidoTexto,
              onRetry: _validar,
            ),
            const SizedBox(height: TokensStrip.s4),
            TextButton(
              onPressed: () => context.go(_loginPath),
              child: Text(s.ativarIrLogin),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(BuildContext context, S s, AtivacaoAluno ativacao) {
    final primary = Theme.of(context).colorScheme.primary;
    final nome = ativacao.alunoPrimeiroNome?.trim();
    final personal = ativacao.personalNome?.trim();
    return SingleChildScrollView(
      padding: authScrollPadding(
        context,
        top: TokensStrip.s5,
        bottomExtra: 28,
        ensureFooter: true,
      ),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: AuthFormEntrance(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: FxConversionLockup(
                    width: authLogoWidthFor(context, withTagline: true),
                    semanticLabel: 'Focux ALUNO',
                    aluno: true,
                  ),
                ),
                const SizedBox(height: TokensStrip.s5),
                Text(
                  nome == null || nome.isEmpty
                      ? s.ativarTitulo
                      : s.ativarOla(nome),
                  style: authPageTitleStyle(context),
                ),
                const SizedBox(height: TokensStrip.s2),
                Text(
                  personal == null || personal.isEmpty
                      ? s.ativarSubtituloSemPersonal
                      : s.ativarSubtitulo(personal),
                  style: authSubtitleStyle(),
                ),
                const SizedBox(height: TokensStrip.s5),
                if (ativacao.precisaEmail) ...[
                  AuthField(
                    label: s.ativarEmailLabel,
                    controller: _emailCtrl,
                    hintText: s.ativarEmailDica,
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator:
                        (v) =>
                            addAlunoEmailValido(v ?? '')
                                ? null
                                : s.ativarEmailInvalido,
                  ),
                  const SizedBox(height: 10),
                ],
                AuthField(
                  label: s.ativarSenhaLabel,
                  controller: _senhaCtrl,
                  hintText: s.ativarSenhaDica,
                  icon: Icons.lock_outline_rounded,
                  obscureText: !_senhaVisivel,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _submit(),
                  validator:
                      (v) =>
                          v == null || v.length < 8 ? s.ativarSenhaCurta : null,
                  suffix: IconButton(
                    tooltip: s.ativarSenhaMostrar,
                    onPressed:
                        () => setState(() => _senhaVisivel = !_senhaVisivel),
                    icon: Icon(
                      _senhaVisivel
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: heroTealSurface(0.82),
                      size: 18,
                    ),
                  ),
                ),
                if (_senhaCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  PasswordStrengthMeter(
                    password: _senhaCtrl.text,
                    minLength: 8,
                  ),
                ],
                if (_erro != null) ...[
                  const SizedBox(height: 10),
                  Semantics(
                    liveRegion: true,
                    child: Text(_erro!, style: authInlineErrorStyle()),
                  ),
                ],
                const SizedBox(height: 22),
                FxLiquidPrimaryButton(
                  label: s.ativarBotao,
                  loading: _enviando,
                  onPressed: _enviando ? null : _submit,
                ),
                const SizedBox(height: TokensStrip.s3),
                AuthLegalConsentText(primary: primary),
                Center(
                  child: TextButton(
                    onPressed: _enviando ? null : () => context.go(_loginPath),
                    child: Text(s.ativarIrLogin),
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
