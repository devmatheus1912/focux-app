import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/design_tokens.dart';

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

  late final AnimationController _bgCtrl;
  late final AnimationController _stepCtrl;
  late final Animation<double> _stepSlide;
  late final Animation<double> _stepFade;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _stepCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _stepSlide = Tween<double>(begin: 30, end: 0).animate(CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOutCubic));
    _stepFade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _stepCtrl, curve: const Interval(0.15, 1.0, curve: Curves.easeOut)));
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _stepCtrl.forward();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmarCtrl.dispose();
    _bgCtrl.dispose();
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
    try {
      final dio = ApiClient().dio;
      await dio.post('/api/auth/esqueci-senha', data: {'email': email, 'tipo': _tipo});
      _animateStepForward(1);
    } catch (e) {
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('As senhas não coincidem')));
      return;
    }
    if (nova.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha deve ter pelo menos 6 caracteres')));
      return;
    }
    setState(() => _loading = true);
    try {
      final dio = ApiClient().dio;
      await dio.post('/api/auth/resetar-senha', data: {'token': token, 'novaSenha': nova});
      _animateStepForward(2);
    } catch (e) {
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            AnimatedBuilder(
              animation: _bgCtrl,
              builder: (context, _) {
                final t = _bgCtrl.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 + sin(t * 2 * pi) * 0.3, -1.0 + cos(t * 2 * pi) * 0.3),
                      end: Alignment(1.0 + cos(t * 2 * pi) * 0.3, 1.0 + sin(t * 2 * pi) * 0.3),
                      colors: const [Color(0xFF0A0F1E), Color(0xFF0D1B5C), Color(0xFF1C3273), Color(0xFF0D1B5C), Color(0xFF0A0F1E)],
                    ),
                  ),
                );
              },
            ),

            CustomPaint(painter: _AuthGridPainter(), size: Size.infinite),

            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(left: 28, right: 28, top: mq.size.height * 0.04, bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: () {
                        if (_step == 1) {
                          _animateStepForward(0);
                        } else {
                          context.pop();
                        }
                      },
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

                    const SizedBox(height: 24),

                    // Step indicator
                    if (_step < 2)
                      Row(
                        children: List.generate(2, (i) => Expanded(
                          child: Container(
                            height: 3,
                            margin: EdgeInsets.only(right: i < 1 ? 6 : 0),
                            decoration: BoxDecoration(
                              color: i <= _step ? EagleTokens.brand : Colors.white.withValues(alpha: 0.08),
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
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: EagleTokens.brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.shield_outlined, color: EagleTokens.brandAccent, size: 28),
        ),
        const SizedBox(height: 20),

        const Text(
          'Recuperar\nacesso.',
          style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w600, height: 1.15, letterSpacing: -1),
        ),
        const SizedBox(height: 10),
        Text(
          'Informe seu e-mail e enviaremos um código de verificação.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 36),

        // Account type toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              _RoleTab(label: 'Personal', isSelected: _tipo == 'PERSONAL', onTap: () => setState(() => _tipo = 'PERSONAL')),
              _RoleTab(label: 'Aluno', isSelected: _tipo == 'ALUNO', onTap: () => setState(() => _tipo = 'ALUNO')),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _FxTextField(controller: _emailCtrl, label: 'E-mail cadastrado', hint: 'seu@email.com', icon: Icons.alternate_email, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _loading ? null : _solicitarToken,
            style: ElevatedButton.styleFrom(
              backgroundColor: EagleTokens.brand,
              foregroundColor: Colors.white,
              disabledBackgroundColor: EagleTokens.brand.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Enviar código', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: () => _animateStepForward(1),
            style: TextButton.styleFrom(foregroundColor: EagleTokens.brandAccent),
            child: const Text('Já tenho um código', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: EagleTokens.brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.vpn_key_outlined, color: EagleTokens.brandAccent, size: 28),
        ),
        const SizedBox(height: 20),

        const Text(
          'Nova\nsenha.',
          style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w600, height: 1.15, letterSpacing: -1),
        ),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            text: 'Enviamos um código para ',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15),
            children: [
              TextSpan(text: _emailCtrl.text.trim(), style: const TextStyle(color: EagleTokens.brandAccent, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 36),

        // Token field (special)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CÓDIGO DE VERIFICAÇÃO', style: TextStyle(color: EagleTokens.brandAccent.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _tokenCtrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 6),
              textAlign: TextAlign.center,
              cursorColor: EagleTokens.brand,
              decoration: InputDecoration(
                hintText: '• • • • • •',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15), letterSpacing: 6),
                filled: true,
                fillColor: EagleTokens.brand.withValues(alpha: 0.08),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: EagleTokens.brand.withValues(alpha: 0.25))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: EagleTokens.brand.withValues(alpha: 0.25))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: EagleTokens.brand, width: 1.5)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _FxTextField(
          controller: _senhaCtrl,
          label: 'Nova senha',
          hint: 'Mínimo 6 caracteres',
          icon: Icons.lock_outline,
          obscureText: !_senhaVisivel,
          suffixIcon: IconButton(
            icon: Icon(_senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white.withValues(alpha: 0.4), size: 20),
            onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
          ),
        ),
        const SizedBox(height: 18),

        _FxTextField(controller: _confirmarCtrl, label: 'Confirmar senha', hint: 'Repita a nova senha', icon: Icons.lock_outline, obscureText: true),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _loading ? null : _redefinirSenha,
            style: ElevatedButton.styleFrom(
              backgroundColor: EagleTokens.brand,
              foregroundColor: Colors.white,
              disabledBackgroundColor: EagleTokens.brand.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Redefinir senha', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: () => _animateStepForward(0),
            style: TextButton.styleFrom(foregroundColor: EagleTokens.brandAccent),
            child: const Text('Solicitar novo código', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
          width: 88, height: 88,
          decoration: BoxDecoration(
            color: const Color(0xFF6FE296).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Color(0xFF6FE296), size: 44),
        ),
        const SizedBox(height: 28),

        const Text(
          'Senha redefinida!',
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Sua senha foi atualizada com sucesso.\nUse-a para fazer login.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 15, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EagleTokens.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Ir para o Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────────

class _RoleTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _RoleTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? EagleTokens.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected ? [BoxShadow(color: EagleTokens.brand.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))] : [],
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4), fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 14)),
          ),
        ),
      ),
    );
  }
}

class _FxTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _FxTextField({required this.controller, required this.label, required this.hint, required this.icon, this.obscureText = false, this.keyboardType, this.suffixIcon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
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
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.025)..strokeWidth = 0.5..style = PaintingStyle.stroke;
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
