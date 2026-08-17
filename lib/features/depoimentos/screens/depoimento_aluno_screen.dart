import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/depoimento_repository.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_loading.dart';
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

  @override
  void dispose() {
    _textoCtrl.dispose();
    super.dispose();
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
      child: FxShellScaffold(
        useMesh: true,
        extendBody: true,
        appBar: const FxShellAppBar(
          title: 'Deixar Depoimento',
          subtitle: 'Conte como foi sua experiência',
        ),
        body:
            _enviando
                ? const Center(child: FxLoading())
                : _enviado
                ? FxEmptyState(
                  icon: 'circle-check',
                  title: 'Depoimento enviado!',
                  subtitle: 'Aguardando aprovação do seu personal.',
                  action: FxEmptyAction(
                    label: 'Voltar',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                )
                : SingleChildScrollView(
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
                              onTap: () => setState(() => _nota = i + 1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Icon(
                                  i < _nota ? Icons.star : Icons.star_border,
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
                          decoration: const InputDecoration(
                            hintText:
                                'Conte como foi sua experiência com seu personal trainer...',
                            alignLabelWithHint: true,
                          ),
                          validator:
                              (v) =>
                                  (v == null || v.trim().length < 10)
                                      ? 'Mínimo 10 caracteres'
                                      : null,
                        ),
                        const SizedBox(height: TokensStrip.s5),
                        FxLiquidPrimaryButton(
                          label: 'Enviar depoimento',
                          loading: _enviando,
                          onPressed: _enviando ? null : _enviar,
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}
