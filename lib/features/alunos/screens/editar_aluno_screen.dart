import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/aluno_repository.dart';
import '../../../core/utils/friendly_error.dart';

class EditarAlunoScreen extends ConsumerStatefulWidget {
  final Aluno aluno;
  const EditarAlunoScreen({super.key, required this.aluno});

  @override
  ConsumerState<EditarAlunoScreen> createState() => _EditarAlunoScreenState();
}

class _EditarAlunoScreenState extends ConsumerState<EditarAlunoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _telefone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _objetivo;
  String? _genero;
  String? _tipoConsultoria;
  bool _salvando = false;

  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.aluno.nome);
    _email = TextEditingController(text: widget.aluno.email);
    _telefone = TextEditingController(text: widget.aluno.telefone ?? '');
    _whatsapp = TextEditingController(text: widget.aluno.whatsapp ?? '');
    _objetivo = TextEditingController(text: widget.aluno.objetivo ?? '');
    _genero = widget.aluno.genero;
    _tipoConsultoria = widget.aluno.tipoConsultoria ?? 'ONLINE';

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _whatsapp.dispose();
    _objetivo.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    HapticFeedback.mediumImpact();
    try {
      final repo = AlunoRepository(ref.read(apiClientProvider));
      await repo.atualizarAluno(widget.aluno.id, {
        'nome': _nome.text.trim(),
        'email': _email.text.trim(),
        'telefone': _telefone.text.trim().isEmpty ? null : _telefone.text.trim(),
        'whatsapp': _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
        'objetivo': _objetivo.text.trim().isEmpty ? null : _objetivo.text.trim(),
        'genero': _genero,
        'tipoConsultoria': _tipoConsultoria,
      });
      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aluno atualizado!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Editar Aluno', style: TextStyle(color: isDark ? EagleTokens.darkInk : EagleTokens.ink, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: isDark ? EagleTokens.darkInk : EagleTokens.ink),
        actions: [
          _salvando
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : TextButton(
                  onPressed: _salvar,
                  child: Text('Salvar', style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
        ],
      ),
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + name header
                Center(
                  child: Column(children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: primary.withValues(alpha: 0.12),
                      child: Text(
                        fxInitials(widget.aluno.nome),
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: primary),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(widget.aluno.nome, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? EagleTokens.darkInk : EagleTokens.ink)),
                  ]),
                ),

                const SizedBox(height: 28),
                _SectionHeader(label: 'INFORMAÇÕES BÁSICAS', icon: Icons.person_outline, isDark: isDark),
                const SizedBox(height: 16),
                _FxFormField(controller: _nome, label: 'Nome completo *', icon: Icons.person_outline, isDark: isDark, validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null, textCapitalization: TextCapitalization.words),
                const SizedBox(height: 14),
                _FxFormField(controller: _email, label: 'E-mail *', icon: Icons.alternate_email, isDark: isDark, keyboardType: TextInputType.emailAddress, validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null),
                const SizedBox(height: 14),
                _FxFormField(controller: _telefone, label: 'Telefone', icon: Icons.phone_outlined, isDark: isDark, keyboardType: TextInputType.phone),
                const SizedBox(height: 14),
                _FxFormField(controller: _whatsapp, label: 'WhatsApp', icon: Icons.chat_outlined, isDark: isDark, keyboardType: TextInputType.phone),

                const SizedBox(height: 28),
                _SectionHeader(label: 'PERFIL DO ALUNO', icon: Icons.tune, isDark: isDark),
                const SizedBox(height: 16),
                _FxFormField(controller: _objetivo, label: 'Objetivo', icon: Icons.flag_outlined, isDark: isDark, maxLines: 2),
                const SizedBox(height: 14),

                // Gender chips
                Text('Gênero', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['MASCULINO', 'FEMININO', 'OUTRO'].map((g) {
                    final sel = _genero == g;
                    return ChoiceChip(
                      label: Text(g[0] + g.substring(1).toLowerCase()),
                      selected: sel,
                      onSelected: (s) => setState(() => _genero = s ? g : null),
                      selectedColor: primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(color: sel ? primary : (isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute), fontWeight: sel ? FontWeight.w600 : FontWeight.w400),
                      side: BorderSide(color: sel ? primary.withValues(alpha: 0.4) : (isDark ? EagleTokens.darkLine : EagleTokens.line)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),
                Text('Consultoria', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [('ONLINE', 'Online'), ('PRESENCIAL', 'Presencial'), ('HIBRIDO', 'Híbrido')].map((e) {
                    final sel = _tipoConsultoria == e.$1;
                    return ChoiceChip(
                      label: Text(e.$2),
                      selected: sel,
                      onSelected: (s) => setState(() => _tipoConsultoria = s ? e.$1 : null),
                      selectedColor: primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(color: sel ? primary : (isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute), fontWeight: sel ? FontWeight.w600 : FontWeight.w400),
                      side: BorderSide(color: sel ? primary.withValues(alpha: 0.4) : (isDark ? EagleTokens.darkLine : EagleTokens.line)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height: 54,
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(_salvando ? 'Salvando...' : 'Salvar alterações', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  const _SectionHeader({required this.label, required this.icon, required this.isDark});
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(children: [
      Icon(icon, size: 16, color: primary),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    ]);
  }
}

class _FxFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final String? Function(String?)? validator;
  const _FxFormField({required this.controller, required this.label, required this.icon, required this.isDark, this.keyboardType, this.textCapitalization = TextCapitalization.none, this.maxLines = 1, this.validator});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      validator: validator,
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
