import 'package:flutter/material.dart';

/// Badge de procedência do vídeo no check-in — mesma regra no thumbnail e no player.
///
/// Só exibe quando há confiança explícita: licença Focux ou upload do personal.
/// Biblioteca genérica / técnica sem source não ganha chip (evita ruído).
abstract final class CheckinVideoBadge {
  CheckinVideoBadge._();

  static String? label({
    String? licenseStatus,
    String? videoSource,
  }) {
    if (licenseStatus == 'LICENSED') return 'Vídeo licenciado';
    if (videoSource == 'PERSONAL_UPLOAD') return 'Enviado pelo personal';
    return null;
  }

  static IconData? icon({
    String? licenseStatus,
    String? videoSource,
  }) {
    if (licenseStatus == 'LICENSED') return Icons.verified_rounded;
    if (videoSource == 'PERSONAL_UPLOAD') return Icons.person_rounded;
    return null;
  }
}
