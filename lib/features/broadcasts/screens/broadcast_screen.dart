import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/friendly_error.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/broadcast_repository.dart';
import '../../../core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

final _broadcastRepositoryProvider = Provider<BroadcastRepository>(
  (ref) => BroadcastRepository(ref.read(apiClientProvider)),
);

final _broadcastHistoricoProvider = FutureProvider<List<Broadcast>>((ref) {
  return ref.read(_broadcastRepositoryProvider).listar();
});

class BroadcastScreen extends ConsumerStatefulWidget {
  const BroadcastScreen({super.key});

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _mensagemCtrl = TextEditingController();
  String _publicoAlvo = 'TODOS';
  bool _enviando = false;

  static const _publicos = ['TODOS', 'ONLINE', 'PRESENCIAL', 'HIBRIDO'];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _mensagemCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final resultado = await ref
          .read(_broadcastRepositoryProvider)
          .enviar(
            titulo: _tituloCtrl.text.trim(),
            mensagem: _mensagemCtrl.text.trim(),
            tipoConsultoriaAlvo: _publicoAlvo == 'TODOS' ? null : _publicoAlvo,
          );
      _tituloCtrl.clear();
      _mensagemCtrl.clear();
      setState(() => _publicoAlvo = 'TODOS');
      ref.invalidate(_broadcastHistoricoProvider);
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(
          content: Text('Enviado para ${resultado.totalEnviados} alunos.'),
          backgroundColor: EagleTokens.good,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(content: Text(friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final historicoAsync = ref.watch(_broadcastHistoricoProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(_broadcastHistoricoProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CENTRAL DE MENSAGERIA',
                      style: TextStyle(
                        color: brand,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Broadcasts',
                      style: TextStyle(
                        color: ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: line),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Nova mensagem',
                        style: TextStyle(
                          color: ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _DesignField(
                        controller: _tituloCtrl,
                        label: 'Titulo',
                        hint: 'Ex.: Lembrete de treino...',
                        maxLength: 100,
                        validatorText: 'Informe o titulo',
                      ),
                      const SizedBox(height: 12),
                      _DesignField(
                        controller: _mensagemCtrl,
                        label: 'Mensagem',
                        hint: 'Digite sua mensagem para os alunos...',
                        minLines: 3,
                        validatorText: 'Informe a mensagem',
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Publico-alvo',
                        style: TextStyle(
                          color: mute,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final p in _publicos) ...[
                            Expanded(
                              child: _AudienceChip(
                                label: p,
                                selected: _publicoAlvo == p,
                                onTap: () => setState(() => _publicoAlvo = p),
                              ),
                            ),
                            if (p != _publicos.last) const SizedBox(width: 7),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _enviando ? null : _enviar,
                          icon:
                              _enviando
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: FxLoading(strokeWidth: 2),
                                  )
                                  : const Icon(Icons.send_rounded, size: 16),
                          label: Text(
                            _enviando ? 'Enviando...' : 'Enviar notificacao',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: brand,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Historico',
                  style: TextStyle(
                    color: ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              historicoAsync.when(
                loading:
                    () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: FxLoading(),
                    ),
                error:
                    (e, _) =>
                        _StateCard(text: 'Erro ao carregar historico: $e'),
                data: (lista) {
                  if (lista.isEmpty) {
                    return const _StateCard(
                      text: 'Nenhum broadcast enviado ainda.',
                    );
                  }
                  return Column(
                    children: [
                      for (final b in lista) ...[
                        _BroadcastCard(broadcast: b),
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesignField extends StatelessWidget {
  const _DesignField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.validatorText,
    this.minLines = 1,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String validatorText;
  final int minLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final fill =
        isDark ? Colors.white.withValues(alpha: 0.05) : EagleTokens.paper;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: mute,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines == 1 ? 1 : 5,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: mute, fontSize: 14),
            filled: true,
            fillColor: fill,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: line),
            ),
            enabledBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: line),
            ),
          ),
          validator:
              (v) => v == null || v.trim().isEmpty ? validatorText : null,
        ),
      ],
    );
  }
}

class _AudienceChip extends StatelessWidget {
  const _AudienceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = Theme.of(context).colorScheme.primary;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              selected
                  ? brand
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : EagleTokens.paper),
          borderRadius: BorderRadius.circular(10),
          border: selected ? null : Border.all(color: line),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: brand.withValues(alpha: 0.32),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? Colors.white : mute,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  const _BroadcastCard({required this.broadcast});

  final Broadcast broadcast;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = Theme.of(context).colorScheme.primary;
    final publico = broadcast.tipoConsultoriaAlvo ?? 'TODOS';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  broadcast.titulo,
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: brand.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${broadcast.totalEnviados} alunos',
                  style: TextStyle(
                    color: brand,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            broadcast.mensagem,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: mute, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people_outline_rounded, size: 13, color: mute),
              const SizedBox(width: 4),
              Text(publico, style: TextStyle(color: mute, fontSize: 11)),
              const SizedBox(width: 12),
              Icon(Icons.schedule_rounded, size: 13, color: mute),
              const SizedBox(width: 4),
              Text(
                _formatarData(broadcast.enviadoEm),
                style: TextStyle(color: mute, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatarData(DateTime dt) {
    final dia = dt.day.toString().padLeft(2, '0');
    final mes = dt.month.toString().padLeft(2, '0');
    final hora = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dia/$mes · $hora:$min';
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? EagleTokens.darkLine : EagleTokens.line,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
        ),
      ),
    );
  }
}
