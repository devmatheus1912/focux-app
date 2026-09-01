String habitoTemplateLabel({
  required String titulo,
  String? icone,
}) {
  final nome = titulo.trim();
  final glyph = icone?.trim();
  if (glyph != null && glyph.isNotEmpty) {
    return nome.isEmpty ? glyph : '$glyph $nome';
  }
  return nome.isEmpty ? 'Template' : nome;
}

String habitoTemplateValue(String? titulo, {String? icone}) {
  if (titulo == null || titulo.trim().isEmpty) return 'Personalizado';
  return habitoTemplateLabel(titulo: titulo, icone: icone);
}

String habitoSubtitle({String? descricao, required int metaSemanal}) {
  final desc = descricao?.trim();
  if (desc != null && desc.isNotEmpty) return desc;
  return 'Meta semanal: ${metaSemanal}x';
}

String habitoMetaValue(int metaSemanal) => '${metaSemanal}x';

String habitoComplianceLabel(String? alunoNome) {
  final nome = alunoNome?.trim();
  if (nome == null || nome.isEmpty) return 'Aluno';
  return nome;
}

String habitoComplianceValue(int pct) => '$pct%';

String habitoComplianceSubtitle(int checksSemana) {
  if (checksSemana == 1) return '1 check na semana';
  return '$checksSemana checks na semana';
}

String habitoComplianceFxIcon(int pct) {
  if (pct >= 70) return 'circle-check';
  if (pct >= 40) return 'trend';
  return 'alert-triangle';
}

bool habitoComplianceDanger(int pct) => pct < 40;

String habitoHubSubtitle(String? freshness) {
  const base = 'Coaching diário e aderência';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}
