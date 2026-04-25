import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_logo.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FOCUX PERSONAL — Premium Esqueci Senha (Final Production)
//
// Aligned with login/register: same palette, typography, grid, performance-optimized
// ─────────────────────────────────────────────────────────────────────────────

class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  String _tipo = 'PERSONAL';
  int _step = 0; // 0 = email, 1 = token+senha, 2 = success
  bool _loading = false;
  bool _senhaVisivel = false;

  late final AnimationController _stepCtrl;
  late final Animation<double> _stepSlide;
  late final Animation<double> _stepFade;

  @override
  void initState() {
    super.initState();
    _stepCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _stepSlide = Tween<double>(begin: 30, end: 0).animate(
        CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOutCubic));
    _stepFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
        parent: _stepCtrl, curve: const Interval(0.15, 1.0, curve: Curves.easeOut)));
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _stepCtrl.forward();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmarCtrl.dispose();
    _stepCtrl.dispose();
    super.dispose();
  }

  void _animateStepForward(int newStep) {
    _stepCtrl.reset();
    setState(() => _step = newStep);
    _stepCtrl.forward();
    HapticFeedback.mediumImpact();
  }

  Future<void> _solicitarToken() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    try {
      final dio = ApiClient().dio;
      await dio.post('/api/auth/esqueci-senha',
          data: {'email': email, 'tipo': _tipo});
      _animateStepForward(1);
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${_extrairMensagem(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _redefinirSenha() async {
    final token = _tokenCtrl.text.trim();
    final nova = _senhaCtrl.text;
    final confirmar = _confirmarCtrl.text;
    if (token.isEmpty || nova.isEmpty) return;
    if (nova != confirmar) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('As senhas não coincidem')));
      return;
    }
    if (nova.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha deve ter pelo menos 6 caracteres')));
      return;
    }
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    try {
      final dio = ApiClient().dio;
      await dio.post('/api/auth/resetar-senha',
          data: {'token': token, 'novaSenha': nova});
      _animateStepForward(2);
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${_extrairMensagem(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _extrairMensagem(dynamic e) {
    if (e is DioException && e.response?.data is Map) {
      return e.response?.data['message'] ?? e.message ?? 'Erro desconhecido';
    }
    return e.toString();
  }

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
                padding: EdgeInsets.only(
                    left: 28, right: 28, top: screenH * 0.035, bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo & Back button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const FxLogo(
                            iconSize: 42,
                            showLabel: true,
                            horizontal: true,
                            light: true),
                        GestureDetector(
                          onTap: () {
                            if (_step == 1) {
                              _animateStepForward(0);
                            } else {
                              context.pop();
                            }
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: EagleTokens.darkInk.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: EagleTokens.darkInk
                                      .withValues(alpha: 0.08)),
                            ),
                            child: Icon(Icons.arrow_back_rounded,
                                color: EagleTokens.darkInk
                                    .withValues(alpha: 0.65),
                                size: 20),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Step indicator
                    if (_step < 2)
                      Row(
                        children: List.generate(
                            2,
                            (i) => Expanded(
                                  child: Container(
                                    height: 3,
                                    margin: EdgeInsets.only(right: i < 1 ? 6 : 0),
                                    decoration: BoxDecoration(
                                      color: i <= _step
                                          ? EagleTokens.brand
                                          : EagleTokens.darkInk
                                              .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                )),
                      ),

                    const SizedBox(height: 32),

                    // Step content (animated)
                    AnimatedBuilder(
                      animation: _stepCtrl,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(0, _stepSlide.value),
                        child: Opacity(opacity: _stepFade.value, child: child),
                      ),
                      child: _buildStepContent(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shield icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: EagleTokens.brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.shield_outlined,
              color: EagleTokens.brandAccent, size: 28),
        ),
        const SizedBox(height: 20),

        Text(
          'Recuperar\nacesso.',
          style: TextStyle(
              color: EagleTokens.darkInk,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.08,
              letterSpacing: -0.8),
        ),
        const SizedBox(height: 10),
        Text(
          'Informe seu e-mail e enviaremos um código de verificação.',
          style: TextStyle(
              color: EagleTokens.darkInkMute,
              fontSize: 14,
              fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 36),

        // Account type toggle
        _buildRoleToggle(),
        const SizedBox(height: 24),

        _PremiumTextField(
            controller: _emailCtrl,
            label: 'E-MAIL CADASTRADO',
            hint: 'seu@email.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _solicitarToken,
            style: ElevatedButton.styleFrom(
              backgroundColor: EagleTokens.brand,
              foregroundColor: EagleTokens.darkInk,
              disabledBackgroundColor: EagleTokens.brand.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Enviar código',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3)),
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: () => _animateStepForward(1),
            style: TextButton.styleFrom(
                foregroundColor: EagleTokens.brandAccent),
            child: const Text('Já tenho um código',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: EagleTokens.brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.vpn_key_outlined,
              color: EagleTokens.brandAccent, size: 28),
        ),
        const SizedBox(height: 20),

        Text(
          'Nova\nsenha.',
          style: TextStyle(
              color: EagleTokens.darkInk,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.08,
              letterSpacing: -0.8),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            text: 'Enviamos um código para ',
            style: TextStyle(
                color: EagleTokens.darkInkMute,
                fontSize: 14,
                fontWeight: FontWeight.w400),
            children: [
              TextSpan(
                  text: _emailCtrl.text.trim(),
                  style: const TextStyle(
                      color: EagleTokens.brandAccent,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // Token field (special)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CÓDIGO DE VERIFICAÇÃO',
                style: TextStyle(
                    color: EagleTokens.darkInk.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tokenCtrl,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(
                  color: EagleTokens.darkInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 6),
              textAlign: TextAlign.center,
              cursorColor: EagleTokens.brand,
              decoration: InputDecoration(
                hintText: '• • • • • •',
                hintStyle: TextStyle(
                    color: EagleTokens.darkInk.withValues(alpha: 0.15),
                    letterSpacing: 6),
                filled: true,
                fillColor: EagleTokens.darkInk.withValues(alpha: 0.05),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: EagleTokens.darkInk.withValues(alpha: 0.08))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: EagleTokens.darkInk.withValues(alpha: 0.08))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: EagleTokens.brand, width: 1.0)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _PremiumTextField(
          controller: _senhaCtrl,
          label: 'NOVA SENHA',
          hint: 'Mínimo 6 caracteres',
          icon: Icons.lock_outline_rounded,
          obscureText: !_senhaVisivel,
          suffixIcon: IconButton(
            icon: Icon(
                _senhaVisivel
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: EagleTokens.darkInk.withValues(alpha: 0.35),
                size: 20),
            onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
          ),
        ),
        const SizedBox(height: 16),

        _PremiumTextField(
            controller: _confirmarCtrl,
            label: 'CONFIRMAR SENHA',
            hint: 'Repita a nova senha',
            icon: Icons.lock_outline_rounded,
            obscureText: true),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _redefinirSenha,
            style: ElevatedButton.styleFrom(
              backgroundColor: EagleTokens.brand,
              foregroundColor: EagleTokens.darkInk,
              disabledBackgroundColor: EagleTokens.brand.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Redefinir senha',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3)),
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: () => _animateStepForward(0),
            style: TextButton.styleFrom(
                foregroundColor: EagleTokens.brandAccent),
            child: const Text('Solicitar novo código',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        // Success animation
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: EagleTokens.goodSoft.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, color: EagleTokens.good, size: 44),
        ),
        const SizedBox(height: 28),

        Text(
          'Senha redefinida!',
          style: TextStyle(
              color: EagleTokens.darkInk,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Sua senha foi atualizada com sucesso.\nUse-a para fazer login.',
          style: TextStyle(
              color: EagleTokens.darkInkMute,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w400),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EagleTokens.brand,
              foregroundColor: EagleTokens.darkInk,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Ir para o Login',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3)),
          ),
        ),
      ],
    );
  }

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
        _roleTab('Personal', Icons.sports_gymnastics_rounded, 'PERSONAL'),
        _roleTab('Aluno', Icons.person_rounded, 'ALUNO'),
      ]),
    );
  }

  Widget _roleTab(String label, IconData icon, String value) {
    final sel = _tipo == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipo = value),
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
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED PREMIUM COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
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
          obscureText: obscureText,
          keyboardType: keyboardType,
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
