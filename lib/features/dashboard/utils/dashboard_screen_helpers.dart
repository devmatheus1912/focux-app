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

PulseMetricCopy pulseAtivosCopy(int alunosAtivos) =>
    alunosAtivos == 0
        ? (hint: 'Nenhum aluno ativo', semantics: '0 alunos ativos')
        : (hint: 'Base ativa', semantics: '$alunosAtivos ativos');

PulseMetricCopy pulseCheckinsCopy(int checkinsHoje) =>
    checkinsHoje == 0
        ? (hint: 'Sem movimento hoje', semantics: '0 check-ins, sem movimento hoje')
        : (hint: 'Check-ins de hoje', semantics: '$checkinsHoje check-ins');

/// Contagem do modelo de alertas (Risco operacional), não do churn da retenção.
PulseMetricCopy pulseRiscoCopy(int riscoAlto) =>
    riscoAlto == 0
        ? (
          hint: 'Nenhum aluno em risco',
          semantics: 'Nenhum aluno em risco operacional',
        )
        : (
          hint: 'Alunos pedem contato',
          semantics:
              '$riscoAlto ${riscoAlto == 1 ? 'aluno' : 'alunos'} em risco operacional',
        );

/// Copy de empty do pulso — BFF manda `emptyHint`; FE replica se o payload for legado.
String? dashboardPulseEmptyHint({
  required int checkinsHoje,
  required List<double> checkinsTrend,
  String? fromApi,
}) {
  final api = fromApi?.trim();
  if (api != null && api.isNotEmpty) return api;
  if (checkinsHoje > 0) return null;
  final weekEmpty =
      checkinsTrend.isEmpty || checkinsTrend.every((v) => v <= 0);
  if (weekEmpty) return 'Sem treinos';
  return 'Nenhum check-in hoje';
}

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
