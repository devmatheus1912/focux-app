import '../data/perfil_repository.dart';
import '../../../l10n/pt.dart';

enum PerfilChecklistAction { photo, editProfile }

class PerfilChecklistItem {
  PerfilChecklistItem({
    required this.label,
    required this.done,
    required this.action,
  });

  final String label;
  final bool done;
  final PerfilChecklistAction action;
}

class PerfilNextStep {
  PerfilNextStep({
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

/// Microcopy de lacunas (singular/plural).
String perfilReadinessGapCopy(int missingCount) {
  if (missingCount <= 0) return ptS.perfilSeuPerfilEstaPronto;
  if (missingCount == 1) return ptS.perfilFalta1PassoNoSeu;
  return ptS.perfilFaltamPassosNoSeuPerfil(missingCount);
}

/// Seis itens que todo plano consegue fechar. Cor e PIX ficam fora: dependem do
/// plano e têm lugar próprio (Marca e sugestão da Hoje). `readinessPercent` do
/// backend conta oito e só serve a builds antigos.
class PerfilReadinessView {
  PerfilReadinessView({
    required this.score,
    required this.items,
    this.nextStep,
  });

  final int score;
  final List<PerfilChecklistItem> items;
  final PerfilNextStep? nextStep;

  int get missingCount => items.where((item) => !item.done).length;

  static PerfilReadinessView from(PerfilPersonal perfil) {
    PerfilChecklistItem item(String label, String? valor) => PerfilChecklistItem(
      label: label,
      done: _hasText(valor),
      action:
          label == ptS.perfilFoto
              ? PerfilChecklistAction.photo
              : PerfilChecklistAction.editProfile,
    );

    final items = [
      item(ptS.perfilFoto, perfil.logoUrl),
      item('CREF', perfil.cref),
      item(ptS.perfilEspecialidade, perfil.especialidades ?? perfil.especialidade),
      item(ptS.perfilBio, perfil.descricaoProfissional),
      item(ptS.perfilTelefone, perfil.telefone),
      item(ptS.landingInstagram, perfil.instagram),
    ];

    final score =
        ((items.where((item) => item.done).length / items.length) * 100).round();
    final next = items.where((item) => !item.done).firstOrNull;

    return PerfilReadinessView(
      score: score,
      items: items,
      nextStep:
          next == null
              ? null
              : PerfilNextStep(
                label: next.label,
                buttonLabel: next.action == PerfilChecklistAction.photo
                    ? ptS.alunoPendenciaFotoTitulo
                    : next.label == ptS.perfilTelefone
                    ? ptS.perfilAdicionarTelefone
                    : ptS.alunoPerfilCompletarTitulo,
                action: next.action,
              ),
    );
  }
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
