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
    final chrome = ShellChrome.of(context);
    final bg =
        chrome.isDark
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
                        chrome.isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.58),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: chrome.isDark ? 0.18 : 0.035,
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

class _CreationPreviewGroup extends StatelessWidget {
  final String title;
  final String goal;
  final String level;
  final Color primary;
  final VoidCallback onFocusName;

  const _CreationPreviewGroup({
    required this.title,
    required this.goal,
    required this.level,
    required this.primary,
    required this.onFocusName,
  });

  @override
  Widget build(BuildContext context) {
    return FxSettingsGroup(
      header: 'Criação guiada',
      caption: 'Monte a base agora. Os exercícios entram no próximo passo.',
      accent: primary,
      children: [
        FxSettingsTile(
          icon: Icons.fitness_center_rounded,
          label: title,
          subtitle: goal,
          value: level,
          showDivider: false,
          onTap: onFocusName,
        ),
      ],
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
            style: FocuxHubTypography.body(color: ink).copyWith(
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
                      : FocuxHubTypography.chip(mute),
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
                width: 148,
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
                      style: FocuxHubTypography.bodyMuted(
                        color:
                            isDark
                                ? EagleTokens.darkInk
                                : TokensStrip.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.bodyMuted(
                        color:
                            isDark
                                ? EagleTokens.darkInkMute
                                : TokensStrip.textSecondary,
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
    final chrome = ShellChrome.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 1,
          thickness: FxSettingsLayout.dividerThickness,
          color: chrome.line,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: List.generate(3, (i) => Expanded(child: _levelChip(i))),
          ),
        ),
        Divider(
          height: 1,
          thickness: FxSettingsLayout.dividerThickness,
          color: chrome.line,
        ),
      ],
    );
  }

  Widget _levelChip(int i) {
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
    return Padding(
      padding: EdgeInsets.only(right: i < 2 ? 8 : 0),
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
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color:
                  sel
                      ? _niveisCor[i].withValues(alpha: isDark ? 0.15 : 0.10)
                      : idleFill,
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              border: Border.all(
                color:
                    sel
                        ? _niveisCor[i].withValues(alpha: 0.42)
                        : idleBorder,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _niveisIcon[i],
                  color: sel ? _niveisCor[i] : idleInk,
                  size: 18,
                ),
                const SizedBox(height: 4),
                Text(
                  _niveisShortLabel[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: FocuxHubTypography.bodyMuted(
                    color: sel ? _niveisCor[i] : idleInk,
                    fontWeight: sel ? FontWeight.w800 : FontWeight.w700,
                  ).copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
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
