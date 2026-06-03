part of 'aluno_detail_screen.dart';

class _OperationalMetricTile extends StatelessWidget {
  const _OperationalMetricTile({
    required this.label,
    required this.value,
    required this.hint,
    required this.color,
    required this.isDark,
    this.semanticsLabel,
  });

  final String label;
  final String value;
  final String hint;
  final Color color;
  final bool isDark;
  final String? semanticsLabel;

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
          Text(
            value,
            style: TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          Text(hint, style: TextStyle(color: color, fontSize: 10.5)),
        ],
      ),
    );

    if (semanticsLabel == null) return tile;
    return Semantics(label: semanticsLabel, child: tile);
  }
}

