part of 'aluno_detail_screen.dart';

class _StudentQuickActions extends StatelessWidget {
  const _StudentQuickActions({
    required this.aluno,
    required this.isDark,
    required this.primary,
    required this.onPassword,
    required this.onEdit,
    required this.onEvolve,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;
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
                      'Acesso e evolução de ${aluno.nome.split(' ').first}',
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
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
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
    ),
    );
  }
}
