import 'enums.dart';

class BibliotecaWizardDraft {
  const BibliotecaWizardDraft({
    required this.step,
    required this.modalidades,
    required this.espacos,
  });

  final int step;
  final Set<Modalidade> modalidades;
  final Set<Espaco> espacos;
}

/// Rascunho in-memory: sair e reabrir o wizard retoma a etapa.
abstract final class BibliotecaWizardDraftCache {
  static BibliotecaWizardDraft? _draft;

  static BibliotecaWizardDraft? get() => _draft;

  static void put(BibliotecaWizardDraft draft) {
    _draft = draft;
  }

  static void clear() {
    _draft = null;
  }
}
