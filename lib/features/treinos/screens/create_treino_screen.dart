import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/treinos_provider.dart';

const _niveis = ['INICIANTE', 'INTERMEDIARIO', 'AVANCADO'];
const _niveisLabel = ['Iniciante', 'Intermediário', 'Avançado'];
const _niveisIcon = [Icons.eco, Icons.speed, Icons.local_fire_department];
const _niveisCor = [EagleTokens.good, EagleTokens.warn, EagleTokens.bad];

class CreateTreinoScreen extends ConsumerStatefulWidget {
  const CreateTreinoScreen({super.key});

  @override
  ConsumerState<CreateTreinoScreen> createState() => _CreateTreinoScreenState();
}

class _CreateTreinoScreenState extends ConsumerState<CreateTreinoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController();
  String? _nivel;
  bool _loading = false;
  String? _error;

  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _objetivoCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    HapticFeedback.mediumImpact();
    try {
      await ref.read(treinoRepositoryProvider).criar(
        _nomeCtrl.text.trim(),
        _descricaoCtrl.text.trim(),
        _objetivoCtrl.text.trim(),
        _nivel,
      );
      if (mounted) {
        HapticFeedback.heavyImpact();
        context.pop(true);
      }
    } catch (e) {
      String msg = 'Erro ao criar treino.';
      if (e is DioException) {
        final serverMsg = e.response?.data?['mensagem'] ??
            e.response?.data?['message'] ??
            e.response?.data?['erro'];
        if (serverMsg != null) msg = serverMsg.toString();
      }
      if (mounted) setState(() { _error = msg; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOVO ITEM',
                        style: TextStyle(fontSize: 12, color: mute, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Novo Treino',
                        style: TextStyle(fontSize: 28, color: ink, fontWeight: FontWeight.w600, letterSpacing: -0.5),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: mute),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
                child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header icon
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.fitness_center, color: primary, size: 28),
                ),
                const SizedBox(height: 16),
                Text('Configure o treino', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? EagleTokens.darkInk : EagleTokens.ink)),
                const SizedBox(height: 6),
                Text('Defina nome, nível e objetivo.', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 14)),

                const SizedBox(height: 28),

                _FxField(controller: _nomeCtrl, label: 'Nome do treino', icon: Icons.edit_outlined, isDark: isDark, validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null),
                const SizedBox(height: 14),

                // Level selector cards
                Text('NÍVEL', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(3, (i) {
                    final sel = _nivel == _niveis[i];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _nivel = _niveis[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: sel ? _niveisCor[i].withValues(alpha: 0.12) : (isDark ? EagleTokens.darkCard : EagleTokens.card),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: sel ? _niveisCor[i].withValues(alpha: 0.4) : (isDark ? EagleTokens.darkLine : EagleTokens.line)),
                          ),
                          child: Column(children: [
                            Icon(_niveisIcon[i], color: sel ? _niveisCor[i] : (isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute), size: 22),
                            const SizedBox(height: 6),
                            Text(_niveisLabel[i], style: TextStyle(color: sel ? _niveisCor[i] : (isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute), fontSize: 11, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                          ]),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 18),
                _FxField(controller: _objetivoCtrl, label: 'Objetivo (opcional)', icon: Icons.flag_outlined, isDark: isDark),
                const SizedBox(height: 14),
                _FxField(controller: _descricaoCtrl, label: 'Descrição (opcional)', icon: Icons.notes, isDark: isDark, maxLines: 3),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: EagleTokens.bad.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.25)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: EagleTokens.bad, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: EagleTokens.bad, fontSize: 13))),
                    ]),
                  ),
                ],

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading ? const SizedBox.shrink() : const Icon(Icons.add, size: 20),
                    label: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Criar Treino', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FxField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final int maxLines;
  final String? Function(String?)? validator;
  const _FxField({required this.controller, required this.label, required this.icon, required this.isDark, this.maxLines = 1, this.validator});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return TextFormField(
      controller: controller, maxLines: maxLines, validator: validator,
      style: TextStyle(color: isDark ? EagleTokens.darkInk : EagleTokens.ink, fontSize: 15),
      cursorColor: primary,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
        filled: true,
        fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
        labelStyle: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EagleTokens.bad)),
        errorStyle: const TextStyle(color: EagleTokens.bad, fontSize: 11),
      ),
    );
  }
}
