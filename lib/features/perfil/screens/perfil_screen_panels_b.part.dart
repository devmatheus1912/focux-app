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
        decoration: fxStripCardDecoration(context, accent: accent, emphasize: !complete),
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
              tween: Tween<double>(
                begin:
                    TokensStrip.prefersReducedMotion(context) ? score / 100 : 0,
                end: score / 100,
              ),
              duration:
                  TokensStrip.prefersReducedMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 700),
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
              'Tudo pronto — compartilhe a vitrine ou abra Meus alunos.',
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
  final bool profileComplete;
  final VoidCallback onEdit;

  const _ProfessionalDataPanel({
    required this.summary,
    required this.accent,
    required this.actionInk,
    required this.mute,
    required this.isDark,
    required this.profileComplete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (profileComplete) {
      return _ProfessionalDataCompleteStrip(
        accent: accent,
        actionInk: actionInk,
        isDark: isDark,
        onEdit: onEdit,
      );
    }

    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return PerfilCardSection(
      title: 'Dados profissionais',
      subtitle: 'Resumo do cadastro — detalhes na edição.',
      isDark: isDark,
      accent: accent,
      actionInk: actionInk,
      quiet: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'Dados profissionais. ${summary.lines.join('. ')}',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dual = constraints.maxWidth >= 320;
                final entries = <(IconData, String)>[
                  (
                    Icons.phone_outlined,
                    summary.lines.isNotEmpty ? summary.lines[0] : '—',
                  ),
                  (
                    Icons.badge_outlined,
                    summary.lines.length > 1 ? summary.lines[1] : '—',
                  ),
                  (
                    Icons.fitness_center_outlined,
                    summary.lines.length > 2 ? summary.lines[2] : '—',
                  ),
                  (
                    Icons.alternate_email_rounded,
                    summary.lines.length > 3 ? summary.lines[3] : '—',
                  ),
                ];
                if (!dual) {
                  return Column(
                    children: [
                      for (var i = 0; i < entries.length; i++) ...[
                        if (i > 0) const SizedBox(height: TokensStrip.s2),
                        _ProfessionalFactRow(
                          icon: entries[i].$1,
                          text: entries[i].$2,
                          accent: accent,
                          actionInk: actionInk,
                          ink: ink,
                          isDark: isDark,
                        ),
                      ],
                    ],
                  );
                }
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ProfessionalFactRow(
                            icon: entries[0].$1,
                            text: entries[0].$2,
                            accent: accent,
                            actionInk: actionInk,
                            ink: ink,
                            isDark: isDark,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: TokensStrip.s2),
                        Expanded(
                          child: _ProfessionalFactRow(
                            icon: entries[1].$1,
                            text: entries[1].$2,
                            accent: accent,
                            actionInk: actionInk,
                            ink: ink,
                            isDark: isDark,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TokensStrip.s2),
                    Row(
                      children: [
                        Expanded(
                          child: _ProfessionalFactRow(
                            icon: entries[2].$1,
                            text: entries[2].$2,
                            accent: accent,
                            actionInk: actionInk,
                            ink: ink,
                            isDark: isDark,
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: TokensStrip.s2),
                        Expanded(
                          child: _ProfessionalFactRow(
                            icon: entries[3].$1,
                            text: entries[3].$2,
                            accent: accent,
                            actionInk: actionInk,
                            ink: ink,
                            isDark: isDark,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
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

class _ProfessionalDataCompleteStrip extends StatelessWidget {
  const _ProfessionalDataCompleteStrip({
    required this.accent,
    required this.actionInk,
    required this.isDark,
    required this.onEdit,
  });

  final Color accent;
  final Color actionInk;
  final bool isDark;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;

    return Semantics(
      button: true,
      label: 'Cadastro completo. Editar dados profissionais',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onEdit();
          },
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          child: Ink(
            decoration: fxStripCardDecoration(
              context,
              accent: accent,
              radius: TokensStrip.rCard,
              glowStrength: 0.03,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 18, color: accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cadastro completo',
                      style: FocuxHubTypography.sectionTitle(
                        context,
                        color: ink,
                      ).copyWith(fontSize: TokensStrip.fontBody),
                    ),
                  ),
                  Text(
                    'Editar',
                    style: FocuxHubTypography.chip(actionInk),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 20, color: mute),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfessionalFactRow extends StatelessWidget {
  const _ProfessionalFactRow({
    required this.icon,
    required this.text,
    required this.accent,
    required this.actionInk,
    required this.ink,
    required this.isDark,
    this.maxLines = 1,
  });

  final IconData icon;
  final String text;
  final Color accent;
  final Color actionInk;
  final Color ink;
  final bool isDark;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final pending = text.toLowerCase().contains('pendente');
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.045)
                : TokensStrip.borderDefault.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border:
            pending
                ? Border.all(color: accent.withValues(alpha: 0.30))
                : Border.all(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : TokensStrip.borderDefault,
                ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: pending ? actionInk : accent.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TokensStrip.bodyMuted(
                color: pending ? actionInk : ink,
              ).copyWith(fontWeight: FontWeight.w700, height: 1.15),
            ),
          ),
        ],
      ),
    );
  }
}

void _showDeleteAccountDialog(
  BuildContext context, {
  required Future<void> Function() onSessionCleared,
}) {
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      var loading = false;
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Excluir conta'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Esta ação é irreversível. Todos os seus dados pessoais serão anonimizados '
                  'conforme a LGPD (Art. 18). Dados financeiros serão mantidos por 5 anos '
                  'conforme legislação fiscal.\n\n'
                  'Digite sua senha e EXCLUIR para confirmar.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha atual',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Digite EXCLUIR',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading
                    ? null
                    : () {
                      passwordCtrl.dispose();
                      confirmCtrl.dispose();
                      Navigator.of(ctx).pop();
                    },
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
                            await dio.delete(
                              '/api/lgpd/me/delete',
                              data: {
                                'senha': passwordCtrl.text,
                                'confirmacao': confirmCtrl.text.trim(),
                              },
                            );
                            if (!ctx.mounted) return;
                            passwordCtrl.dispose();
                            confirmCtrl.dispose();
                            Navigator.of(ctx).pop();
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
