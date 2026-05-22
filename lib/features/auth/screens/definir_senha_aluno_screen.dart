import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/auth_provider.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';

class DefinirSenhaAlunoScreen extends ConsumerStatefulWidget {
  const DefinirSenhaAlunoScreen({super.key});

  @override
  ConsumerState<DefinirSenhaAlunoScreen> createState() =>
      _DefinirSenhaAlunoScreenState();
}

class _DefinirSenhaAlunoScreenState
    extends ConsumerState<DefinirSenhaAlunoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _senhaAtualCtrl = TextEditingController();
  final _novaSenhaCtrl = TextEditingController();
  final _confirmacaoCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _showSenhaAtual = false;
  bool _showNovaSenha = false;
  bool _showConfirmacao = false;

  late final AnimationController _iconAnim;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _iconScale = CurvedAnimation(parent: _iconAnim, curve: Curves.elasticOut);
    _novaSenhaCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _iconAnim.dispose();
    _senhaAtualCtrl.dispose();
    _novaSenhaCtrl.dispose();
    _confirmacaoCtrl.dispose();
    super.dispose();
  }

  double _passwordStrength() {
    final pwd = _novaSenhaCtrl.text;
    if (pwd.isEmpty) return 0;
    double score = 0;
    if (pwd.length >= 6) score += 0.25;
    if (pwd.length >= 8) score += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(pwd)) score += 0.2;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pwd)) score += 0.2;
    return score.clamp(0, 1);
  }

  Color _strengthColor() {
    final s = _passwordStrength();
    if (s <= 0.25) return EagleTokens.bad;
    if (s <= 0.5) return Colors.orange;
    if (s <= 0.75) return Colors.amber;
    return EagleTokens.good;
  }

  String _strengthLabel() {
    final s = _passwordStrength();
    if (s <= 0) return '';
    if (s <= 0.25) return 'Fraca';
    if (s <= 0.5) return 'Razoável';
    if (s <= 0.75) return 'Boa';
    return 'Forte';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      await ref
          .read(authProvider.notifier)
          .definirSenhaDefinitivaAluno(
            _senhaAtualCtrl.text,
            _novaSenhaCtrl.text,
          );
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      context.go('/aluno/ativacao');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível definir a nova senha. Verifique os dados.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final surface = isDark ? EagleTokens.darkCard : Colors.white;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
    final strength = _passwordStrength();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Hero icon ──
                    Center(
                      child: ScaleTransition(
                        scale: _iconScale,
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [primary, primary.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.3),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Title ──
                    Text(
                      'Crie sua senha',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Por segurança, defina uma senha pessoal\npara proteger sua conta.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: mute, height: 1.5),
                    ),
                    const SizedBox(height: 32),

                    // ── Card ──
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: line),
                        boxShadow:
                            isDark
                                ? null
                                : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Senha provisória
                          TextFormField(
                            controller: _senhaAtualCtrl,
                            obscureText: !_showSenhaAtual,
                            decoration: InputDecoration(
                              labelText: 'Senha provisória',
                              prefixIcon: Icon(
                                Icons.key_rounded,
                                color: mute,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showSenhaAtual
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: mute,
                                  size: 20,
                                ),
                                onPressed:
                                    () => setState(
                                      () => _showSenhaAtual = !_showSenhaAtual,
                                    ),
                              ),
                              border: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              enabledBorder: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: line),
                              ),
                              focusedBorder: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: primary,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : EagleTokens.paper,
                            ),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty
                                        ? 'Informe a senha atual'
                                        : null,
                          ),
                          const SizedBox(height: 16),

                          // Nova senha
                          TextFormField(
                            controller: _novaSenhaCtrl,
                            obscureText: !_showNovaSenha,
                            decoration: InputDecoration(
                              labelText: 'Nova senha',
                              prefixIcon: Icon(
                                Icons.lock_outline_rounded,
                                color: mute,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showNovaSenha
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: mute,
                                  size: 20,
                                ),
                                onPressed:
                                    () => setState(
                                      () => _showNovaSenha = !_showNovaSenha,
                                    ),
                              ),
                              border: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              enabledBorder: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: line),
                              ),
                              focusedBorder: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: primary,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : EagleTokens.paper,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Informe a nova senha';
                              }
                              if (v.length < 6) return 'Mínimo de 6 caracteres';
                              return null;
                            },
                          ),

                          // ── Strength indicator ──
                          if (_novaSenhaCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: strength,
                                      minHeight: 5,
                                      backgroundColor: line,
                                      valueColor: AlwaysStoppedAnimation(
                                        _strengthColor(),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _strengthLabel(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _strengthColor(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Confirmar
                          TextFormField(
                            controller: _confirmacaoCtrl,
                            obscureText: !_showConfirmacao,
                            decoration: InputDecoration(
                              labelText: 'Confirmar nova senha',
                              prefixIcon: Icon(
                                Icons.lock_reset_rounded,
                                color: mute,
                                size: 20,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showConfirmacao
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: mute,
                                  size: 20,
                                ),
                                onPressed:
                                    () => setState(
                                      () =>
                                          _showConfirmacao = !_showConfirmacao,
                                    ),
                              ),
                              border: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              enabledBorder: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: line),
                              ),
                              focusedBorder: FxInputDeco.outlineBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: primary,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : EagleTokens.paper,
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Confirme a nova senha';
                              }
                              if (v != _novaSenhaCtrl.text) {
                                return 'As senhas não conferem';
                              }
                              return null;
                            },
                          ),

                          // ── Error ──
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: EagleTokens.bad.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: EagleTokens.bad.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: EagleTokens.bad,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: EagleTokens.bad,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Submit button ──
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child:
                            _loading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: FxLoading(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shield_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Salvar nova senha',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Tips ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: isDark ? 0.1 : 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Use pelo menos 6 caracteres, combinando letras maiúsculas, números e símbolos para uma senha forte.',
                              style: TextStyle(
                                fontSize: 12,
                                color: mute,
                                height: 1.5,
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
      ),
    );
  }
}
