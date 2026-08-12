part of 'perfil_screen.dart';

class _CompletenessCard extends StatelessWidget {
  final int score;
  final Color accent;
  final bool isDark;
  final List<PerfilChecklistItem> items;
  final PerfilNextStep? nextStep;
  final void Function(PerfilChecklistAction action) onChecklistAction;

  const _CompletenessCard({
    required this.score,
    required this.accent,
    required this.isDark,
    required this.items,
    required this.nextStep,
    required this.onChecklistAction,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final complete = score >= 100;

    return Semantics(
      container: true,
      label:
          complete
              ? 'Perfil pronto. $score por cento de prontidão comercial.'
              : 'Prontidão comercial. $score por cento.',
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          TokensStrip.s4,
          TokensStrip.s3,
          TokensStrip.s4,
          TokensStrip.s3,
        ),
        decoration: chrome.panel(radius: 16, accent: accent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    complete ? 'Perfil pronto' : 'Prontidão comercial',
                    style: TokensStrip.body(color: ink).copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (complete)
                  _ReadyStamp(accent: accent)
                else
                  Text(
                    '$score%',
                    style: TokensStrip.h2(color: accent).copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              perfilReadinessGapCopy(
                items.where((item) => !item.done).length,
              ),
              style: TokensStrip.bodyMuted(color: mute).copyWith(height: 1.3),
            ),
            const SizedBox(height: TokensStrip.s2),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: score / 100),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color:
                              isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : TokensStrip.borderDefault,
                        ),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value,
                          child: ColoredBox(color: accent),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (complete) ...[
              const SizedBox(height: TokensStrip.s2),
              _ReadyFocusStrip(accent: accent, isDark: isDark),
            ] else ...[
              const SizedBox(height: TokensStrip.s2),
              // Só lacunas — evita nuvem de chips concluídos.
              Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children:
                    items
                        .where((item) => !item.done)
                        .map(
                          (item) => _ChecklistChip(
                            item: item,
                            accent: accent,
                            onTap: () => onChecklistAction(item.action),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: TokensStrip.s2),
              FxLiquidPrimaryButton(
                icon: Icons.arrow_forward_rounded,
                label: nextStep?.buttonLabel ?? 'Completar perfil',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  if (nextStep != null) {
                    onChecklistAction(nextStep!.action);
                    return;
                  }
                  onChecklistAction(PerfilChecklistAction.convites);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadyStamp extends StatelessWidget {
  final Color accent;

  const _ReadyStamp({required this.accent});

  @override
  Widget build(BuildContext context) {
    final stamp = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(TokensStrip.rPill),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 15, color: accent),
          const SizedBox(width: 5),
          Text(
            'PRONTO',
            style: TokensStrip.bodyMuted(color: accent).copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              fontSize: TokensStrip.fontBodySm - 2,
            ),
          ),
        ],
      ),
    );

    if (TokensStrip.prefersReducedMotion(context)) return stamp;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.88, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        return Transform.scale(
          scale: t,
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
      child: stamp,
    );
  }
}

class _ReadyFocusStrip extends StatelessWidget {
  final Color accent;
  final bool isDark;

  const _ReadyFocusStrip({required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : TokensStrip.borderDefault,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_outlined, color: accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tudo pronto — compartilhe a vitrine ou abra o Copiloto IA.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TokensStrip.bodyMuted(color: mute).copyWith(
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistChip extends StatelessWidget {
  final PerfilChecklistItem item;
  final Color accent;
  final VoidCallback? onTap;

  const _ChecklistChip({required this.item, required this.accent, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        item.done
            ? accent
            : (isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary);
    final statusLabel =
        item.done
            ? '${item.label}, concluído'
            : '${item.label}, pendente. Toque para completar';
    return Semantics(
      button: onTap != null,
      label: statusLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rPill),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color:
                  item.done
                      ? accent.withValues(alpha: isDark ? 0.16 : 0.09)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : TokensStrip.borderDefault),
              borderRadius: BorderRadius.circular(TokensStrip.rPill),
              border:
                  onTap != null
                      ? Border.all(color: accent.withValues(alpha: 0.22))
                      : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.done ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 5),
                Text(
                  item.label,
                  style: TokensStrip.bodyMuted(color: color).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfessionalDataPanel extends StatelessWidget {
  final PerfilProfessionalSummary summary;
  final Color accent;
  final Color actionInk;
  final Color mute;
  final bool isDark;
  final VoidCallback onEdit;

  const _ProfessionalDataPanel({
    required this.summary,
    required this.accent,
    required this.actionInk,
    required this.mute,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return PerfilCardSection(
      title: 'Dados profissionais',
      subtitle: 'Resumo do cadastro — detalhes na edição.',
      isDark: isDark,
      accent: accent,
      actionInk: actionInk,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'Dados profissionais. ${summary.lines.join('. ')}',
            child: Wrap(
              spacing: TokensStrip.s2,
              runSpacing: TokensStrip.s2,
              children: [
                for (final line in summary.lines)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : TokensStrip.borderDefault.withValues(
                                alpha: 0.65,
                              ),
                      borderRadius: BorderRadius.circular(TokensStrip.rPill),
                      border:
                          line.toLowerCase().contains('pendente')
                              ? Border.all(
                                color: accent.withValues(alpha: 0.35),
                              )
                              : null,
                    ),
                    child: Text(
                      line,
                      style: TokensStrip.bodyMuted(
                        color:
                            line.toLowerCase().contains('pendente')
                                ? actionInk
                                : ink,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ),
          if (summary.missingPhone) ...[
            const SizedBox(height: TokensStrip.s2),
            Text(
              'WhatsApp é o canal que o aluno usa para te achar.',
              style: TokensStrip.bodyMuted(color: mute).copyWith(height: 1.35),
            ),
          ],
          const SizedBox(height: TokensStrip.s3),
          if (summary.missingPhone)
            FxLiquidPrimaryButton(
              icon: Icons.edit_outlined,
              label: summary.ctaLabel,
              onPressed: () {
                HapticFeedback.selectionClick();
                onEdit();
              },
            )
          else
            FxLiquidSecondaryButton(
              icon: Icons.edit_outlined,
              label: summary.ctaLabel,
              onPressed: () {
                HapticFeedback.selectionClick();
                onEdit();
              },
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color mute;
  final Color line;
  final bool showDivider;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.mute,
    required this.line,
    this.showDivider = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        border:
            showDivider
                ? Border(bottom: BorderSide(color: line, width: 0.5))
                : null,
      ),
      child: Row(
        children: [
          _LeadingIcon(
            icon: icon,
            background:
                isDark
                    ? accent.withValues(alpha: 0.14)
                    : BrandPalette.soft(accent),
            color: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TokensStrip.bodyMuted(color: mute).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TokensStrip.body(color: ink).copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: TokensStrip.fontBodySm + 1,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) Icon(Icons.chevron_right, size: 18, color: mute),
        ],
      ),
    );

    if (onTap == null) {
      return Semantics(label: '$label. $value', child: content);
    }

    return Semantics(
      button: true,
      label: '$label. $value',
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

class _ProfileTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.032)
          ..strokeWidth = 0.5;
    const step = 34.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _showDeleteAccountDialog(
  BuildContext context, {
  required Future<void> Function() onSessionCleared,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      var loading = false;
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Excluir conta'),
            content: const Text(
              'Esta ação é irreversível. Todos os seus dados pessoais serão anonimizados '
              'conforme a LGPD (Art. 18). Dados financeiros serão mantidos por 5 anos '
              'conforme legislação fiscal.\n\n'
              'Deseja realmente excluir sua conta?',
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: EagleTokens.bad),
                onPressed:
                    loading
                        ? null
                        : () async {
                          setDialogState(() => loading = true);
                          try {
                            final dio = ApiClient().dio;
                            await dio.delete('/api/lgpd/me/delete');
                            if (!ctx.mounted) return;
                            Navigator.of(ctx).pop();
                            if (!context.mounted) return;
                            FeedbackHelper.showSuccess(
                              context,
                              'Conta excluída com sucesso.',
                            );
                            await onSessionCleared();
                          } catch (e) {
                            if (!ctx.mounted) return;
                            setDialogState(() => loading = false);
                            if (!context.mounted) return;
                            FeedbackHelper.showError(
                              context,
                              friendlyError(e),
                            );
                          }
                        },
                child: Text(loading ? 'Excluindo…' : 'Excluir definitivamente'),
              ),
            ],
          );
        },
      );
    },
  );
}

String _buildSubtitle(PerfilPersonal perfil) {
  final specialty = perfil.especialidade ?? 'Personal Trainer';
  final ig = perfil.instagram?.trim();
  if (ig != null && ig.isNotEmpty) {
    return '$specialty  |  @${ig.replaceFirst('@', '')}';
  }
  return specialty;
}

String _formatInstagram(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Não informado';
  }
  final normalized = value.trim();
  return normalized.startsWith('@') ? normalized : '@$normalized';
}

String _initials(String nome) {
  final parts = nome
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty);
  if (parts.isEmpty) return 'FP';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

Color _parseColor(String? value, {required Color fallback}) {
  if (value == null || value.trim().isEmpty) {
    return fallback;
  }

  final sanitized = value.trim().replaceFirst('#', '');
  if (sanitized.length != 6 && sanitized.length != 8) {
    return fallback;
  }

  final normalized = sanitized.length == 6 ? 'FF$sanitized' : sanitized;
  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null) {
    return fallback;
  }

  return Color(parsed);
}

bool _usesDefaultPalette(Color primary, Color secondary) {
  int channel(double v) => (v * 255).round();
  bool close(Color a, Color b) =>
      (channel(a.r) - channel(b.r)).abs() <= 8 &&
      (channel(a.g) - channel(b.g)).abs() <= 8 &&
      (channel(a.b) - channel(b.b)).abs() <= 8;

  return close(primary, BrandPalette.defaultPrimary) &&
      close(secondary, BrandPalette.defaultSecondary);
}
