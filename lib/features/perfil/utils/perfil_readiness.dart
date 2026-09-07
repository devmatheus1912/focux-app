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

/// Carteira comercial pronta (PIX ou dados bancários completos).
bool perfilHasWallet(PerfilPersonal perfil) =>
    _hasText(perfil.chavePix) ||
    (_hasText(perfil.banco) &&
        _hasText(perfil.agencia) &&
        _hasText(perfil.conta));

/// Microcopy de lacunas da prontidão (singular/plural).
String perfilReadinessGapCopy(int missingCount) {
  if (missingCount <= 0) {
    return 'Seu perfil comercial está pronto para operar.';
  }
  if (missingCount == 1) {
    return 'Falta 1 passo para fechar o perfil comercial.';
  }
  return 'Faltam $missingCount passos para fechar o perfil comercial.';
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

  bool get isPixDone =>
      items.any((item) => item.label == 'PIX' && item.done);

  int get missingCount => items.where((item) => !item.done).length;

  static const _order = [
    'Foto',
    'Telefone',
    'CREF',
    'Especialidade',
    'Bio',
    'Instagram',
    'Paleta',
    'PIX',
  ];

  /// SSoT: `readinessPercent` / `readinessMissing` do GET /api/personal/perfil.
  /// Sem esses campos, cai no cálculo local dos 8 itens.
  static PerfilReadinessView from(PerfilPersonal perfil) {
    final missing = _missingLabels(perfil);
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

    final localScore =
        ((items.where((item) => item.done).length / items.length) * 100)
            .round();
    final score = perfil.readinessPercent ?? localScore;

    final next = items.firstWhere(
      (item) => !item.done,
      orElse:
          () => const PerfilChecklistItem(
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

    return PerfilReadinessView(score: score, items: items, nextStep: nextStep);
  }

  static Set<String> _missingLabels(PerfilPersonal perfil) {
    final fromApi = perfil.readinessMissing;
    if (fromApi != null) {
      return fromApi.toSet();
    }
    return _localMissing(perfil);
  }

  static Set<String> _localMissing(PerfilPersonal perfil) {
    final missing = <String>{};
    if (!_hasText(perfil.logoUrl)) missing.add('Foto');
    if (!_hasText(perfil.telefone)) missing.add('Telefone');
    if (!_hasText(perfil.cref)) missing.add('CREF');
    if (!_hasText(perfil.especialidades ?? perfil.especialidade)) {
      missing.add('Especialidade');
    }
    if (!_hasText(perfil.descricaoProfissional)) {
      missing.add('Bio');
    }
    if (!_hasText(perfil.instagram)) {
      missing.add('Instagram');
    }
    if (!_hasText(perfil.corPrimaria) || !_hasText(perfil.corSecundaria)) {
      missing.add('Paleta');
    }
    if (!perfilHasWallet(perfil)) missing.add('PIX');
    return missing;
  }

  static PerfilChecklistAction _actionFor(String label) {
    return switch (label) {
      'Foto' => PerfilChecklistAction.photo,
      'Telefone' => PerfilChecklistAction.editProfile,
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
    return switch (item.label) {
      'Foto' => 'Adicionar foto',
      'Telefone' => 'Adicionar telefone',
      'CREF' || 'Especialidade' || 'Bio' || 'Instagram' => 'Completar cadastro',
      'Paleta' => 'Ajustar marca',
      'PIX' => 'Configurar PIX',
      _ => switch (item.action) {
        PerfilChecklistAction.photo => 'Adicionar foto',
        PerfilChecklistAction.editProfile => 'Completar cadastro',
        PerfilChecklistAction.brand => 'Ajustar marca',
        PerfilChecklistAction.wallet => 'Configurar PIX',
        PerfilChecklistAction.convites => 'Convidar alunos',
      },
    };
  }
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
