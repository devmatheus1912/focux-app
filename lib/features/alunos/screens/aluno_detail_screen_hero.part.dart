part of 'aluno_detail_screen.dart';

class _AlunoDetailHeroCard extends StatelessWidget {
  const _AlunoDetailHeroCard({
    required this.aluno,
    required this.isDark,
    required this.primary,
    required this.ink,
    required this.mute,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;
  final Color ink;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final displayName = fxTitleCaseName(aluno.nome);
    final objective = _heroPrettyObjective(aluno.objetivo);
    final status = _heroStatusVisual(aluno, isDark);
    final aderColor = EagleTokens.aderenciaColor(
      (aluno.aderenciaPercent ?? 0).toDouble(),
      isDark: isDark,
    );

    return Semantics(
      container: true,
      label:
          '$displayName, objetivo $objective, ${status.label}, aderência ${aluno.aderenciaPercent ?? 'indisponível'} por cento',
      child: Container(
        key: const ValueKey('aluno360_hero_card'),
        width: double.infinity,
        decoration: chrome.panel(
          radius: TokensStrip.rCard,
          accent: primary,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primary.withValues(alpha: isDark ? 0.35 : 0.55),
                    BrandPalette.accent(primary).withValues(alpha: 0.85),
                    primary.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AlunoDetailHeroAvatar(
                        name: displayName,
                        photoUrl: aluno.fotoUrl,
                        primary: primary,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    displayName,
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.45,
                                      height: 1.1,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _HeroStatusPill(
                                  label: status.label,
                                  background: status.background,
                                  foreground: status.foreground,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: primary.withValues(
                                  alpha: isDark ? 0.14 : 0.08,
                                ),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: primary.withValues(
                                    alpha: isDark ? 0.28 : 0.16,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.fitness_center_rounded,
                                    size: 13,
                                    color: primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      objective,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: primary,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroMetricChip(
                          label: 'Aderência',
                          value:
                              aluno.aderenciaPercent == null
                                  ? '—'
                                  : '${aluno.aderenciaPercent}%',
                          color: aderColor,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HeroMetricChip(
                          label: 'Sem treino',
                          value:
                              aluno.diasSemTreino == null
                                  ? '—'
                                  : '${aluno.diasSemTreino}d',
                          color:
                              (aluno.diasSemTreino ?? 0) >=
                                      AlunoFollowUpStore.diasSemTreinoLimite
                                  ? EagleTokens.warn
                                  : mute,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _HeroMetricChip(
                          label: 'Prontidão',
                          value:
                              aluno.scoreProntidao == null
                                  ? '—'
                                  : '${aluno.scoreProntidao}',
                          color: primary,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatusVisual {
  const _HeroStatusVisual({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

_HeroStatusVisual _heroStatusVisual(Aluno aluno, bool isDark) {
  if (aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente) {
    return _HeroStatusVisual(
      label: 'Inadimplente',
      background: isDark ? const Color(0x24FF8B8B) : EagleTokens.badSoft,
      foreground: isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad,
    );
  }
  if (aluno.status == 'INATIVO') {
    return _HeroStatusVisual(
      label: 'Inativo',
      background: isDark ? const Color(0x24E2B46F) : EagleTokens.warnSoft,
      foreground: isDark ? const Color(0xFFE2B46F) : EagleTokens.warn,
    );
  }
  if (aluno.emRisco) {
    return _HeroStatusVisual(
      label: 'Em risco',
      background: isDark ? const Color(0x24FFB77A) : EagleTokens.warnSoft,
      foreground: isDark ? const Color(0xFFFFB77A) : EagleTokens.warn,
    );
  }
  return _HeroStatusVisual(
    label: 'Ativo',
    background: isDark ? const Color(0x1F6FE296) : EagleTokens.goodSoft,
    foreground: isDark ? const Color(0xFF6FE296) : EagleTokens.good,
  );
}

String _heroPrettyObjective(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return 'Objetivo não definido';
  return raw
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map(
        (part) =>
            part.length <= 2
                ? part.toUpperCase()
                : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String? _heroResolvePhotoUrl(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;
  final uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) return raw;
  final base =
      Env.apiUrl.endsWith('/')
          ? Env.apiUrl.substring(0, Env.apiUrl.length - 1)
          : Env.apiUrl;
  final path = raw.startsWith('/') ? raw : '/$raw';
  return '$base$path';
}

Color _heroAvatarFallbackColor(String name, bool isDark) {
  final palette =
      isDark
          ? const [
            Color(0xFF1EC8C8),
            Color(0xFF26A8A8),
            Color(0xFF159A9A),
            Color(0xFF32D4D4),
          ]
          : const [
            Color(0xFF1EC8C8),
            Color(0xFF26A8A8),
            Color(0xFF5EEAD4),
            Color(0xFF159A9A),
          ];
  final hash = name.isNotEmpty ? name.codeUnitAt(0) : 0;
  return palette[hash % palette.length];
}

class _AlunoDetailHeroAvatar extends StatelessWidget {
  const _AlunoDetailHeroAvatar({
    required this.name,
    required this.photoUrl,
    required this.primary,
    required this.isDark,
  });

  final String name;
  final String? photoUrl;
  final Color primary;
  final bool isDark;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _heroResolvePhotoUrl(photoUrl);
    final neon = BrandPalette.accent(primary);

    if (resolvedUrl != null) {
      return Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: neon.withValues(alpha: isDark ? 0.92 : 0.82),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: neon.withValues(alpha: isDark ? 0.28 : 0.22),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: Image.network(
            resolvedUrl,
            width: _size - 8,
            height: _size - 8,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => _AlunoDetailHeroInitials(
                  name: name,
                  primary: primary,
                  isDark: isDark,
                ),
          ),
        ),
      );
    }

    return _AlunoDetailHeroInitials(
      name: name,
      primary: primary,
      isDark: isDark,
    );
  }
}

class _AlunoDetailHeroInitials extends StatelessWidget {
  const _AlunoDetailHeroInitials({
    required this.name,
    required this.primary,
    required this.isDark,
  });

  final String name;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final fallback = _heroAvatarFallbackColor(name, isDark);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandPalette.soft(primary, dark: isDark),
            fallback.withValues(alpha: isDark ? 0.55 : 0.35),
          ],
        ),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.35 : 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.18 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        fxInitials(name),
        style: TextStyle(
          color: primary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeroStatusPill extends StatelessWidget {
  const _HeroStatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _HeroMetricChip extends StatelessWidget {
  const _HeroMetricChip({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.22 : 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink.withValues(alpha: 0.62),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.35,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentQuickActions extends StatelessWidget {
  const _StudentQuickActions({
    required this.aluno,
    required this.isDark,
    required this.primary,
    required this.onMessage,
    required this.onPassword,
    required this.onEdit,
    required this.onEvolve,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;
  final VoidCallback onMessage;
  final VoidCallback onPassword;
  final VoidCallback onEdit;
  final VoidCallback onEvolve;

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.flash_on_rounded, color: primary, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ações rápidas',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Contato, acesso e evolução de ${aluno.nome.split(' ').first}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mute,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 360;
              final pills = [
                _QuickActionPill(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  primary: primary,
                  onTap: onMessage,
                ),
                _QuickActionPill(
                  icon: Icons.key_outlined,
                  label: 'Senha',
                  primary: primary,
                  onTap: onPassword,
                ),
                _QuickActionPill(
                  icon: Icons.trending_up_rounded,
                  label: 'Evoluir',
                  primary: primary,
                  onTap: onEvolve,
                ),
                _QuickActionPill(
                  icon: Icons.edit_outlined,
                  label: 'Editar',
                  primary: primary,
                  onTap: onEdit,
                ),
              ];

              if (narrow) {
                final itemWidth = (constraints.maxWidth - 7) / 2;
                return Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final pill in pills)
                      SizedBox(width: itemWidth, child: pill),
                  ],
                );
              }

              return Row(
                children: [
                  for (var i = 0; i < pills.length; i++) ...[
                    if (i > 0) const SizedBox(width: 7),
                    Expanded(child: pills[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionPill extends StatelessWidget {
  const _QuickActionPill({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: primary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
