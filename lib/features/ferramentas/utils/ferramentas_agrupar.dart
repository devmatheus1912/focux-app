import '../../dashboard/utils/dashboard_tool_groups.dart';

/// Grupos prontos para a tela Ferramentas.
///
/// Um grupo com um item só, de mesmo nome ("Captação" com "Captação"), não
/// ensina nada: perde o cabeçalho e junta com os vizinhos na mesma lista.
/// Grupos de verdade (vários itens, ou nome diferente) ficam como estão.
List<DashboardToolGroupSection> agruparFerramentas(
  List<DashboardToolGroupSection> grupos,
) {
  final saida = <DashboardToolGroupSection>[];
  var soltos = <DashboardToolGroupSection>[];

  void fecharSoltos() {
    if (soltos.isEmpty) return;
    saida.add(
      DashboardToolGroupSection(
        title: '',
        shortcuts: [for (final g in soltos) ...g.shortcuts],
        collapsed: soltos.first.collapsed,
      ),
    );
    soltos = [];
  }

  for (final grupo in grupos) {
    if (_repeteONome(grupo)) {
      if (soltos.isNotEmpty && soltos.first.collapsed != grupo.collapsed) {
        fecharSoltos();
      }
      soltos.add(grupo);
    } else {
      fecharSoltos();
      saida.add(grupo);
    }
  }
  fecharSoltos();
  return saida;
}

bool _repeteONome(DashboardToolGroupSection grupo) {
  if (grupo.shortcuts.length != 1) return false;
  return _norm(grupo.shortcuts.first.label) == _norm(grupo.title);
}

String _norm(String texto) => texto.trim().toLowerCase();
