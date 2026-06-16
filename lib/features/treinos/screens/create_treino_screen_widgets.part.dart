part of 'create_treino_screen.dart';


class _StickyCreateBar extends StatelessWidget {
  final bool canSubmit;
  final bool loading;
  final VoidCallback onSubmit;

  const _StickyCreateBar({
    required this.canSubmit,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark
            ? EagleTokens.darkBg.withValues(alpha: 0.44)
            : Colors.white.withValues(alpha: 0.46);
    final enabled = canSubmit && !loading;

    return SafeArea(
      top: false,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: loading ? 'Criando treino' : 'Criar treino',
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 12),
              decoration: BoxDecoration(
                color: bg,
                border: Border(
                  top: BorderSide(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.58),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.18 : 0.035,
                    ),
                    blurRadius: 22,
                    offset: const Offset(0, -12),
                    spreadRadius: -18,
                  ),
                ],
              ),
              child: Opacity(
                opacity: enabled ? 1 : 0.48,
                child: FxLiquidPrimaryButton(
                  label: 'Criar treino',
                  icon: Icons.add_rounded,
                  onPressed: enabled ? onSubmit : null,
                  loading: loading,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreationHero extends StatelessWidget {
  final String title;
  final String goal;
  final String level;
  final bool isDark;
  final Color primary;

  const _CreationHero({
    required this.title,
    required this.goal,
    required this.level,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final primaryDeep = BrandPalette.deep(primary);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primaryDeep],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.08 : 0.14),
            blurRadius: 22,
            offset: const Offset(0, 12),
            spreadRadius: -20,
          ),
        ],
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
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Criação guiada',
                  style: AppTypography.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Monte a base agora. Os exercícios entram no próximo passo.',
            style: AppTypography.inter(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12.2,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _HeroPill(label: goal, icon: Icons.flag_rounded)),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroPill(label: level, icon: Icons.tune_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.82), size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionKicker extends StatelessWidget {
  final String title;
  final String action;
  final bool isDark;
  final VoidCallback? onAction;

  const _SectionKicker({
    required this.title,
    required this.action,
    required this.isDark,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.inter(
              color: ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              action,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  onAction == null
                      ? AppTypography.mono(
                        color: mute,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      )
                      : AppTypography.inter(
                        color: mute,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PresetRail extends StatelessWidget {
  final List<_TreinoPreset> presets;
  final String selected;
  final bool isDark;
  final Color primary;
  final ValueChanged<_TreinoPreset> onTap;

  const _PresetRail({
    required this.presets,
    required this.selected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 22),
        itemCount: presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final preset = presets[index];
          final active = selected == preset.title;
          return Semantics(
            button: true,
            selected: active,
            label: 'Modelo ${preset.title}, ${preset.subtitle}',
            child: GestureDetector(
              onTap: () => onTap(preset),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 132,
                padding: const EdgeInsets.all(12),
                decoration: fxListCardDecoration(
                  context,
                  accent: active ? primary : null,
                  selected: active,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      preset.icon,
                      color: active ? primary : TokensStrip.textSecondary,
                      size: 20,
                    ),
                    const Spacer(),
                    Text(
                      preset.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        color:
                            isDark
                                ? EagleTokens.darkInk
                                : TokensStrip.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        color:
                            isDark
                                ? EagleTokens.darkInkMute
                                : TokensStrip.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LevelSelector extends StatelessWidget {
  final String? selected;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _LevelSelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final sel = selected == _niveis[i];
        final idleInk =
            isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
        final idleBorder =
            isDark
                ? EagleTokens.darkLine
                : TokensStrip.textSecondary.withValues(alpha: 0.22);
        final idleFill =
            isDark
                ? EagleTokens.darkCardHi.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.9);
        return Expanded(
          child: Semantics(
            button: true,
            selected: sel,
            label: 'Nível ${_niveisLabel[i]}',
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(_niveis[i]);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      sel
                          ? _niveisCor[i].withValues(
                            alpha: isDark ? 0.15 : 0.10,
                          )
                          : idleFill,
                  borderRadius: BorderRadius.circular(TokensStrip.rCard),
                  border: Border.all(
                    color:
                        sel
                            ? _niveisCor[i].withValues(alpha: 0.42)
                            : idleBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.10 : 0.035,
                      ),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                      spreadRadius: -14,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _niveisIcon[i],
                      color: sel ? _niveisCor[i] : idleInk,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        _niveisLabel[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          color: sel ? _niveisCor[i] : idleInk,
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  final String message;

  const _ErrorNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: EagleTokens.bad.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: EagleTokens.bad, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.inter(
                color: EagleTokens.bad,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FxField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final IconData icon;
  final bool isDark;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FxField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.label,
    required this.icon,
    required this.isDark,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      validator: validator,
      style: AppTypography.inter(
        color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      cursorColor: primary,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
        ),
        filled: true,
        fillColor: isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg,
        labelStyle: AppTypography.inter(
          color: isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? EagleTokens.darkLine : TokensStrip.borderDefault,
          ),
        ),
        enabledBorder: FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? EagleTokens.darkLine : TokensStrip.borderDefault,
          ),
        ),
        focusedBorder: FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.68)),
        ),
        errorBorder: FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: EagleTokens.bad),
        ),
        errorStyle: AppTypography.inter(
          color: EagleTokens.bad,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TreinoPreset {
  final String title;
  final String subtitle;
  final IconData icon;

  const _TreinoPreset(this.title, this.subtitle, this.icon);
}
