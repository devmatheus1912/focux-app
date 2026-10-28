import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../models/exercicio_criado.dart';

/// Folha logo depois de criar: diz onde o exercício ficou e oferece o próximo
/// passo. Fechar a folha mantém o exercício onde está ("Meus exercícios").
Future<ExercicioCriadoDestino> showExercicioCriadoSheet(
  BuildContext context, {
  required String nome,
  required ExercicioOrigem origem,
}) async {
  final escolha = await showFxHomeSheet<ExercicioCriadoDestino>(
    context,
    builder: (_) => _ExercicioCriadoSheet(nome: nome, origem: origem),
  );
  return escolha ?? ExercicioCriadoDestino.ficar;
}

class _ExercicioCriadoSheet extends StatelessWidget {
  const _ExercicioCriadoSheet({required this.nome, required this.origem});

  final String nome;
  final ExercicioOrigem origem;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final (principal, destinoPrincipal) = switch (origem) {
      ExercicioOrigem.treino => (
        'Adicionar ao treino',
        ExercicioCriadoDestino.adicionarAoTreino,
      ),
      ExercicioOrigem.troca => (
        'Usar no lugar do atual',
        ExercicioCriadoDestino.usarNoLugar,
      ),
      ExercicioOrigem.biblioteca => (
        'Ver em Meus exercícios',
        ExercicioCriadoDestino.verEmMeus,
      ),
    };

    void escolher(ExercicioCriadoDestino d) =>
        FxHomeSheetChrome.dismissAndPop(context, d);

    return FxSheetFrame(
      title: 'Exercício criado',
      subtitle: nome,
      leading: Icon(Icons.check_circle_rounded, color: chrome.brand, size: 20),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxLiquidPrimaryButton(
            label: principal,
            onPressed: () => escolher(destinoPrincipal),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (origem != ExercicioOrigem.biblioteca)
                Flexible(
                  child: FxActionLink(
                    label: 'Ver em Meus exercícios',
                    onTap: () => escolher(ExercicioCriadoDestino.verEmMeus),
                  ),
                ),
              if (origem == ExercicioOrigem.biblioteca)
                Flexible(
                  child: FxActionLink(
                    label: 'Criar outro',
                    onTap: () => escolher(ExercicioCriadoDestino.criarOutro),
                  ),
                ),
            ],
          ),
        ],
      ),
      child: Text(
        'Ele está em Meus exercícios, na aba Treinos. O vídeo que você '
        'enviar fica só com você.',
        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
      ),
    );
  }
}
