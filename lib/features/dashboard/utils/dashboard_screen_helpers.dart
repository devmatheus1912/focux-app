import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/curated_brand_palettes.dart';
import '../../../core/utils/fx_utils.dart';
import '../../alunos/data/aluno_repository.dart';
import '../data/command_center_data.dart';

/// Nome do personal na Home — mesmo valor do BFF/`perfil` (title-case).
/// Compostos e nomes longos: UI usa `maxLines: 1` + ellipsis; não corta no 1º token.
String dashboardPersonalDisplayName(String? nome) {
  final trimmed = nome?.trim();
  if (trimmed == null || trimmed.isEmpty) return 'Personal';
  return fxTitleCaseName(trimmed);
}

/// @Deprecated — preferir [dashboardPersonalDisplayName] (nome completo SSOT).
String dashboardPersonalFirstName(String? nome) {
  final parts =
      nome
          ?.trim()
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList() ??
      const <String>[];
  if (parts.isEmpty) return 'Personal';
  return fxTitleCaseName(parts.first);
}

bool isRiskEchoCopy(String text) {
  final lower = text.toLowerCase();
  return lower.contains('risco') ||
      lower.contains('abandono') ||
      lower.contains('aderência') ||
      lower.contains('aderencia');
}

/// Stub mínimo para o rail de atenção a partir do BFF (sem sidecar `/alunos`).
Aluno alunoFromAlertaResumo(AlertaResumo alerta) {
  return Aluno(
    id: alerta.id,
    nome: alerta.nomeAluno,
    email: '',
    status: 'ATIVO',
    emRisco: true,
    objetivo: alerta.motivo.isEmpty ? null : alerta.motivo,
    riscoNivel: alerta.nivelRisco,
  );
}

typedef PulseMetricCopy = ({String hint, String semantics});

/// Cor primária do personal (BFF) — soft branding no chrome da Home.
/// Remapeia cyan legado (#13C2C2) → petróleo, igual tema/perfil.
Color? dashboardParseBrandColor(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  return CuratedBrandPalette.safePrimary(
    BrandPalette.resolveStoredPrimary(trimmed),
  );
}
