import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_logo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class RegisterAlunoScreen extends ConsumerStatefulWidget {
  const RegisterAlunoScreen({super.key});

  @override
  ConsumerState<RegisterAlunoScreen> createState() => _RegisterAlunoScreenState();
}

class _RegisterAlunoScreenState extends ConsumerState<RegisterAlunoScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _conviteCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _senhaVisivel = false;

  late final AnimationController _bgCtrl;
  late final AnimationController _formCtrl;
  late final Animation<double> _formSlide;
  late final Animation<double> _formFade;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _formCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _formSlide = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutCubic),
    );
    _formFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _formCtrl, curve: const Interval(0.1, 1.0, curve: Curves.easeOut)),
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _formCtrl.forward();
    });
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _conviteCtrl.dispose();
    _bgCtrl.dispose();
    _formCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    HapticFeedback.mediumImpact();

    try {
      await ref.read(authProvider.notifier).registerAluno(
        _nomeCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _senhaCtrl.text,
        _conviteCtrl.text.trim(),
      );
      if (mounted) {
        HapticFeedback.heavyImpact();
        context.go('/dashboard/aluno');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() { _error = 'Erro ao criar conta. Verifique o código de convite.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkColor = isDark ? EagleTokens.darkInk : EagleTokens.card;
    final inkMuteColor = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Animated gradient background
            AnimatedBuilder(
              animation: _bgCtrl,
              builder: (context, _) {
                final t = _bgCtrl.value;
                final gradientColors = isDark ? EagleTokens.heroGradientDark : EagleTokens.heroGradientLight;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 + sin(t * 2 * pi) * 0.3, -1.0 + cos(t * 2 * pi) * 0.3),
                      end: Alignment(1.0 + cos(t * 2 * pi) * 0.3, 1.0 + sin(t * 2 * pi) * 0.3),
                      colors: [
                        gradientColors[0],
                        gradientColors[1],
                        gradientColors[1],
                        gradientColors[1],
                        gradientColors[0],
                      ],
                    ),
                  ),
                );
              },
            ),

            CustomPaint(painter: _AuthGridPainter(), size: Size.infinite),

            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(left: 28, right: 28, top: mq.size.height * 0.04, bottom: 32),
                child: AnimatedBuilder(
                  animation: _formCtrl,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _formSlide.value),
                    child: Opacity(opacity: _formFade.value, child: child),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo & Back button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const FxLogo(iconSize: 42, showLabel: true, horizontal: true, light: true),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  color: EagleTokens.darkInk.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: EagleTokens.darkInk.withValues(alpha: 0.08)),
                                ),
                                child: Icon(Icons.arrow_back, color: EagleTokens.darkInk.withValues(alpha: 0.7), size: 20),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Hero invite badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: EagleTokens.brand.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: EagleTokens.brand.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mail_outline, color: EagleTokens.brandAccent, size: 16),
                              const SizedBox(width: 8),
                              const Text(
                                'Convite do seu Personal',
                                style: TextStyle(color: EagleTokens.brandAccent, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'Bem-vindo\nao Focux.',
                          style: TextStyle(
                            color: inkColor,
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Insira o código que seu personal enviou e configure sua conta.',
                          style: TextStyle(color: inkMuteColor, fontSize: 15, height: 1.4),
                        ),

                        const SizedBox(height: 36),

                        // Invite code field (special highlight)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CÓDIGO DO CONVITE',
                              style: TextStyle(color: EagleTokens.brandAccent.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _conviteCtrl,
                              textCapitalization: TextCapitalization.characters,
                              style: TextStyle(color: inkColor, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 4),
                              textAlign: TextAlign.center,
                              cursorColor: EagleTokens.brand,
                              validator: (v) => v == null || v.isEmpty ? 'Informe o código' : null,
                              decoration: InputDecoration(
                                hintText: '• • • • • •',
                                hintStyle: TextStyle(color: inkColor.withValues(alpha: 0.15), letterSpacing: 6),
                                filled: true,
                                fillColor: EagleTokens.brand.withValues(alpha: 0.08),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: EagleTokens.brand.withValues(alpha: 0.25))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: EagleTokens.brand.withValues(alpha: 0.25))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EagleTokens.brand, width: 1.5)),
                                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: EagleTokens.bad)),
                                errorStyle: TextStyle(color: EagleTokens.bad, fontSize: 11),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Standard fields
                        _FxTextField(controller: _nomeCtrl, label: 'Nome completo', hint: 'Maria Souza', icon: Icons.person_outline, textCapitalization: TextCapitalization.words, validator: (v) => v == null || v.isEmpty ? 'Informe seu nome' : null),
                        const SizedBox(height: 18),

                        _FxTextField(controller: _emailCtrl, label: 'E-mail', hint: 'aluno@exemplo.com', icon: Icons.alternate_email, keyboardType: TextInputType.emailAddress, validator: (v) => v == null || v.isEmpty ? 'Informe o e-mail' : null),
                        const SizedBox(height: 18),

                        _FxTextField(
                          controller: _senhaCtrl,
                          label: 'Senha',
                          hint: 'Mínimo 6 caracteres',
                          icon: Icons.lock_outline,
                          obscureText: !_senhaVisivel,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Informe a senha';
                            if (v.length < 6) return 'Mínimo de 6 caracteres';
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(_senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: inkColor.withValues(alpha: 0.4), size: 20),
                            onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                          ),
                        ),

                        // Error
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: EagleTokens.badSoft.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.3)),
                            ),
                            child: Row(children: [
                              Icon(Icons.error_outline, color: EagleTokens.bad, size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_error!, style: TextStyle(color: EagleTokens.bad, fontSize: 13))),
                            ]),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Submit
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EagleTokens.brand,
                              foregroundColor: EagleTokens.card,
                              disabledBackgroundColor: EagleTokens.brand.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _loading
                                ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: EagleTokens.card))
                                : const Text('Criar conta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Já tem conta? ', style: TextStyle(color: inkColor.withValues(alpha: 0.45), fontSize: 14)),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: const Text('Entrar', style: TextStyle(color: EagleTokens.brandAccent, fontSize: 14, fontWeight: FontWeight.w600)),
                              ),
                            ],
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

// Reusable text field
class _FxTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const _FxTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inkColor = isDark ? EagleTokens.darkInk : EagleTokens.card;
    final inkMuteColor = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: inkMuteColor, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: TextStyle(color: inkColor, fontSize: 15),
          cursorColor: EagleTokens.brand,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: inkColor.withValues(alpha: 0.2)),
            prefixIcon: Icon(icon, color: inkColor.withValues(alpha: 0.35), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: inkColor.withValues(alpha: 0.06),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: inkColor.withValues(alpha: 0.08))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: inkColor.withValues(alpha: 0.08))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EagleTokens.brand, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: EagleTokens.bad)),
            errorStyle: TextStyle(color: EagleTokens.bad, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _AuthGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EagleTokens.darkInk.withValues(alpha: 0.025)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    const spacing = 50.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
