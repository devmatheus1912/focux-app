enum CommandActionTone { primary, hot, money }

class CommandActionItem {
  final String icon;
  final String title;
  final String subtitle;
  final String route;
  final CommandActionTone tone;
  final bool isRadarStudent;
  final String? priorityBadge;
  final int? alunoId;
  /// Quando preenchida e [commandActionAutoCompletesOnOpen], concluir ao abrir.
  final String? actionKey;

  const CommandActionItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.tone,
    this.isRadarStudent = false,
    this.priorityBadge,
    this.alunoId,
    this.actionKey,
  });
}
