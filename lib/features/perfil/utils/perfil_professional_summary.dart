import 'package:flutter/material.dart';

import '../../../core/utils/br_phone.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../data/perfil_repository.dart';

class PerfilProfessionalFact {
  const PerfilProfessionalFact({
    required this.icon,
    required this.label,
    required this.value,
    required this.pending,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool pending;
}

/// Resumo compacto dos dados profissionais (hub Perfil — sem espelhar o form).
class PerfilProfessionalSummary {
  const PerfilProfessionalSummary({
    required this.facts,
    required this.missingPhone,
    required this.ctaLabel,
  });

  final List<PerfilProfessionalFact> facts;
  final bool missingPhone;
  final String ctaLabel;

  List<String> get lines => [
    for (final fact in facts)
      fact.pending ? '${fact.label} pendente' : fact.value,
  ];

  static PerfilProfessionalSummary from({
    required PerfilPersonal perfil,
    required DashboardData dashboard,
  }) {
    final phone = (perfil.telefone ?? '').trim();
    final missingPhone = phone.isEmpty;
    final specialty =
        (perfil.especialidades ?? perfil.especialidade ?? '').trim();
    final cref = (perfil.cref ?? '').trim();
    final ig = (perfil.instagram ?? dashboard.instagram ?? '').trim();

    final facts = <PerfilProfessionalFact>[
      PerfilProfessionalFact(
        icon: Icons.phone_outlined,
        label: 'WhatsApp',
        value: missingPhone ? 'Pendente' : BrPhone.formatDisplay(phone),
        pending: missingPhone,
      ),
      PerfilProfessionalFact(
        icon: Icons.badge_outlined,
        label: 'CREF',
        value: cref.isEmpty ? 'Pendente' : cref,
        pending: cref.isEmpty,
      ),
      PerfilProfessionalFact(
        icon: Icons.fitness_center_outlined,
        label: 'Especialidade',
        value: specialty.isEmpty ? 'Pendente' : specialty,
        pending: specialty.isEmpty,
      ),
      PerfilProfessionalFact(
        icon: Icons.alternate_email_rounded,
        label: 'Instagram',
        value: ig.isEmpty
            ? 'Pendente'
            : (ig.startsWith('@') ? ig : '@$ig'),
        pending: ig.isEmpty,
      ),
    ];

    return PerfilProfessionalSummary(
      facts: facts,
      missingPhone: missingPhone,
      ctaLabel: missingPhone ? 'Completar cadastro' : 'Editar cadastro',
    );
  }
}
