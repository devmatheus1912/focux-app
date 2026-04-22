import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _senhaVisivel = false;

  // Password strength tracking
  double _senhaForca = 0;

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

    _senhaCtrl.addListener(_calcForca);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _formCtrl.forward();
    });
  }

  void _calcForca() {
    final s = _senhaCtrl.text;
    double f = 0;
    if (s.length >= 6) f += 0.25;
    if (s.length >= 8) f += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(s)) f += 0.2;
    if (RegExp(r'[0-9]').hasMatch(s)) f += 0.2;
    if (RegExp(r'[!@#\$%\^&\*]').hasMatch(s)) f += 0.2;
    setState(() => _senhaForca = f.clamp(0, 1));
  }

  Color get _forcaCor {
    if (_senhaForca < 0.4) return const Color(0xFFFF8B8B);
    if (_senhaForca < 0.7) return const Color(0xFFE2B46F);
    return const Color(0xFF6FE296);
  }

  String get _forcaTexto {
    if (_senhaCtrl.text.isEmpty) return '';
    if (_senhaForca < 0.4) return 'Fraca';
    if (_senhaForca < 0.7) return 'Média';
    return 'Forte';
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _bgCtrl.dispose();
    _formCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    HapticFeedback.mediumImpact();

    try {
      await ref.read(authProvider.notifier).register(
        _nomeCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _senhaCtrl.text,
      );
      if (mounted) {
        HapticFeedback.heavyImpact();
        context.go('/dashboard/personal');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() { _error = 'Erro ao criar conta. Verifique os dados.'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

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
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(
                        -1.0 + sin(t * 2 * pi) * 0.3,
                        -1.0 + cos(t * 2 * pi) * 0.3,
                      ),
                      end: Alignment(
                        1.0 + cos(t * 2 * pi) * 0.3,
                        1.0 + sin(t * 2 * pi) * 0.3,
                      ),
                      colors: const [
                        Color(0xFF0A0F1E),
                        Color(0xFF0D1B5C),
                        Color(0xFF1C3273),
                        Color(0xFF0D1B5C),
                        Color(0xFF0A0F1E),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Grid overlay
            CustomPaint(painter: _AuthGridPainter(), size: Size.infinite),

            // Content
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 28, right: 28,
                  top: mq.size.height * 0.04,
                  bottom: 32,
                ),
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
                        // Back button
                        GestureDetector(
                          onTap: () => context.go('/login'),
                          child: Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: Icon(Icons.arrow_back, color: Colors.white.withValues(alpha: 0.7), size: 20),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Title
                        const Text(
                          'Crie sua\nconta.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Comece a transformar a gestão dos seus alunos hoje.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Name field
                        _FxTextField(
                          controller: _nomeCtrl,
                          label: 'Nome completo',
                          hint: 'Carlos Silva',
                          icon: Icons.person_outline,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                        ),
                        const SizedBox(height: 18),

                        // Email field
                        _FxTextField(
                          controller: _emailCtrl,
                          label: 'E-mail profissional',
                          hint: 'personal@exemplo.com',
                          icon: Icons.alternate_email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) => v == null || v.isEmpty ? 'Informe o e-mail' : null,
                        ),
                        const SizedBox(height: 18),

                        // Password field with strength meter
                        _FxTextField(
                          controller: _senhaCtrl,
                          label: 'Senha',
                          hint: 'Mínimo 6 caracteres',
                          icon: Icons.lock_outline,
                          obscureText: !_senhaVisivel,
                          validator: (v) => v != null && v.length < 6 ? 'Mínimo 6 caracteres' : null,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white.withValues(alpha: 0.4),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                          ),
                        ),

                        // Strength indicator
                        if (_senhaCtrl.text.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _senhaForca,
                                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                                    color: _forcaCor,
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _forcaTexto,
                                style: TextStyle(color: _forcaCor, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],

                        // Error
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9E2B2B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF9E2B2B).withValues(alpha: 0.3)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline, color: Color(0xFFFF8B8B), size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFFF8B8B), fontSize: 13))),
                            ]),
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Terms
                        Text.rich(
                          TextSpan(
                            text: 'Ao criar sua conta, você concorda com os ',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
                            children: [
                              TextSpan(
                                text: 'Termos de Uso',
                                style: TextStyle(color: EagleTokens.brandAccent.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                              ),
                              const TextSpan(text: ' e a '),
                              TextSpan(
                                text: 'Política de Privacidade',
                                style: TextStyle(color: EagleTokens.brandAccent.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EagleTokens.brand,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: EagleTokens.brand.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : const Text('Começar agora', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Link to login
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Já tem conta? ', style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 14)),
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

// Reusable field (same as login)
class _FxTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffixIcon;

  const _FxTextField({
    required this.controller,
    this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onFieldSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          cursorColor: EagleTokens.brand,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.35), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EagleTokens.brand, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFF8B8B))),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFF8B8B), width: 1.5)),
            errorStyle: const TextStyle(color: Color(0xFFFF8B8B), fontSize: 11),
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
      ..color = Colors.white.withValues(alpha: 0.025)
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
