import '../data/dashboard_tool_shortcuts.dart';
import '../../ferramentas/data/ferramentas_catalogo_models.dart';

class DashboardToolGroupSection {
  const DashboardToolGroupSection({
    required this.title,
    required this.shortcuts,
    this.subtitulo,
    this.collapsed = false,
  });

  final String title;
  final String? subtitulo;
  final List<DashboardToolShortcut> shortcuts;
  final bool collapsed;
}

/// Agrupa o catálogo em hubs (≤ 8), com papel secundário recolhível.
List<DashboardToolGroupSection> groupCatalogoHubs(
  FerramentasCatalogo catalogo, {
  String query = '',
}) {
  final q = query.trim();
  final sections = <DashboardToolGroupSection>[];

  for (final hub in catalogo.hubs) {
    final items =
        hub.itens.where((item) {
          if (q.isEmpty) return true;
          if (item.matchesQuery(q)) return true;
          if (hub.titulo.toLowerCase().contains(q.toLowerCase())) return true;
          if ((hub.subtitulo ?? '').toLowerCase().contains(q.toLowerCase())) {
            return true;
          }
          return false;
        }).toList();
    if (items.isEmpty) continue;

    final shortcuts = [
      for (final item in items) DashboardToolShortcut.fromEntrada(item),
    ];
    sections.add(
      DashboardToolGroupSection(
        title: hub.titulo,
        subtitulo: hub.subtitulo,
        shortcuts: shortcuts,
        collapsed: catalogoPapelTier(hub.papel) == CatalogoPapelTier.secundario,
      ),
    );
  }

  // Primários primeiro; secundários (studio/avançado/conta) depois.
  sections.sort((a, b) {
    final ac = a.collapsed ? 1 : 0;
    final bc = b.collapsed ? 1 : 0;
    return ac.compareTo(bc);
  });
  return sections;
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
            s.displayFeatureName.toLowerCase().contains(q) ||
            s.entrada.matchesQuery(q),
      )
      .toList();
}
