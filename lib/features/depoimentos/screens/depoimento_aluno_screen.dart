import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_star_rating.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/depoimento_repository.dart';
import '../utils/depoimento_display.dart';

class DepoimentoAlunoScreen extends ConsumerStatefulWidget {
  const DepoimentoAlunoScreen({super.key});

  @override
  ConsumerState<DepoimentoAlunoScreen> createState() => _State();
}

class _State extends ConsumerState<DepoimentoAlunoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textoCtrl = TextEditingController();
  int _nota = 5;
  bool _enviando = false;
  bool _loading = true;
  String? _loadErro;
  DepoimentoModel? _enviado;

  bool get _isDirty =>
      _enviado == null && (_textoCtrl.text.trim().isNotEmpty || _nota != 5);

  bool get _canSubmit =>
      !_enviando && _textoCtrl.text.trim().length >= 10 && _nota >= 1;

  @override
  void initState() {
    super.initState();
    _textoCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _carregar();
  }

  @override
  void dispose() {
    _textoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _loadErro = null;
    });
    try {
      final meus = await DepoimentoRepository(
        ref.read(apiClientProvider),
      ).listarMeus();
      if (!mounted) return;
      setState(() {
        _enviado = meus.isEmpty ? null : meus.first;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadErro = friendlyError(
          e,
          fallback: 'Não foi possível carregar seus depoimentos.',
        );
        _loading = false;
      });
    }
  }

  Future<void> _cancel() async {
    FxKeyboardDismissScope.dismiss();
    if (_isDirty) {
      final ok = await showFxConfirmSheet(
        context,
        title: 'Descartar depoimento?',
        message: 'O texto e a nota não serão enviados.',
        confirmLabel: 'Descartar',
      );
      if (!ok || !mounted) return;
    }
    safePopOrGo(context, '/dashboard/aluno');
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    FxKeyboardDismissScope.dismiss();
    setState(() => _enviando = true);
    try {
      final criado = await DepoimentoRepository(
        ref.read(apiClientProvider),
      ).submeter(texto: _textoCtrl.text.trim(), nota: _nota);
      if (!mounted) return;
      setState(() => _enviado = criado);
      FeedbackHelper.showSuccess(context, 'Depoimento enviado');
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _abrirAjuda() {
    showFxHelpSheet(
      context,
      title: 'Depoimento',
      subtitle: 'Sua avaliação ajuda o personal e aparece no perfil dele.',
      tips: const [
        FxHelpTip('Nota', 'Toque nas estrelas de 1 a 5 antes de escrever.'),
        FxHelpTip(
          'Texto',
          'Mínimo 10 caracteres. Seja específico: o que mudou no treino ou na rotina.',
        ),
        FxHelpTip(
          'Aprovação',
          'O personal revisa antes de publicar. Você vê o status aqui.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.of(context);
    final showForm = !_loading && _loadErro == null && _enviado == null;

    return fxScreenA11yScope(
      label: 'Deixar Depoimento',
      child: FxKeyboardDismissScope(
        child: FxFormPopGuard(
          dirty: _isDirty,
          onCancel: _cancel,
          child: FxShellScaffold(
            useMesh: true,
            constrainWidth: false,
            extendBody: true,
            appBar: FxShellAppBar(
              title: 'Deixar Depoimento',
              subtitle: _enviado == null
                  ? 'Conte como foi sua experiência'
                  : depoimentoStatusLabel(aprovado: _enviado!.aprovado),
              leadingWidth: 92,
              leading: TextButton(
                onPressed: _cancel,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(_enviado == null ? 'Cancelar' : 'Fechar'),
              ),
              actions: [
                FxHelpIconButton(
                  tooltip: 'Como funciona',
                  onTap: _abrirAjuda,
                ),
              ],
            ),
            bottomNavigationBar: showForm
                ? FxFormStickyBar(
                    child: FxLiquidPrimaryButton(
                      label: 'Enviar depoimento',
                      loading: _enviando,
                      loadingLabel: 'Enviando…',
                      onPressed: _canSubmit ? _enviar : null,
                    ),
                  )
                : null,
            body: FxContentWidthLimiter(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(TokensStrip.s4),
                      child: SkeletonList(count: 4),
                    )
                  : _loadErro != null
                  ? FxErrorState(
                      chromeOnDark: isDark,
                      primary: primary,
                      title: FocuxMicrocopy.naoFoiPossivelCarregar,
                      message: _loadErro!,
                      onRetry: _carregar,
                    )
                  : _enviado != null
                  ? _DepoimentoEnviadoBody(
                      depoimento: _enviado!,
                      chrome: chrome,
                      onBack: () =>
                          safePopOrGo(context, '/dashboard/aluno'),
                    )
                  : SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        TokensStrip.s3,
                        TokensStrip.s4,
                        TokensStrip.s6,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FxSettingsGroup(
                              header: 'Nota',
                              caption: 'Como você avalia o acompanhamento?',
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: TokensStrip.s3,
                                  ),
                                  child: FxStarRating(
                                    value: _nota,
                                    enabled: !_enviando,
                                    onChanged: (n) =>
                                        setState(() => _nota = n),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: TokensStrip.s3,
                                  ),
                                  child: Text(
                                    depoimentoNotaLabel(_nota),
                                    textAlign: TextAlign.center,
                                    style: FocuxHubTypography.bodyMuted(
                                      color: chrome.mute,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: TokensStrip.s4),
                            FxSettingsGroup(
                              header: 'Seu depoimento',
                              caption: 'O personal lê antes de publicar.',
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    FxSettingsLayout.groupPadH,
                                    TokensStrip.s2,
                                    FxSettingsLayout.groupPadH,
                                    FxSettingsLayout.groupPadV,
                                  ),
                                  child: TextFormField(
                                    controller: _textoCtrl,
                                    maxLines: 6,
                                    maxLength: 500,
                                    enabled: !_enviando,
                                    textInputAction: TextInputAction.newline,
                                    onTapOutside: (_) =>
                                        FxKeyboardDismissScope.dismiss(),
                                    decoration: FxInputDeco.build(
                                      context,
                                      'Depoimento',
                                      hint:
                                          'Ex.: treinos claros, evolução nas cargas e suporte no WhatsApp…',
                                    ).copyWith(alignLabelWithHint: true),
                                    validator: (v) =>
                                        (v == null || v.trim().length < 10)
                                            ? 'Mínimo 10 caracteres'
                                            : null,
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
    );
  }
}

class _DepoimentoEnviadoBody extends StatelessWidget {
  const _DepoimentoEnviadoBody({
    required this.depoimento,
    required this.chrome,
    required this.onBack,
  });

  final DepoimentoModel depoimento;
  final ShellPalette chrome;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final aprovado = depoimento.aprovado;
    return ListView(
      padding: const EdgeInsets.all(TokensStrip.s4),
      children: [
        FxEmptyState(
          icon: aprovado ? 'circle-check' : 'clock',
          title: aprovado ? 'Depoimento publicado' : 'Aguardando aprovação',
          subtitle: aprovado
              ? 'Seu texto já pode aparecer no perfil do personal.'
              : 'O personal ainda precisa aprovar antes de publicar.',
        ),
        const SizedBox(height: TokensStrip.s3),
        FxSettingsGroup(
          header: 'O que você enviou',
          caption: depoimentoStatusLabel(aprovado: aprovado),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.groupPadH,
                TokensStrip.s3,
                FxSettingsLayout.groupPadH,
                TokensStrip.s2,
              ),
              child: FxStarRating(
                value: depoimento.nota,
                enabled: false,
                size: 28,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.groupPadH,
                0,
                FxSettingsLayout.groupPadH,
                FxSettingsLayout.groupPadV,
              ),
              child: Text(
                depoimento.texto,
                style: FocuxHubTypography.body(color: chrome.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: TokensStrip.s4),
        FxLiquidPrimaryButton(
          label: 'Voltar ao início',
          onPressed: onBack,
        ),
      ],
    );
  }
}
