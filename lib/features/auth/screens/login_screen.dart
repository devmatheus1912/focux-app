import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_logo.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FOCUX PERSONAL — Premium Login Screen (Final Production)
//
// Aligned with register: same palette, typography, grid, performance-optimized
// ─────────────────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
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
    final screenH = mq.size.height;

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
            // ── Layer 1: Deep gradient ──────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: EagleTokens.heroGradientDark,
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
            CustomPaint(painter: _PremiumGridPainter(), size: Size.infinite),

            // ── Layer 4: Content ────────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 28, right: 28,
                  top: screenH * 0.035, bottom: 32,
                ),
                child: AnimatedBuilder(
                  animation: _entryCtrl,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _entrySlide.value),
                    child: Opacity(opacity: _entryFade.value, child: child),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Header: Logo ──────────────────────────────
                        const FxLogo(
                          iconSize: 42,
                          showLabel: true,
                          horizontal: true,
                          light: true,
                        ),

                        const SizedBox(height: 28),

                        // ─── Title ──────────────────────────────────────
                        Text(
                          'Bem-vindo de\nvolta.',
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

                        // ─── Role Toggle ────────────────────────────────
                        _buildRoleToggle(),

                        const SizedBox(height: 24),

                        // ─── Email ──────────────────────────────────────
                        _PremiumTextField(
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

                        // ─── Password ───────────────────────────────────
                        _PremiumTextField(
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
                              color: EagleTokens.darkInk.withValues(alpha: 0.35),
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _senhaVisivel = !_senhaVisivel),
                          ),
                        ),

                        // ─── Forgot Password ────────────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/esqueci-senha'),
                            style: TextButton.styleFrom(
                              foregroundColor: EagleTokens.brand,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 12),
                            ),
                            child: Text('Esqueceu a senha?',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),

                        // ─── Error ──────────────────────────────────────
                        if (_error != null) _buildError(_error!),

                        const SizedBox(height: 12),

                        // ─── Submit ─────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EagleTokens.brand,
                              foregroundColor: EagleTokens.darkInk,
                              disabledBackgroundColor:
                                  EagleTokens.brand.withValues(alpha: 0.45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Entrar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ─── Create Account ─────────────────────────────
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Primeiro acesso? ',
                                  style: TextStyle(
                                      color: EagleTokens.darkInkMute,
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

  // ── Role Toggle (Solid, No Blur) ───────────────────────────────────

  Widget _buildRoleToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: EagleTokens.darkInk.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EagleTokens.darkInk.withValues(alpha: 0.08),
        ),
      ),
      child: Row(children: [
        _roleTab('Personal', Icons.sports_gymnastics_rounded, 'personal'),
        _roleTab('Aluno', Icons.person_rounded, 'aluno'),
      ]),
    );
  }

  Widget _roleTab(String label, IconData icon, String value) {
    final sel = _tipoLogin == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() { _tipoLogin = value; _error = null; }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? EagleTokens.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: EagleTokens.bad.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, color: EagleTokens.bad, size: 18),
        const SizedBox(width: 10),
        Expanded(
            child: Text(msg,
                style: TextStyle(color: EagleTokens.bad, fontSize: 13))),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED PREMIUM COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class _PremiumTextField extends StatelessWidget {
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

  const _PremiumTextField({
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
