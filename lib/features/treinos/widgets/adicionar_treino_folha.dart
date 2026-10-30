import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_sheet.dart';
import '../../../core/widgets/fx_bottom_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_sheet_search_field.dart';
import '../../../core/widgets/fx_tap_row.dart';
import '../../../l10n/app_localizations.dart';
import '../models/ficha_modelo.dart';
import '../providers/ficha_modelos_provider.dart';
import 'ficha_acoes.dart';

/// O que entra num dia: uma sessão nova (só o nome) ou a cópia de uma sessão de um modelo.
sealed class EscolhaDeSessao {
  const EscolhaDeSessao();
}

class SessaoNova extends EscolhaDeSessao {
  const SessaoNova(this.nome);
  final String nome;
}

class CopiaDeSessao extends EscolhaDeSessao {
  const CopiaDeSessao(this.treinoId, this.exerciciosCount);
  final int treinoId;
  final int exerciciosCount;
}

enum _Origem { nova, copiar }

/// "Adicionar treino" de um dia: Sessão nova ou Copiar de um modelo.
/// Quem grava é o editor da semana; a folha só escolhe.
Future<EscolhaDeSessao?> escolherSessaoParaODia(BuildContext context) async {
  final s = S.of(context);
  final origem = await showFxActionSheet<_Origem>(
    context,
    title: s.rotinaAdicionarTreino,
    itens: [
      FxActionSheetItem(value: _Origem.nova, label: s.adicionarSessaoNova, icon: Icons.add_rounded),
      FxActionSheetItem(
        value: _Origem.copiar,
        label: s.adicionarCopiarDeModelo,
        icon: Icons.copy_all_rounded,
      ),
    ],
  );
  if (origem == null || !context.mounted) return null;
  switch (origem) {
    case _Origem.nova:
      final nome = await pedirNomeDaSessao(context);
      return nome == null ? null : SessaoNova(nome);
    case _Origem.copiar:
      return showFxBottomSheet<CopiaDeSessao>(
        context: context,
        builder: (_) => const _CopiarDeModeloFolha(),
      );
  }
}

class _CopiarDeModeloFolha extends ConsumerStatefulWidget {
  const _CopiarDeModeloFolha();

  @override
  ConsumerState<_CopiarDeModeloFolha> createState() => _CopiarDeModeloFolhaState();
}

class _CopiarDeModeloFolhaState extends ConsumerState<_CopiarDeModeloFolha> {
  var _busca = '';
  FichaModelo? _modelo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final modelo = _modelo;
    return FxSheetFrame(
      title: modelo?.nome ?? s.adicionarCopiarDeModelo,
      subtitle: modelo == null ? s.adicionarEscolhaModelo : s.adicionarEscolhaSessao,
      expand: true,
      child: modelo == null ? _modelos(s, chrome) : _sessoes(s, modelo),
    );
  }

  Widget _modelos(S s, ShellPalette chrome) {
    final async = ref.watch(fichaModelosProvider);
    return async.when(
      loading: () => const Center(child: FxLoading()),
      error: (_, __) => Center(child: Text(s.modeloNaoAbriu)),
      data: (lista) {
        final alvo = _busca.trim().toLowerCase();
        final visiveis = [
          for (final m in lista)
            if (m.sessoes.isNotEmpty && (alvo.isEmpty || m.nome.toLowerCase().contains(alvo))) m,
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FxSheetSearchField(
              dica: s.adicionarBuscarModelo,
              onChanged: (texto) => setState(() => _busca = texto),
            ),
            const SizedBox(height: TokensStrip.s2),
            if (visiveis.isEmpty)
              Padding(
                padding: const EdgeInsets.all(TokensStrip.s3),
                child: Text(s.adicionarSemModelos, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
              ),
            for (final m in visiveis) ...[
              FxTapRow(
                title: m.nome,
                subtitle: s.modeloContagem(m.sessoes.length, m.totalExercicios),
                onTap: () => setState(() => _modelo = m),
              ),
              const SizedBox(height: TokensStrip.s1),
            ],
          ],
        );
      },
    );
  }

  Widget _sessoes(S s, FichaModelo modelo) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final sessao in modelo.sessoes)
        if (sessao.treinoId != null) ...[
          FxTapRow(
            title: sessao.nome,
            subtitle: s.rotinaSessaoExercicios(sessao.exerciciosCount),
            onTap: () => Navigator.pop(
              context,
              CopiaDeSessao(sessao.treinoId!, sessao.exerciciosCount),
            ),
          ),
          const SizedBox(height: TokensStrip.s1),
        ],
    ],
  );
}
