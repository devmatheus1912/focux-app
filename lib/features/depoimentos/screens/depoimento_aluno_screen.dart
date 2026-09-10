import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/depoimento_repository.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

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
  bool _enviado = false;

  bool get _isDirty =>
      !_enviado &&
      (_textoCtrl.text.trim().isNotEmpty || _nota != 5);

  @override
  void initState() {
    super.initState();
    _textoCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _textoCtrl.dispose();
    super.dispose();
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
    setState(() => _enviando = true);
    try {
      await DepoimentoRepository(
        ref.read(apiClientProvider),
      ).submeter(texto: _textoCtrl.text.trim(), nota: _nota);
      if (mounted) setState(() => _enviado = true);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return fxScreenA11yScope(
      label: 'Deixar Depoimento',
      child: FxFormPopGuard(
        dirty: _isDirty,
        onCancel: _cancel,
        child: FxShellScaffold(
          useMesh: true,
          extendBody: true,
          appBar: FxShellAppBar(
            title: 'Deixar Depoimento',
            subtitle: 'Conte como foi sua experiência',
            onBack: _cancel,
          ),
          bottomNavigationBar:
              _enviado
                  ? null
                  : FxFormStickyBar(
                    child: FxLiquidPrimaryButton(
                      label: 'Enviar depoimento',
                      loading: _enviando,
                      loadingLabel: 'Enviando…',
                      onPressed: _enviando ? null : _enviar,
                    ),
                  ),
          body:
              _enviado
                  ? FxEmptyState(
                    icon: 'circle-check',
                    title: 'Depoimento enviado!',
                    subtitle: 'Aguardando aprovação do seu personal.',
                    action: FxEmptyAction(
                      label: 'Voltar',
                      onTap: () => safePopOrGo(context, '/dashboard/aluno'),
                    ),
                  )
                  : SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(TokensStrip.s5),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AVALIAÇÃO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: chrome.mute,
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              5,
                              (i) => GestureDetector(
                                onTap:
                                    _enviando
                                        ? null
                                        : () => setState(() => _nota = i + 1),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Icon(
                                    i < _nota
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: EagleTokens.goldStar,
                                    size: 44,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s5),
                          Text(
                            'DEPOIMENTO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: chrome.mute,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _textoCtrl,
                            maxLines: 5,
                            maxLength: 500,
                            enabled: !_enviando,
                            decoration: FxInputDeco.build(
                              context,
                              'Depoimento',
                              hint:
                                  'Conte como foi sua experiência com seu personal trainer...',
                            ).copyWith(alignLabelWithHint: true),
                            validator:
                                (v) =>
                                    (v == null || v.trim().length < 10)
                                        ? 'Mínimo 10 caracteres'
                                        : null,
                          ),
                        ],
                      ),
                    ),
                  ),
        ),
      ),
    );
  }
}
