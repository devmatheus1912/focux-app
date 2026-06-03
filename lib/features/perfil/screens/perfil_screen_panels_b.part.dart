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
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: chrome.panel(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete ? 'Perfil pronto' : 'Prontidão comercial',
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complete
                          ? 'Seu perfil comercial está pronto para operar.'
                          : 'Faltam ${items.where((item) => !item.done).length} passos para parecer premium.',
                      style: TextStyle(color: mute, fontSize: 12, height: 1.35),
                    ),
                  ],
                ),
              ),
              if (complete)
                _ReadyStamp(accent: accent)
              else
                Text(
                  '$score%',
                  style: TextStyle(
                    color: accent,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 9,
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
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accent.withValues(alpha: 0.72), accent],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          if (complete)
            _ReadyFocusStrip(accent: accent, isDark: isDark)
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children:
                  items
                      .map(
                        (item) => _ChecklistChip(
                          item: item,
                          accent: accent,
                          onTap:
                              item.done
                                  ? null
                                  : () => onChecklistAction(item.action),
                        ),
                      )
                      .toList(),
            ),
          if (!complete) ...[
            const SizedBox(height: 10),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 15, color: accent),
          const SizedBox(width: 5),
          Text(
            'PRONTO',
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
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
              'Operação pronta — use o Copiloto IA, convide alunos e acompanhe pelo dashboard.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: mute,
                fontSize: 11.8,
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

  const _ChecklistChip({
    required this.item,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        item.done
            ? accent
            : (isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color:
                item.done
                    ? accent.withValues(alpha: isDark ? 0.16 : 0.09)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : TokensStrip.borderDefault),
            borderRadius: BorderRadius.circular(999),
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
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfessionalDataPanel extends StatelessWidget {
  final PerfilPersonal perfil;
  final DashboardData dashboard;
  final String bioText;
  final Color accent;
  final Color actionInk;
  final Color mute;
  final Color line;
  final bool isDark;
  final VoidCallback onEdit;

  const _ProfessionalDataPanel({
    required this.perfil,
    required this.dashboard,
    required this.bioText,
    required this.accent,
    required this.actionInk,
    required this.mute,
    required this.line,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return _CardSection(
      title: 'Dados profissionais',
      subtitle: 'Contrato, canais públicos e prova de autoridade.',
      trailingLabel: 'Editar',
      onTrailingTap: onEdit,
      isDark: isDark,
      accent: accent,
      actionInk: actionInk,
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: perfil.email,
            accent: accent,
            mute: mute,
            line: line,
          ),
          _InfoTile(
            icon: Icons.badge_outlined,
            label: 'CREF',
            value: perfil.cref ?? 'Não informado',
            accent: accent,
            mute: mute,
            line: line,
            onTap: onEdit,
          ),
          _InfoTile(
            icon: Icons.trending_up_outlined,
            label: 'Especialidade',
            value:
                perfil.especialidades ??
                perfil.especialidade ??
                'Não informada',
            accent: accent,
            mute: mute,
            line: line,
            onTap: onEdit,
          ),
          _InfoTile(
            icon: Icons.alternate_email,
            label: 'Instagram',
            value: _formatInstagram(perfil.instagram ?? dashboard.instagram),
            accent: accent,
            mute: mute,
            line: line,
            onTap: onEdit,
            showDivider: bioText.isNotEmpty,
          ),
          if (bioText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LeadingIcon(
                        icon: Icons.notes_outlined,
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
                              'Bio profissional',
                              style: TextStyle(
                                color: mute,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              bioText,
                              style: TextStyle(
                                color: ink,
                                fontSize: 13.5,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 18, color: mute),
                    ],
                  ),
                ),
              ),
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
                  style: TextStyle(
                    color: mute,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color? actionInk;
  final Color mute;
  final Color line;
  final bool danger;
  final bool showDivider;
  final bool locked;
  final String? upgradeTierLabel;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.actionInk,
    required this.mute,
    required this.line,
    required this.onTap,
    this.danger = false,
    this.showDivider = true,
    this.locked = false,
    this.upgradeTierLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink =
        danger
            ? (isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad)
            : (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary);
    final inkMuted = locked ? ink.withValues(alpha: 0.55) : ink;

    final link = actionInk ?? accent;
    final a11y =
        danger
            ? label
            : locked
            ? '$label trancado. Plano ${upgradeTierLabel ?? 'upgrade'}'
            : (value.isEmpty ? label : '$label. $value');

    return Semantics(
      button: true,
      label: a11y,
      child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border:
              showDivider
                  ? Border(bottom: BorderSide(color: line, width: 0.5))
                  : null,
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _LeadingIcon(
                  icon: icon,
                  background:
                      danger
                          ? (isDark ? const Color(0x24FF8B8B) : EagleTokens.badSoft)
                          : (isDark
                              ? accent.withValues(alpha: locked ? 0.08 : 0.14)
                              : BrandPalette.soft(accent).withValues(
                                alpha: locked ? 0.55 : 1,
                              )),
                  color:
                      danger
                          ? ink
                          : accent.withValues(alpha: locked ? 0.55 : 1),
                ),
                if (locked)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A2228) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: line),
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 10,
                        color: mute,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: inkMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value.isNotEmpty)
              Flexible(
                flex: 5,
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color:
                        danger
                            ? ink
                            : (locked ? mute : link),
                    fontSize: 12,
                    fontWeight: danger ? FontWeight.w600 : FontWeight.w800,
                  ),
                ),
              ),
            if (!danger) ...[
              const SizedBox(width: 8),
              Icon(
                locked ? Icons.lock_outline_rounded : Icons.chevron_right,
                size: 18,
                color: locked ? mute : link,
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

class _PerfilGrowthSection extends StatefulWidget {
  const _PerfilGrowthSection({
    required this.accent,
    required this.actionInk,
    required this.mute,
    required this.line,
    required this.isDark,
    required this.child,
  });

  final Color accent;
  final Color actionInk;
  final Color mute;
  final Color line;
  final bool isDark;
  final Widget child;

  @override
  State<_PerfilGrowthSection> createState() => _PerfilGrowthSectionState();
}

class _PerfilGrowthSectionState extends State<_PerfilGrowthSection> {
  bool _expanded = false;

  static const _collapsedHint =
      'Automações, desafios, loja, equipe e hábitos';
  static const _collapsedValue = '5 ferramentas';

  @override
  Widget build(BuildContext context) {
    final ink =
        widget.isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final link = widget.actionInk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          label:
              _expanded
                  ? 'Recolher Crescimento'
                  : 'Expandir Crescimento. $_collapsedHint',
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: widget.line, width: 0.5)),
              ),
              child: Row(
                children: [
                  _LeadingIcon(
                    icon: Icons.trending_up_rounded,
                    background:
                        widget.isDark
                            ? widget.accent.withValues(alpha: 0.14)
                            : BrandPalette.soft(widget.accent),
                    color: widget.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Text(
                      'Crescimento',
                      style: TextStyle(
                        color: ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (!_expanded)
                    Text(
                      _collapsedValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: link,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: link,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: widget.child,
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color color;

  const _LeadingIcon({
    required this.icon,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 16, color: color),
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

void _showDeleteAccountDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Excluir conta'),
          content: const Text(
            'Esta ação é irreversível. Todos os seus dados pessoais serão anonimizados '
            'conforme a LGPD (Art. 18). Dados financeiros serão mantidos por 5 anos '
            'conforme legislação fiscal.\n\n'
            'Deseja realmente excluir sua conta?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: EagleTokens.bad),
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  final dio = ApiClient().dio;
                  await dio.delete('/api/lgpd/me/delete');
                  if (!context.mounted) return;
                  FeedbackHelper.showSnackBar(
                    context,
                    const SnackBar(
                      content: Text('Conta excluída com sucesso.'),
                    ),
                  );
                  GoRouter.of(context).go('/login');
                } catch (e) {
                  if (!context.mounted) return;
                  FeedbackHelper.showSnackBar(
                    context,
                    SnackBar(content: Text(friendlyError(e))),
                  );
                }
              },
              child: const Text('Excluir definitivamente'),
            ),
          ],
        ),
  );
}

bool _hasWallet(PerfilPersonal perfil) =>
    _hasText(perfil.chavePix) ||
    (_hasText(perfil.banco) &&
        _hasText(perfil.agencia) &&
        _hasText(perfil.conta));

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

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
