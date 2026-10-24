import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/ficha_modelos_provider.dart';
import '../utils/treino_criacao_fluxo.dart';

/// Quando o treino foi aberto por um modelo de ficha: de qual modelo é e uma
/// fileira para trocar de sessão do modelo sem voltar.
class ModeloContextoDoTreino extends ConsumerWidget {
  const ModeloContextoDoTreino({
    super.key,
    required this.modeloId,
    required this.treinoId,
  });

  final int modeloId;
  final int treinoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelo = ref.watch(fichaModeloProvider(modeloId)).asData?.value;
    if (modelo == null) return const SizedBox.shrink();

    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final sessoes = modelo.sessoes.where((e) => e.treinoId != null).toList();

    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.treinoContextoModelo(modelo.nome),
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
          if (sessoes.length > 1)
            FxChoiceStrip<int>(
              itens: [
                for (final e in sessoes)
                  FxChoiceItem(value: e.treinoId!, label: e.nome),
              ],
              selecionado: treinoId,
              onSelecionar: (id) {
                if (id == treinoId) return;
                context.pushReplacement(
                  '/treinos/$id',
                  extra: TreinoRouteExtra(modeloId: modeloId).toExtra(),
                );
              },
            ),
        ],
      ),
    );
  }
}
