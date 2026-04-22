import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/alunos_provider.dart';

const _generos = ['Masculino', 'Feminino', 'Outro'];
const _tiposConsultoria = ['ONLINE', 'PRESENCIAL', 'HIBRIDO'];
const _tiposConsultoriaLabel = ['Online', 'Presencial', 'Híbrido'];

class AddAlunoScreen extends ConsumerStatefulWidget {
  const AddAlunoScreen({super.key});

  @override
  ConsumerState<AddAlunoScreen> createState() => _AddAlunoScreenState();
}

class _AddAlunoScreenState extends ConsumerState<AddAlunoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  String? _genero;
  String? _tipoConsultoria;
  bool _loading = false;
  String? _error;

  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _objetivoCtrl.dispose();
    _whatsappCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    HapticFeedback.mediumImpact();
    try {
      final novoAluno = await ref.read(alunoRepositoryProvider).criar(
        nome: _nomeCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        objetivo: _objetivoCtrl.text.trim(),
        whatsapp: _whatsappCtrl.text.trim(),
        genero: _genero,
        tipoConsultoria: _tipoConsultoria,
      );
      if (mounted) {
        if (novoAluno.senhaProvisoria != null) {
          _showSenhaBottomSheet(novoAluno);
        } else {
          HapticFeedback.heavyImpact();
          context.pop(true);
        }
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() { _error = 'Erro ao cadastrar aluno. Verifique os dados.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _showSenhaBottomSheet(final aluno) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: isDark ? EagleTokens.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(28).copyWith(bottom: 28 + MediaQuery.of(ctx).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: EagleTokens.good.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: EagleTokens.good, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Aluno cadastrado!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? EagleTokens.darkInk : EagleTokens.ink),
            ),
            const SizedBox(height: 8),
            Text(
              'Senha provisória gerada. Compartilhe com o aluno:',
              style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                color: EagleTokens.brand.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EagleTokens.brand.withValues(alpha: 0.2)),
              ),
              child: Text(
                aluno.senhaProvisoria!,
                style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 6,
                  color: isDark ? Colors.white : EagleTokens.ink,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  final texto = 'Olá ${aluno.nome.split(' ').first}! Seu perfil no Focux foi criado.\n\nAcesse com seu e-mail: ${aluno.email}\nSenha provisória: ${aluno.senhaProvisoria}\n\nLembre-se de alterar a senha no primeiro acesso!';
                  Clipboard.setData(ClipboardData(text: texto));
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mensagem copiada!')),
                  );
                  Navigator.of(ctx).pop();
                  if (mounted) context.pop(true);
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copiar convite'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EagleTokens.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () { Navigator.of(ctx).pop(); if (mounted) context.pop(true); },
              child: Text('Fechar', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Novo Aluno', style: TextStyle(color: isDark ? EagleTokens.darkInk : EagleTokens.ink, fontWeight: FontWeight.w700)),
        iconTheme: IconThemeData(color: isDark ? EagleTokens.darkInk : EagleTokens.ink),
      ),
      body: FadeTransition(
        opacity: _entryFade,
        child: SlideTransition(
          position: _entrySlide,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: basic info
                  _SectionHeader(label: 'INFORMAÇÕES BÁSICAS', icon: Icons.person_outline, isDark: isDark),
                  const SizedBox(height: 16),
                  _FxFormField(controller: _nomeCtrl, label: 'Nome completo', icon: Icons.person_outline, isDark: isDark, validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null, textCapitalization: TextCapitalization.words),
                  const SizedBox(height: 14),
                  _FxFormField(controller: _emailCtrl, label: 'E-mail', icon: Icons.alternate_email, isDark: isDark, keyboardType: TextInputType.emailAddress, validator: (v) => v == null || v.isEmpty ? 'Informe o e-mail' : null),
                  const SizedBox(height: 14),
                  _FxFormField(controller: _whatsappCtrl, label: 'WhatsApp (opcional)', icon: Icons.phone_outlined, isDark: isDark, keyboardType: TextInputType.phone, hint: '(11) 99999-9999'),

                  const SizedBox(height: 28),
                  _SectionHeader(label: 'PERFIL', icon: Icons.tune, isDark: isDark),
                  const SizedBox(height: 16),
                  _FxFormField(controller: _objetivoCtrl, label: 'Objetivo', icon: Icons.flag_outlined, isDark: isDark, hint: 'Hipertrofia, Emagrecimento...', maxLines: 2),
                  const SizedBox(height: 14),

                  // Gender chips
                  Text('Gênero', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _generos.map((g) => ChoiceChip(
                      label: Text(g),
                      selected: _genero == g,
                      onSelected: (sel) => setState(() => _genero = sel ? g : null),
                      selectedColor: EagleTokens.brand.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: _genero == g ? EagleTokens.brand : (isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
                        fontWeight: _genero == g ? FontWeight.w600 : FontWeight.w400,
                      ),
                      side: BorderSide(color: _genero == g ? EagleTokens.brand.withValues(alpha: 0.4) : (isDark ? EagleTokens.darkLine : EagleTokens.line)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    )).toList(),
                  ),

                  const SizedBox(height: 14),

                  // Consultoria chips
                  Text('Consultoria', style: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: List.generate(_tiposConsultoria.length, (i) {
                      final sel = _tipoConsultoria == _tiposConsultoria[i];
                      return ChoiceChip(
                        label: Text(_tiposConsultoriaLabel[i]),
                        selected: sel,
                        onSelected: (s) => setState(() => _tipoConsultoria = s ? _tiposConsultoria[i] : null),
                        selectedColor: EagleTokens.brand.withValues(alpha: 0.15),
                        labelStyle: TextStyle(color: sel ? EagleTokens.brand : (isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute), fontWeight: sel ? FontWeight.w600 : FontWeight.w400),
                        side: BorderSide(color: sel ? EagleTokens.brand.withValues(alpha: 0.4) : (isDark ? EagleTokens.darkLine : EagleTokens.line)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      );
                    }),
                  ),

                  // Error
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

                  // Submit
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading ? const SizedBox.shrink() : const Icon(Icons.person_add, size: 20),
                      label: _loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Cadastrar Aluno', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EagleTokens.brand,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: EagleTokens.brand.withValues(alpha: 0.5),
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
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;
  const _SectionHeader({required this.label, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: EagleTokens.brand),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(color: EagleTokens.brand, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    ]);
  }
}

class _FxFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FxFormField({required this.controller, required this.label, required this.icon, required this.isDark, this.hint, this.keyboardType, this.textCapitalization = TextCapitalization.none, this.maxLines = 1, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: isDark ? EagleTokens.darkInk : EagleTokens.ink, fontSize: 15),
      cursorColor: EagleTokens.brand,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
        filled: true,
        fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
        labelStyle: TextStyle(color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
        hintStyle: TextStyle(color: (isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute).withValues(alpha: 0.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EagleTokens.brand, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EagleTokens.bad)),
        errorStyle: const TextStyle(color: EagleTokens.bad, fontSize: 11),
      ),
    );
  }
}
