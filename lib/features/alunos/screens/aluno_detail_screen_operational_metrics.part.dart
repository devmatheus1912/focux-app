part of 'aluno_detail_screen.dart';

class _OperationalMetricTile extends StatelessWidget {
  const _OperationalMetricTile({
    required this.label,
    required this.value,
    required this.hint,
    required this.color,
    required this.isDark,
    this.semanticsLabel,
    this.leadingIcon,
  });

  final String label;
  final String value;
  final String hint;
  final Color color;
  final bool isDark;
  final String? semanticsLabel;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.24 : 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: mute,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: 17, color: color),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          Text(hint, style: TextStyle(color: color, fontSize: 10.5)),
        ],
      ),
    );

    if (semanticsLabel == null) return tile;
    return Semantics(label: semanticsLabel, child: tile);
  }
}

IconData _riscoMetricIcon(String? raw) {
  final value = (raw ?? '').trim().toUpperCase();
  return switch (value) {
    'ALTO' || 'HIGH' => Icons.warning_amber_rounded,
    'MEDIO' || 'MÉDIO' || 'MEDIUM' => Icons.error_outline_rounded,
    'BAIXO' || 'LOW' => Icons.check_circle_outline_rounded,
    _ => Icons.help_outline_rounded,
  };
}
