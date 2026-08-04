import '../data/dashboard_tool_shortcuts.dart';

class DashboardToolGroupSection {
  const DashboardToolGroupSection({
    required this.title,
    required this.shortcuts,
  });

  final String title;
  final List<DashboardToolShortcut> shortcuts;
}

/// Agrupa atalhos pelo [DashboardToolShortcut.group] explícito.
List<DashboardToolGroupSection> groupDashboardToolShortcuts(
  List<DashboardToolShortcut> shortcuts,
) {
  final buckets = <DashboardToolGroup, List<DashboardToolShortcut>>{
    for (final g in DashboardToolGroup.values) g: <DashboardToolShortcut>[],
  };

  for (final shortcut in shortcuts) {
    buckets[shortcut.group]!.add(shortcut);
  }

  return [
    for (final g in DashboardToolGroup.values)
      if (buckets[g]!.isNotEmpty)
        DashboardToolGroupSection(title: g.title, shortcuts: buckets[g]!),
  ];
}

List<DashboardToolShortcut> filterDashboardToolShortcuts(
  List<DashboardToolShortcut> shortcuts,
  String query,
) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return shortcuts;
  return shortcuts
      .where(
        (s) =>
            s.label.toLowerCase().contains(q) ||
            s.displayFeatureName.toLowerCase().contains(q),
      )
      .toList();
}
