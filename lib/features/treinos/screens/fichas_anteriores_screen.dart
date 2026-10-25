import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_tap_row.dart';
import '../../../l10n/app_localizations.dart';
import '../models/ficha_historico.dart';
import '../providers/ficha_historico_provider.dart';
import '../utils/ficha_historico_textos.dart';
import '../widgets/ficha_help_sheets.dart';

/// Fichas que o aluno já teve, da mais recente para a mais antiga.
class FichasAnterioresScreen extends ConsumerStatefulWidget {
  const FichasAnterioresScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  final int alunoId;
  final String alunoNome;

  @override
  ConsumerState<FichasAnterioresScreen> createState() => _FichasAnterioresScreenState();
}

class _FichasAnterioresScreenState extends ConsumerState<FichasAnterioresScreen> {
  var _medido = false;

  void _medir(List<FichaHistorico> lista) {
    if (_medido) return;
    _medido = true;
    AnalyticsService.instance.track(
      ProductEvents.fichaHistoricoAberto,
      props: {'fichas': lista.length},
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final async = ref.watch(fichasAnterioresProvider(widget.alunoId));
    ref.listen(fichasAnterioresProvider(widget.alunoId), (_, proximo) {
      final lista = proximo.asData?.value;
      if (lista != null) _medir(lista);
    });

    return fxScreenA11yScope(
      label: s.fichasAnterioresTitulo,
      child: FxShellScaffold(
        appBar: FxShellAppBar(
          title: s.fichasAnterioresTitulo,
          actions: [
            FxHelpIconButton(
              tooltip: 'Sobre as fichas anteriores',
              onTap: () => showFichasAnterioresHelpSheet(context),
            ),
          ],
        ),
        body: async.when(
          loading: () => const Center(child: FxLoading()),
          error: (_, __) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(fichasAnterioresProvider(widget.alunoId)),
              child: Text(s.historicoNaoAbriu),
            ),
          ),
          data: (lista) => lista.isEmpty
              ? Center(
                  child: FxEmptyState(
                    icon: 'dumbbell',
                    title: s.fichasAnterioresVazioTitulo,
                    subtitle: s.fichasAnterioresVazioSubtitulo,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => ref.refresh(fichasAnterioresProvider(widget.alunoId).future),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(TokensStrip.s4),
                    itemCount: lista.length,
                    separatorBuilder: (_, __) => const SizedBox(height: TokensStrip.s2),
                    itemBuilder: (context, i) => FichaAnteriorCard(
                      ficha: lista[i],
                      onTap: () => context.push(
                        '/alunos/${widget.alunoId}/fichas-anteriores/${lista[i].id}',
                        extra: widget.alunoNome,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Uma ficha na lista: o período, por que saiu e quanto tinha.
class FichaAnteriorCard extends StatelessWidget {
  const FichaAnteriorCard({super.key, required this.ficha, required this.onTap});

  final FichaHistorico ficha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final contagem = s.modeloContagem(ficha.sessoes, ficha.exercicios);
    return FxTapRow(
      title: periodoDaFicha(s, ficha),
      subtitle: '${motivoDaFicha(s, ficha)}\n$contagem',
      leading: Icon(Icons.history_rounded, color: chrome.mute),
      onTap: onTap,
    );
  }
}
