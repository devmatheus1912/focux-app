import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _senhaFocus = FocusNode();
  bool _loading = false;
  String? _error;
  String _tipoLogin = 'personal';
  bool _senhaVisivel = false;

  late final AnimationController _bgCtrl;
  late final AnimationController _formCtrl;
  late final Animation<double> _formSlide;
  late final Animation<double> _formFade;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _formCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _formSlide = Tween<double>(begin: 40, end: 0).animate(
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
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _emailFocus.dispose();
    _senhaFocus.dispose();
    _bgCtrl.dispose();
    _formCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    // Haptic feedback
    HapticFeedback.mediumImpact();

    try {
      if (_tipoLogin == 'aluno') {
        await ref.read(authProvider.notifier).loginAluno(
          _emailCtrl.text.trim(),
          _senhaCtrl.text,
        );
        if (mounted) context.go('/dashboard/aluno');
      } else {
        await ref.read(authProvider.notifier).login(
          _emailCtrl.text.trim(),
          _senhaCtrl.text,
        );
        if (mounted) context.go('/dashboard/personal');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      String msg = 'Email ou senha incorretos.';
      if (e is DioException) {
        final status = e.response?.statusCode;
        if (status == null) msg = 'Sem conexão com o servidor.';
        else if (status != 401) msg = 'Erro $status: ${e.response?.data?['message'] ?? e.message}';
      }
      setState(() { _error = msg; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                      stops: [
                        0.0,
                        0.25 + sin(t * 2 * pi) * 0.05,
                        0.5,
                        0.75 + cos(t * 2 * pi) * 0.05,
                        1.0,
                      ],
                    ),
                  ),
                );
              },
            ),

            // Subtle grid overlay
            CustomPaint(
              painter: _AuthGridPainter(),
              size: Size.infinite,
            ),

            // Content
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 28, right: 28,
                  top: mq.size.height * 0.08,
                  bottom: 32,
                ),
                child: AnimatedBuilder(
                  animation: _formCtrl,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _formSlide.value),
                      child: Opacity(
                        opacity: _formFade.value,
                        child: child,
                      ),
                    );
                  },
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                'assets/images/logo_focux.png',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'FOCUX PERSONAL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 48),

                        // Welcome text
                        const Text(
                          'Bem-vindo\nde volta.',
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
                          'Treine com dados. Evolua com inteligência.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Role toggle — glassmorphism
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              _RoleTab(
                                label: 'Personal',
                                icon: Icons.sports_gymnastics,
                                isSelected: _tipoLogin == 'personal',
                                onTap: () => setState(() { _tipoLogin = 'personal'; _error = null; }),
                              ),
                              _RoleTab(
                                label: 'Aluno',
                                icon: Icons.person,
                                isSelected: _tipoLogin == 'aluno',
                                onTap: () => setState(() { _tipoLogin = 'aluno'; _error = null; }),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Email field
                        _FxTextField(
                          controller: _emailCtrl,
                          focusNode: _emailFocus,
                          label: 'E-mail',
                          hint: 'personal@exemplo.com',
                          icon: Icons.alternate_email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) => v == null || v.isEmpty ? 'Informe o e-mail' : null,
                          onFieldSubmitted: (_) => _senhaFocus.requestFocus(),
                        ),

                        const SizedBox(height: 18),

                        // Password field
                        _FxTextField(
                          controller: _senhaCtrl,
                          focusNode: _senhaFocus,
                          label: 'Senha',
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          obscureText: !_senhaVisivel,
                          textInputAction: TextInputAction.done,
                          validator: (v) => v == null || v.isEmpty ? 'Informe a senha' : null,
                          onFieldSubmitted: (_) => _submit(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white.withValues(alpha: 0.4),
                              size: 20,
                            ),
                            onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                          ),
                        ),

                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/esqueci-senha'),
                            style: TextButton.styleFrom(
                              foregroundColor: EagleTokens.brandAccent,
                              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            child: const Text('Esqueceu a senha?'),
                          ),
                        ),

                        // Error message
                        if (_error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9E2B2B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF9E2B2B).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFFF8B8B), size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: Color(0xFFFF8B8B), fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 8),

                        // Login button
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
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Text(
                                    'Entrar',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Create account link
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Primeiro acesso? ',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (_tipoLogin == 'aluno') {
                                    context.go('/register/aluno');
                                  } else {
                                    context.go('/register');
                                  }
                                },
                                child: const Text(
                                  'Criar conta',
                                  style: TextStyle(
                                    color: EagleTokens.brandAccent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Social proof
                        Center(
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  5,
                                  (i) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 1),
                                    child: Icon(
                                      Icons.star_rounded,
                                      color: const Color(0xFFFFD37A),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Usado por +500 personal trainers no Brasil',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  fontSize: 11.5,
                                  letterSpacing: 0.3,
                                ),
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

// ── Custom Widgets ──────────────────────────────────────────────────────────

class _RoleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? EagleTokens.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [BoxShadow(color: EagleTokens.brand.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4), size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FxTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
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
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: EagleTokens.brand, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF8B8B)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF8B8B), width: 1.5),
            ),
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
