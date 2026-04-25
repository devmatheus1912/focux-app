import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/design_tokens.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FOCUX PERSONAL — Glow Effect Premium Login
// Inspired by CSS Glow Edition: dramatic bottom glow, glass inputs,
// breathing animations, premium branding with text glow
// ─────────────────────────────────────────────────────────────────────────────

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

  late final AnimationController _entryCtrl;

  late final Animation<double> _entryFade;
  late final Animation<double> _entrySlide;

  @override
  void initState() {
    super.initState();

    // Simple entrance
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entryFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut),
    );
    _entrySlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _emailFocus.dispose();
    _senhaFocus.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    HapticFeedback.mediumImpact();
    try {
      if (_tipoLogin == 'aluno') {
        await ref.read(authProvider.notifier).loginAluno(
              _emailCtrl.text.trim(), _senhaCtrl.text);
        if (!mounted) return;
        final requiresPasswordChange = ref.read(requiresPasswordChangeProvider);
        context.go(
          requiresPasswordChange
              ? '/aluno/definir-senha'
              : '/dashboard/aluno',
        );
      } else {
        await ref.read(authProvider.notifier).login(
              _emailCtrl.text.trim(), _senhaCtrl.text);
        if (mounted) context.go('/dashboard/personal');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      String msg = 'Email ou senha incorretos.';
      if (e is DioException) {
        final s = e.response?.statusCode;
        if (s == null) {
          msg = 'Sem conexão com o servidor.';
        } else if (s != 401) {
          msg = 'Erro $s: ${e.response?.data?['message'] ?? e.message}';
        }
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final h = mq.size.height;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── L1: Deep gradient (same as register) ────────────────
            Container(
              decoration: BoxDecoration(
                gradient: EagleTokens.heroGradient(dark: true),
              ),
            ),

            // ── L2: Radial accent ───────────────────────────────────
            Positioned(
              top: -h * 0.12,
              left: 0,
              right: 0,
              child: Container(
                height: h * 0.50,
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

            // ── L3: Grid ────────────────────────────────────────────
            CustomPaint(painter: _PremiumGrid(), size: Size.infinite),

            // ── L6: Content ─────────────────────────────────────────
            SafeArea(
              child: AnimatedBuilder(
                animation: _entryCtrl,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _entrySlide.value),
                  child: Opacity(opacity: _entryFade.value, child: child),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 28, right: 28,
                    top: h * 0.03, bottom: 32,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // ═══ BRANDING HERO ═══
                        _buildBrandHero(isDark),

                        const SizedBox(height: 28),

                        // ═══ FORM SECTION ═══
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                // Welcome
                                Text(
                                  'Bem-vindo de volta.',
                                  style: TextStyle(
                                    color: (isDark ? EagleTokens.darkInk : EagleTokens.ink)
                                        .withValues(alpha: 0.92),
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    height: 1.05,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildRoleToggle(),
                                const SizedBox(height: 24),
                                _GlassTextField(
                                  controller: _emailCtrl,
                                  focusNode: _emailFocus,
                                  label: 'E-MAIL',
                                  hint: 'personal@exemplo.com',
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Informe o e-mail' : null,
                                  onFieldSubmitted: (_) =>
                                      _senhaFocus.requestFocus(),
                                ),
                                const SizedBox(height: 16),
                                _GlassTextField(
                                  controller: _senhaCtrl,
                                  focusNode: _senhaFocus,
                                  label: 'SENHA',
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: !_senhaVisivel,
                                  textInputAction: TextInputAction.done,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Informe a senha' : null,
                                  onFieldSubmitted: (_) => _submit(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _senhaVisivel
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white.withValues(alpha: 0.30),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _senhaVisivel = !_senhaVisivel),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () =>
                                        context.push('/esqueci-senha'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: EagleTokens.brand,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 8),
                                    ),
                                    child: Text('Esqueceu a senha?',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                ),
                                if (_error != null) _buildError(_error!),
                                const SizedBox(height: 4),
                                _buildGlowButton(),
                                const SizedBox(height: 24),
                                _buildCreateAccount(isDark),
                                const SizedBox(height: 28),
                                _buildSocialProof(),
                              ],
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

  // ── Brand Hero ─────────────────────────────────────────────────────

  Widget _buildBrandHero(bool isDark) {
    return Column(
      children: [
        // F icon with glow
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: EagleTokens.brand.withValues(alpha: 0.30),
                blurRadius: 56,
                spreadRadius: 12,
              ),
              BoxShadow(
                color: EagleTokens.brand.withValues(alpha: 0.10),
                blurRadius: 100,
                spreadRadius: 28,
              ),
            ],
          ),
          child: ShaderMask(
            shaderCallback: (b) => RadialGradient(
              radius: 0.70,
              colors: [
                Colors.white,
                Colors.white,
                Colors.white.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.88, 1.0],
            ).createShader(b),
            blendMode: BlendMode.dstIn,
            child: Image.asset(
              'assets/images/logo_icon.png',
              height: 120,
              width: 120,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Wordmark with glow text
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(children: [
            TextSpan(
              text: 'FOCUX ',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                letterSpacing: 2.5,
              ),
            ),
            TextSpan(
              text: 'PERSONAL',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w300,
                color: (isDark ? EagleTokens.darkInk : EagleTokens.ink)
                    .withValues(alpha: 0.78),
                letterSpacing: 1.0,
              ),
            ),
          ]),
        ),

        const SizedBox(height: 6),

        Text(
          'Treine com dados. Evolua com inteligência.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
            letterSpacing: 0.15,
          ),
        ),
      ],
    );
  }

  // ── Role Toggle (glass) ────────────────────────────────────────────

  Widget _buildRoleToggle() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06), width: 0.5),
          ),
          child: Row(children: [
            _roleTab('Personal', Icons.sports_gymnastics_rounded, 'personal'),
            _roleTab('Aluno', Icons.person_rounded, 'aluno'),
          ]),
        ),
      ),
    );
  }

  Widget _roleTab(String label, IconData icon, String value) {
    final sel = _tipoLogin == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _tipoLogin = value; _error = null; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel
                ? EagleTokens.brand.withValues(alpha: 0.85)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: sel
                ? Border.all(color: Colors.white.withValues(alpha: 0.12), width: 0.5)
                : null,
            boxShadow: sel
                ? [BoxShadow(
                    color: EagleTokens.brand.withValues(alpha: 0.35),
                    blurRadius: 16, offset: const Offset(0, 4))]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: sel ? Colors.white : EagleTokens.darkInkMute,
                  size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                    color: sel ? Colors.white : EagleTokens.darkInkMute,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Error Card ─────────────────────────────────────────────────────

  Widget _buildError(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: EagleTokens.badSoft.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: EagleTokens.bad.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded,
            color: EagleTokens.bad, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: TextStyle(
                    color: EagleTokens.bad, fontSize: 13))),
      ]),
    );
  }

  // ── Glow Button ────────────────────────────────────────────────────

  Widget _buildGlowButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [EagleTokens.brand, EagleTokens.brandInk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: EagleTokens.brand.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loading ? null : _submit,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text('Entrar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    )),
          ),
        ),
      ),
    );
  }

  // ── Create Account ─────────────────────────────────────────────────

  Widget _buildCreateAccount(bool isDark) {
    return Center(
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('Primeiro acesso? ',
            style: TextStyle(
                color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkSoft,
                fontSize: 14)),
        GestureDetector(
          onTap: () {
            if (_tipoLogin == 'aluno') {
              context.go('/register/aluno');
            } else {
              context.go('/register');
            }
          },
          child: Text('Criar conta',
              style: TextStyle(
                  color: EagleTokens.brand,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  // ── Social Proof ───────────────────────────────────────────────────

  Widget _buildSocialProof() {
    return Center(
      child: Column(children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
              5,
              (i) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(Icons.star_rounded,
                        color: Color(0xFFE8C55A), size: 17),
                  )),
        ),
        const SizedBox(height: 6),
        Text('Usado por +500 personal trainers no Brasil',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.30),
              fontSize: 12,
              letterSpacing: 0.2,
            )),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GLASS TEXT FIELD — BackdropFilter real blur
// ═══════════════════════════════════════════════════════════════════════════

class _GlassTextField extends StatelessWidget {
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

  const _GlassTextField({
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
        Text(label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            )),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              validator: validator,
              onFieldSubmitted: onFieldSubmitted,
              style: TextStyle(
                color: EagleTokens.darkInk,
                fontSize: 15,
              ),
              cursorColor: EagleTokens.brand,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.16),
                  fontSize: 15,
                ),
                prefixIcon: Icon(icon,
                    color: Colors.white.withValues(alpha: 0.28), size: 20),
                suffixIcon: suffixIcon,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: EagleTokens.brand.withValues(alpha: 0.70),
                      width: 1.0),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: EagleTokens.bad, width: 0.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: EagleTokens.bad, width: 1.0),
                ),
                errorStyle: TextStyle(
                    color: EagleTokens.bad, fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PREMIUM GRID
// ═══════════════════════════════════════════════════════════════════════════

class _PremiumGrid extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.008)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
