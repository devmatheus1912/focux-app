import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_premium_entrance.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/convite_repository.dart';
import '../providers/convite_provider.dart';

class ConvitesScreen extends ConsumerStatefulWidget {
  const ConvitesScreen({super.key});

  @override
  ConsumerState<ConvitesScreen> createState() => _ConvitesScreenState();
}

class _ConvitesScreenState extends ConsumerState<ConvitesScreen> {
  Convite? _convite;
  bool _loading = false;
  String? _error;
  Timer? _countdownTimer;
  Duration? _remaining;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime expiresAt) {
    _countdownTimer?.cancel();
    void tick() {
      if (!mounted) return;
      final left = expiresAt.difference(DateTime.now());
      setState(() => _remaining = left.isNegative ? Duration.zero : left);
      if (left.isNegative) _countdownTimer?.cancel();
    }

    tick();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> _gerar() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _loading = true;
      _error = null;
      _convite = null;
      _remaining = null;
    });
    try {
      final convite = await ref.read(conviteRepositoryProvider).gerar();
      if (!mounted) return;
      setState(() => _convite = convite);
      if (convite.expiraEm != null) {
        _startCountdown(convite.expiraEm!);
      }
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Erro ao gerar convite. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _shareLink => _convite?.shareLink ?? '';

  void _copiar() {
    if (_shareLink.isEmpty) return;
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: _shareLink));
    FeedbackHelper.showSnackBar(
      context,
      const SnackBar(content: Text('Link copiado!')),
    );
  }

  Future<void> _compartilharWhatsApp() async {
    if (_shareLink.isEmpty) return;
    HapticFeedback.selectionClick();
    final texto =
        'Olá! Use este link para criar sua conta no app do seu personal: $_shareLink';
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(texto)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatRemaining(Duration? remaining) {
    if (remaining == null) return '24h';
    if (remaining <= Duration.zero) return 'Expirado';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}min';
    return '${minutes}min';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final chrome = ShellChrome.forDark(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: FxShellAppBar(
        title: 'Convidar aluno',
        onBack: () => safePopOrGo(context, '/dashboard/personal'),
      ),
      body: FxPremiumEntrance(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroCard(isDark: isDark, primary: primary, ink: ink, mute: mute),
              const SizedBox(height: 20),
              FxGlowSurface(
                color: primary,
                enabled: !_loading && _convite == null,
                borderRadius: 16,
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon:
                        _loading
                            ? const SizedBox.shrink()
                            : const Icon(Icons.link_rounded),
                    label:
                        _loading
                            ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: FxLoading(strokeWidth: 2, color: Colors.white),
                            )
                            : const Text('Gerar novo link'),
                    onPressed: _loading ? null : _gerar,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: EagleTokens.bad)),
              ],
              if (_convite != null) ...[
                const SizedBox(height: 20),
                FxGlowSurface(
                  color: primary,
                  enabled: true,
                  intensity: 0.85,
                  borderRadius: 22,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: fxListCardDecoration(
                      context,
                      accent: primary,
                    ).copyWith(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.verified_outlined,
                                color: primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Link gerado',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: ink,
                                    ),
                                  ),
                                  Text(
                                    'Expira em ${_formatRemaining(_remaining)}',
                                    style: TextStyle(
                                      color: mute,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: chrome.cardFill,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: chrome.line),
                          ),
                          child: SelectableText(
                            _shareLink,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12.5,
                              height: 1.45,
                              color: ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _copiar,
                                icon: const Icon(Icons.copy_rounded, size: 18),
                                label: const Text('Copiar'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _compartilharWhatsApp,
                                icon: const Icon(Icons.chat_rounded, size: 18),
                                label: const Text('WhatsApp'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 320.ms, curve: Curves.easeOutCubic)
                    .slideY(begin: 0.06, curve: Curves.easeOutCubic),
                const SizedBox(height: 12),
                Text(
                  'Compartilhe este link com o aluno. Ele expira em 24h e pode ser usado uma única vez.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: mute,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.isDark,
    required this.primary,
    required this.ink,
    required this.mute,
  });

  final bool isDark;
  final Color primary;
  final Color ink;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: isDark ? 0.22 : 0.12),
            (isDark ? EagleTokens.darkCard : EagleTokens.card)
                .withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.person_add_alt_1_rounded, color: primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Convite único',
                  style: GoogleFonts.outfit(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gere um link seguro para seu aluno criar a conta no app.',
                  style: TextStyle(color: mute, height: 1.35, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
