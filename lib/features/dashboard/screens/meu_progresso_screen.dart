import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../l10n/pt.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../auth/providers/auth_provider.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../../evolucao/utils/evolucao_fotos_display.dart';
import '../../evolucao/widgets/evolucao_hero.dart';
import '../../evolucao/widgets/evolucao_medidas_aba.dart';
import '../../evolucao/widgets/evolucao_recordes_aba.dart';
import '../../evolucao/widgets/medida_form_sheet.dart';

final minhaEvolucaoProvider = FutureProvider.autoDispose<EvolucaoHomeBundle>(
  (ref) => EvolucaoRepository(ref.read(apiClientProvider)).minhaEvolucao(),
);

final minhasFotosProvider = FutureProvider.autoDispose<List<FotoEvolucao>>(
  (ref) async =>
      (await EvolucaoRepository(ref.read(apiClientProvider)).minhasFotos())
          .content,
);

/// Progresso do aluno: medidas, fotos e recordes.
class MeuProgressoScreen extends ConsumerStatefulWidget {
  const MeuProgressoScreen({super.key});

  @override
  ConsumerState<MeuProgressoScreen> createState() => _MeuProgressoScreenState();
}

class _MeuProgressoScreenState extends ConsumerState<MeuProgressoScreen> {
  String _aba = 'medidas';

  Future<void> _atualizar() async {
    ref.invalidate(minhaEvolucaoProvider);
    ref.invalidate(minhasFotosProvider);
    ref.invalidate(alunoPerfilHomeProvider);
    await ref.read(minhaEvolucaoProvider.future);
  }

  Future<void> _abrirMedida(MedidaCorporal medida) async {
    if (medida.registradoPor == 'PERSONAL') return;
    final repo = EvolucaoRepository(ref.read(apiClientProvider));
    final acao = await escolherAcaoDaMedida(context, podeEditar: true);
    if (acao == null || !mounted) return;
    try {
      if (acao == AcaoDaMedida.editar) {
        final novo = await editarMedidaSheet(context, medida);
        if (novo == null) return;
        await repo.editarMinhaMedida(
          medida,
          peso: novo.peso,
          cintura: novo.cintura,
          quadril: novo.quadril,
          braco: novo.braco,
        );
      } else {
        final ok = await showFxConfirmSheet(
          context,
          title: ptS.evolucaoExcluirTitulo,
          message: ptS.evolucaoExcluirMensagem,
          icon: Icons.delete_outline_rounded,
          confirmLabel: ptS.evolucaoExcluir,
          destructive: true,
        );
        if (!ok) return;
        await repo.excluirMinhaMedida(medida.id);
      }
      await _atualizar();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _excluirFoto(FotoEvolucao foto) async {
    if (foto.registradoPor != 'ALUNO') return;
    final ok = await showFxConfirmSheet(
      context,
      title: ptS.evolucaoExcluirFotoTitulo,
      message: ptS.evolucaoExcluirFotoMensagem,
      icon: Icons.delete_outline_rounded,
      confirmLabel: ptS.evolucaoExcluir,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await EvolucaoRepository(
        ref.read(apiClientProvider),
      ).excluirMinhaFoto(foto.id);
      ref.invalidate(minhasFotosProvider);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final evolucao = ref.watch(minhaEvolucaoProvider);
    return fxScreenA11yScope(
      label: ptS.meuProgressoTitulo,
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: ptS.meuProgressoTitulo,
          onBack: () => context.pop(),
        ),
        body: evolucao.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                child: SkeletonList(count: 4),
              ),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: chrome.isDark,
                primary: primary,
                message: friendlyError(e),
                title: ptS.meuProgressoErro,
                onRetry: () => ref.invalidate(minhaEvolucaoProvider),
              ),
          data:
              (dados) => FxContentWidthLimiter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        TokensStrip.s4,
                        FxSettingsLayout.pageInset,
                        TokensStrip.s2,
                      ),
                      child: Column(
                        children: [
                          EvolucaoHero(medidas: dados.medidas),
                          const SizedBox(height: TokensStrip.s4),
                          AlunoSegmentedChoice(
                            options: [
                              (value: 'medidas', label: ptS.meuProgressoMedidas),
                              (value: 'fotos', label: ptS.meuProgressoFotos),
                              (value: 'recordes', label: ptS.meuProgressoRecordes),
                            ],
                            selected: _aba,
                            isDark: chrome.isDark,
                            onSelect: (v) => setState(() => _aba = v),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: switch (_aba) {
                        'fotos' => _Fotos(onExcluir: _excluirFoto),
                        'recordes' => EvolucaoRecordesAba(
                          recordes: dados.recordes,
                          vazioSubtitulo: ptS.meuProgressoSemRecorde,
                          onAtualizar: _atualizar,
                        ),
                        _ => EvolucaoMedidasAba(
                          medidas: dados.medidas,
                          vazioSubtitulo: ptS.meuProgressoSemMedida,
                          onAtualizar: _atualizar,
                          onAbrirMedida: _abrirMedida,
                        ),
                      },
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}

class _Fotos extends ConsumerWidget {
  const _Fotos({required this.onExcluir});

  final ValueChanged<FotoEvolucao> onExcluir;

  void _ampliar(BuildContext context, FotoEvolucao foto) => showDialog<void>(
    context: context,
    builder:
        (ctx) => GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Center(
            child: FxCachedNetworkImage(imageUrl: foto.url, fit: BoxFit.contain),
          ),
        ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return ref
        .watch(minhasFotosProvider)
        .when(
          loading:
              () => const Padding(
                padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                child: SkeletonList(count: 3),
              ),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: chrome.isDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(minhasFotosProvider),
              ),
          data:
              (fotos) =>
                  fotos.isEmpty
                      ? ListView(
                        children: [
                          FxEmptyState(
                            icon: 'spark',
                            title: ptS.meuProgressoSemFotoTitulo,
                            subtitle: ptS.meuProgressoSemFoto,
                          ),
                        ],
                      )
                      : GridView.builder(
                        padding: const EdgeInsets.all(
                          FxSettingsLayout.pageInset,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: TokensStrip.s2,
                              crossAxisSpacing: TokensStrip.s2,
                              childAspectRatio: 0.75,
                            ),
                        itemCount: fotos.length,
                        itemBuilder: (context, i) {
                          final foto = fotos[i];
                          return Semantics(
                            button: true,
                            label: evolucaoFotosDateLabel(foto.data),
                            excludeSemantics: true,
                            child: GestureDetector(
                              onTap: () => _ampliar(context, foto),
                              onLongPress: () => onExcluir(foto),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  TokensStrip.rCard,
                                ),
                                child: FxCachedNetworkImage(
                                  imageUrl: foto.url,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 480,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
        );
  }
}
