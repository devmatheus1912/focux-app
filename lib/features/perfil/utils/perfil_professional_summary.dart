import '../../../core/utils/br_phone.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../data/perfil_repository.dart';

/// Resumo compacto dos dados profissionais (hub Perfil — sem espelhar o form).
class PerfilProfessionalSummary {
  const PerfilProfessionalSummary({
    required this.lines,
    required this.missingPhone,
    required this.ctaLabel,
  });

  final List<String> lines;
  final bool missingPhone;
  final String ctaLabel;

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

    final lines = <String>[
      if (!missingPhone) BrPhone.formatDisplay(phone) else 'WhatsApp pendente',
      if (cref.isNotEmpty) cref else 'CREF pendente',
      if (specialty.isNotEmpty) specialty else 'Especialidade pendente',
      if (ig.isNotEmpty)
        ig.startsWith('@')
            ? ig
            : '@$ig'
      else
        'Instagram pendente',
    ];

    return PerfilProfessionalSummary(
      lines: lines,
      missingPhone: missingPhone,
      ctaLabel: missingPhone ? 'Completar cadastro' : 'Editar cadastro',
    );
  }
}
