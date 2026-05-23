import '../../dashboard/data/dashboard_repository.dart';
import '../data/perfil_repository.dart';

enum PerfilChecklistAction { photo, editProfile, brand, wallet, convites }

class PerfilChecklistItem {
  const PerfilChecklistItem({
    required this.label,
    required this.done,
    required this.action,
  });

  final String label;
  final bool done;
  final PerfilChecklistAction action;
}

class PerfilNextStep {
  const PerfilNextStep({
    required this.label,
    required this.buttonLabel,
    required this.action,
  });

  final String label;
  final String buttonLabel;
  final PerfilChecklistAction action;
}

class PerfilReadinessView {
  const PerfilReadinessView({
    required this.score,
    required this.items,
    this.nextStep,
  });

  final int score;
  final List<PerfilChecklistItem> items;
  final PerfilNextStep? nextStep;

  static const _order = [
    'Foto',
    'CREF',
    'Especialidade',
    'Bio',
    'Instagram',
    'Paleta',
    'PIX',
  ];

  static PerfilReadinessView from({
    required PerfilPersonal perfil,
    required DashboardData dashboard,
  }) {
    final missing = _missingLabels(perfil, dashboard);
    final items =
        _order
            .map(
              (label) => PerfilChecklistItem(
                label: label,
                done: !missing.contains(label),
                action: _actionFor(label),
              ),
            )
            .toList();

    final score =
        perfil.readinessPercent ??
        ((items.where((item) => item.done).length / items.length) * 100)
            .round();

    final next = items.firstWhere(
      (item) => !item.done,
      orElse: () => const PerfilChecklistItem(
        label: '',
        done: true,
        action: PerfilChecklistAction.brand,
      ),
    );

    final PerfilNextStep? nextStep =
        next.done
            ? null
            : PerfilNextStep(
              label: next.label,
              buttonLabel: _buttonLabelFor(next),
              action: next.action,
            );

    return PerfilReadinessView(
      score: score,
      items: items,
      nextStep: nextStep,
    );
  }

  static Set<String> _missingLabels(
    PerfilPersonal perfil,
    DashboardData dashboard,
  ) {
    if (perfil.readinessMissing != null) {
      return perfil.readinessMissing!.toSet();
    }

    final missing = <String>{};
    if (!_hasText(perfil.logoUrl ?? dashboard.logoUrl)) missing.add('Foto');
    if (!_hasText(perfil.cref)) missing.add('CREF');
    if (!_hasText(perfil.especialidades ?? perfil.especialidade)) {
      missing.add('Especialidade');
    }
    if (!_hasText(
      perfil.descricaoProfissional ?? dashboard.descricaoProfissional,
    )) {
      missing.add('Bio');
    }
    if (!_hasText(perfil.instagram ?? dashboard.instagram)) {
      missing.add('Instagram');
    }
    if (!_hasText(perfil.corPrimaria ?? dashboard.corPrimaria) ||
        !_hasText(perfil.corSecundaria ?? dashboard.corSecundaria)) {
      missing.add('Paleta');
    }
    if (!_hasWallet(perfil)) missing.add('PIX');
    return missing;
  }

  static PerfilChecklistAction _actionFor(String label) {
    return switch (label) {
      'Foto' => PerfilChecklistAction.photo,
      'CREF' => PerfilChecklistAction.editProfile,
      'Especialidade' => PerfilChecklistAction.editProfile,
      'Bio' => PerfilChecklistAction.editProfile,
      'Instagram' => PerfilChecklistAction.editProfile,
      'Paleta' => PerfilChecklistAction.brand,
      'PIX' => PerfilChecklistAction.wallet,
      _ => PerfilChecklistAction.editProfile,
    };
  }

  static String _buttonLabelFor(PerfilChecklistItem item) {
    return switch (item.action) {
      PerfilChecklistAction.photo => 'Adicionar foto',
      PerfilChecklistAction.editProfile => 'Completar cadastro',
      PerfilChecklistAction.brand => 'Ajustar marca',
      PerfilChecklistAction.wallet => 'Configurar PIX',
      PerfilChecklistAction.convites => 'Convidar alunos',
    };
  }

  static bool _hasWallet(PerfilPersonal perfil) =>
      _hasText(perfil.chavePix) ||
      (_hasText(perfil.banco) &&
          _hasText(perfil.agencia) &&
          _hasText(perfil.conta));

  static bool _hasText(String? value) =>
      value != null && value.trim().isNotEmpty;
}
