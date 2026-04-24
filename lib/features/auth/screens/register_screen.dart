import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/fx_logo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/design_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FOCUX PERSONAL — Premium Register Screen (Final Production)
//
// Aligned with login: same palette, glass, typography, grid
// ─────────────────────────────────────────────────────────────────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _senhaVisivel = false;

  // Password strength
  double _senhaForca = 0;

  late final AnimationController _entryCtrl;
  late final Animation<double> _entrySlide;
  late final Animation<double> _entryFade;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entrySlide = Tween<double>(begin: 32, end: 0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );
    _entryFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
      ),
    );
    _senhaCtrl.addListener(_calcForca);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _entryCtrl.forward();
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
    if (_senhaForca < 0.4) return EagleTokens.bad;
    if (_senhaForca < 0.7) return EagleTokens.warn;
    return EagleTokens.good;
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
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
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
      String msg = 'Erro ao criar conta. Verifique os dados.';
      if (e.toString().contains('409')) {
        msg = 'Este e-mail já está em uso.';
      } else if (e.toString().contains('DioException')) {
        msg = 'Falha na conexão com o servidor.';
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Layer 1: Deep gradient ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark ? EagleTokens.heroGradientDark : EagleTokens.heroGradientLight,
                  stops: const [0.0, 1.0],
                ),
              ),
            ),

            // ── Layer 2: Radial accent ──────────────────────────────────
            Positioned(
              top: -screenH * 0.12,
              left: 0,
              right: 0,
              child: Container(
                height: screenH * 0.50,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.65,
                    colors: [
                      EagleTokens.brand.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Layer 3: Grid ───────────────────────────────────────────
            CustomPaint(
              painter: _PremiumGridPainter(),
              size: Size.infinite,
            ),

            // ── Layer 4: Content ────────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 28,
                  right: 28,
                  top: screenH * 0.035,
                  bottom: 32,
                ),
                child: AnimatedBuilder(
                  animation: _entryCtrl,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _entrySlide.value),
                    child:
                        Opacity(opacity: _entryFade.value, child: child),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Header: Logo + Back ────────────────────
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const FxLogo(
                              iconSize: 42,
                              showLabel: true,
                              horizontal: true,
                              light: true,
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: EagleTokens.darkInk
                                      .withValues(alpha: 0.05),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                    color: EagleTokens.darkInk
                                        .withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: EagleTokens.darkInk
                                      .withValues(alpha: 0.65),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ─── Title ──────────────────────────────────
                        Text(
                          'Crie sua\nconta.',
                          style: TextStyle(
                            color: EagleTokens.darkInk,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1.08,
                            letterSpacing: -0.8,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'Treine com dados. Evolua com inteligência.',
                          style: TextStyle(
                            color: EagleTokens.darkInkMute,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ─── Name ───────────────────────────────────
                        _PremiumTextField(
                          controller: _nomeCtrl,
                          label: 'NOME COMPLETO',
                          hint: 'Carlos Silva',
                          icon: Icons.person_outline_rounded,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Informe o nome'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // ─── Email ──────────────────────────────────
                        _PremiumTextField(
                          controller: _emailCtrl,
                          label: 'E-MAIL PROFISSIONAL',
                          hint: 'personal@exemplo.com',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) => v == null || v.isEmpty
                              ? 'Informe o e-mail'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // ─── Password ───────────────────────────────
                        _PremiumTextField(
                          controller: _senhaCtrl,
                          label: 'SENHA',
                          hint: 'Mínimo 6 caracteres',
                          icon: Icons.lock_outline_rounded,
                          obscureText: !_senhaVisivel,
                          textInputAction: TextInputAction.done,
                          validator: (v) => v != null && v.length < 6
                              ? 'Mínimo 6 caracteres'
                              : null,
                          onFieldSubmitted: (_) => _submit(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _senhaVisivel
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color:
                                  EagleTokens.darkInk.withValues(alpha: 0.35),
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _senhaVisivel = !_senhaVisivel),
                          ),
                        ),

                        // Strength indicator
                        if (_senhaCtrl.text.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: _senhaForca,
                                    backgroundColor: EagleTokens.darkInk
                                        .withValues(alpha: 0.05),
                                    color: _forcaCor,
                                    minHeight: 3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _forcaTexto,
                                style: TextStyle(
                                  color: _forcaCor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // ─── Error ──────────────────────────────────
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: EagleTokens.bad
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: EagleTokens.bad
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: EagleTokens.bad,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: EagleTokens.bad,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // ─── Terms ──────────────────────────────────
                        Text.rich(
                          TextSpan(
                            text:
                                'Ao criar sua conta, você concorda com os ',
                            style: TextStyle(
                              color: EagleTokens.darkInkMute,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: 'Termos de Uso',
                                style: TextStyle(
                                  color: EagleTokens.brand
                                      .withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(text: ' e a '),
                              TextSpan(
                                text: 'Política de Privacidade',
                                style: TextStyle(
                                  color: EagleTokens.brand
                                      .withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ─── Submit ─────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EagleTokens.brand,
                              foregroundColor: EagleTokens.darkInk,
                              disabledBackgroundColor:
                                  EagleTokens.brand
                                      .withValues(alpha: 0.45),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Começar agora',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ─── Login link ─────────────────────────────
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Já tem conta? ',
                                style: TextStyle(
                                  color: EagleTokens.darkInkMute,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: Text(
                                  'Entrar',
                                  style: TextStyle(
                                    color: EagleTokens.brand,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
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

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED PREMIUM COMPONENTS (identical to login_screen)
// ═══════════════════════════════════════════════════════════════════════════════

class _PremiumTextField extends StatelessWidget {
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

  const _PremiumTextField({
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
          label,
          style: TextStyle(
            color: EagleTokens.darkInk.withValues(alpha: 0.45),
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
          textCapitalization: textCapitalization,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: TextStyle(
            color: EagleTokens.darkInk,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          cursorColor: EagleTokens.brand,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: EagleTokens.darkInk.withValues(alpha: 0.18),
              fontSize: 15,
            ),
            prefixIcon: Icon(
              icon,
              color: EagleTokens.darkInk.withValues(alpha: 0.30),
              size: 20,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: EagleTokens.darkInk.withValues(alpha: 0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: EagleTokens.darkInk.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: EagleTokens.darkInk.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: EagleTokens.brand, width: 1.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: EagleTokens.bad, width: 0.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: EagleTokens.bad, width: 1.0),
            ),
            errorStyle: TextStyle(
              color: EagleTokens.bad,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EagleTokens.darkInk.withValues(alpha: 0.010)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 48.0;

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
