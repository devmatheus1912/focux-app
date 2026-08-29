import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';

/// Linha única da prescrição ativa — paridade dock, sheet e detalhe.
String formatActivePrescriptionLine({
  required String presetLabel,
  required String series,
  required String repeticoes,
  required String descansoSegundos,
  String tipoSerie = 'NORMAL',
}) {
  final tipoLabel = switch (tipoSerie) {
    'SUPERSET' => ' · Superset',
    'DROPSET' => ' · Drop set',
    _ => '',
  };
  return '$presetLabel · $series×$repeticoes · ${descansoSegundos}s$tipoLabel';
}

/// Caption do bloco de prescrição (ex.: «Prescrição padrão»).
TextStyle activePrescriptionCaptionStyle({required Color mute}) =>
    FxSettingsLayout.sectionHeader(color: mute);

/// Valor escaneável — `bodyMuted` 13pt w800 na cor da marca (Perfil + sheet).
TextStyle activePrescriptionLineStyle({required Color brand}) =>
    FocuxHubTypography.bodyMuted(
      color: brand,
      fontWeight: FontWeight.w800,
    );

/// Strip inset da prescrição — sem glow (paridade dock + Perfil inset).
BoxDecoration activePrescriptionStripDecoration({
  required Color brand,
  required bool isDark,
}) {
  return BoxDecoration(
    color: brand.withValues(alpha: isDark ? 0.12 : 0.06),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: brand.withValues(alpha: 0.22)),
  );
}

/// Métricas de volume (séries, reps, descanso, carga).
TextStyle activePrescriptionMetricStyle({required Color ink}) =>
    FxSettingsLayout.rowMetric(color: ink).copyWith(fontWeight: FontWeight.w800);
