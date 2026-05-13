import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/depoimento_repository.dart';
import '../../../core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';

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
      if (mounted) FeedbackHelper.showSuccess(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Deixar Depoimento'),
      ),
      body:
          _enviado
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: EagleTokens.good,
                        size: 72,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Depoimento enviado!',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aguardando aprovação do seu personal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              isDark
                                  ? EagleTokens.darkInkMute
                                  : EagleTokens.inkMute,
                        ),
                      ),
                      const SizedBox(height: 32),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Voltar'),
                      ),
                    ],
                  ),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                          color:
                              isDark
                                  ? EagleTokens.darkInkMute
                                  : EagleTokens.inkMute,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                color: const Color(0xFFF59E0B),
                                size: 44,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'DEPOIMENTO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color:
                              isDark
                                  ? EagleTokens.darkInkMute
                                  : EagleTokens.inkMute,
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
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _enviando ? null : _enviar,
                          child:
                              _enviando
                                  ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: FxLoading(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Text('Enviar depoimento'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
