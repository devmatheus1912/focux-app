import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../perfil/data/white_label_repository.dart';
import '../../perfil/providers/perfil_provider.dart';
import '../../planos/providers/plano_features_provider.dart';
import 'aluno_invite_copy.dart';

/// Quem assina o convite, a partir do perfil do personal e do plano:
/// - nome do personal: sempre;
/// - nome do app e slogan: só com white-label (e o nome do app só se ele
///   ocultou a marca Focux). Qualquer falha cai no convite padrão.
Future<ConviteMarca?> carregarMarcaDoConvite(WidgetRef ref) async {
  try {
    final perfil = await ref.read(perfilProvider.future);
    final nome = perfil.nome.trim();
    if (nome.isEmpty) return null;
    final comWhiteLabel = ref.read(planoFeaturesProvider).value?.whiteLabel == true;
    if (!comWhiteLabel) return ConviteMarca(nomePersonal: nome);
    WhiteLabelConfig? config;
    try {
      config = await ref.read(whiteLabelConfigProvider.future);
    } catch (_) {
      config = null;
    }
    final nomeApp = (config?.appDisplayName ?? '').trim();
    final ocultou = config?.ocultarMarcaFocux ?? false;
    return ConviteMarca(
      nomePersonal: nome,
      nomeApp: ocultou && nomeApp.isNotEmpty ? nomeApp : 'Focux',
      slogan: perfil.slogan,
    );
  } catch (_) {
    return null;
  }
}
