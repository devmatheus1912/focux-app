import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_action_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../core/widgets/fx_sticky_actions.dart';
import '../../../core/widgets/fx_tap_row.dart';
import '../../../l10n/app_localizations.dart';
import '../models/ficha_modelo.dart';
import '../providers/ficha_modelos_provider.dart';
import 'ficha_acoes.dart';

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
              child: TextButton(
                onPressed: () => ref.invalidate(fichaModelosProvider),
                child: Text(s.modeloNaoAbriu),
              ),
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
          onPrimary: () => _novoModelo(context, ref),
        ),
      ],
    );
  }

  Future<void> _novoModelo(BuildContext context, WidgetRef ref) async {
    final s = S.of(context);
    final dias = await showFxActionSheet<int>(
      context,
      title: s.modelosQuantosDias,
      itens: [
        for (final n in const [2, 3, 4, 5, 6, 7])
          FxActionSheetItem(
            value: n,
            label: s.modeloNDias(n),
            icon: Icons.calendar_today_rounded,
          ),
      ],
    );
    if (dias == null || !context.mounted) return;
    final nome = await pedirTexto(
      context,
      titulo: s.rotinaModeloNomeTitulo,
      inicial: s.modeloNomeSugerido(dias),
    );
    if (nome == null || !context.mounted) return;
    try {
      final modelo = await ref
          .read(fichaModeloRepositoryProvider)
          .criarPorDias(nome: nome, diasPorSemana: dias);
      ref.invalidate(fichaModelosProvider);
      if (context.mounted) context.push('/modelos/${modelo.id}');
    } catch (_) {
      if (context.mounted) FeedbackHelper.showError(context, s.checkinNaoSalvou);
    }
  }
}

/// Um modelo na lista: nome, "A · B · C · D", contagens e o estado.
class FichaModeloCard extends StatelessWidget {
  const FichaModeloCard({super.key, required this.modelo});

  final FichaModelo modelo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final contagem = s.modeloContagem(modelo.sessoes.length, modelo.totalExercicios);
    final resumo = modelo.resumoDasSessoes;
    return FxTapRow(
      title: modelo.nome,
      subtitle: resumo.isEmpty ? contagem : '$resumo · $contagem',
      trailing: FxStatusPill(
        label: modelo.pronto ? s.modeloPronto : s.modeloEmMontagem,
        tone: modelo.pronto ? FxPillTone.success : FxPillTone.warning,
      ),
      onTap: () => context.push('/modelos/${modelo.id}'),
    );
  }
}
