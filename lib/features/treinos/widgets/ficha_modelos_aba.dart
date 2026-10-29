import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../core/widgets/fx_sticky_actions.dart';
import '../../../core/widgets/fx_tap_row.dart';
import '../../../l10n/app_localizations.dart';
import '../models/ficha_modelo.dart';
import '../providers/ficha_modelos_provider.dart';
import 'ficha_acoes.dart';
import 'modelo_acoes.dart';
import '../../../core/widgets/fx_tonal_button.dart';

/// Aba "Semanas" de Modelos de treino: um card por modelo e "Novo modelo".
/// [abas] é a fileira Semanas | Sessões, que o dono da tela desenha.
class FichaModelosAba extends ConsumerWidget {
  const FichaModelosAba({super.key, required this.abas});

  final Widget abas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final modelos = ref.watch(fichaModelosProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(TokensStrip.s4, TokensStrip.s2, TokensStrip.s4, 0),
          child: abas,
        ),
        Expanded(
          child: modelos.when(
            loading: () => const Center(child: FxLoading()),
            error: (_, __) => Center(
              child: FxTonalButton(label: s.modeloNaoAbriu, onPressed: () => ref.invalidate(fichaModelosProvider), compact: true),
            ),
            data: (lista) => lista.isEmpty
                ? Center(
                    child: FxEmptyState(
                      icon: 'dumbbell',
                      title: s.modelosVazioTitulo,
                      subtitle: s.modelosVazioSubtitulo,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.refresh(fichaModelosProvider.future),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(TokensStrip.s4),
                      itemCount: lista.length,
                      separatorBuilder: (_, __) => const SizedBox(height: TokensStrip.s2),
                      itemBuilder: (context, i) => FichaModeloCard(modelo: lista[i]),
                    ),
                  ),
          ),
        ),
        FxStickyActions(
          primaryLabel: s.modelosNovo,
          onPrimary: () => criarNovoModelo(context, ref),
        ),
      ],
    );
  }
}

/// Um modelo na lista: nome, "A · B · C · D", contagens, o estado e o "…".
class FichaModeloCard extends ConsumerWidget {
  const FichaModeloCard({super.key, required this.modelo});

  final FichaModelo modelo;

  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    final acao = await mostrarMenuDoModelo(context, nome: modelo.nome, comRecomecar: false);
    if (acao == null || !context.mounted) return;
    switch (acao) {
      case ModeloAcao.aplicar:
        await aplicarModeloEmAluno(context, ref, modelo);
      case ModeloAcao.renomear:
        await renomearModelo(context, ref, modelo);
      case ModeloAcao.excluir:
        await excluirModelo(context, ref, modelo);
      case ModeloAcao.recomecar:
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final contagem = s.modeloContagem(modelo.sessoes.length, modelo.totalExercicios);
    final resumo = modelo.resumoDasSessoes;
    return FxTapRow(
      title: modelo.nome,
      subtitle: resumo.isEmpty ? contagem : '$resumo · $contagem',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FxStatusPill(
            label: modelo.pronto ? s.modeloPronto : s.modeloEmMontagem,
            tone: modelo.pronto ? FxPillTone.success : FxPillTone.warning,
          ),
          IconButton(
            tooltip: s.rotinaMenuFicha,
            onPressed: () => _menu(context, ref),
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      onTap: () => context.push('/modelos/${modelo.id}'),
    );
  }
}
