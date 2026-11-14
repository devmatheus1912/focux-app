import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../widgets/desafio_editar_sheet.dart';
import '../widgets/desafio_linhas.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/desafio_repository.dart';
import '../utils/desafio_display.dart';
import '../../../core/theme/fx_icons.dart';

class DesafioDetailScreen extends ConsumerStatefulWidget {
  const DesafioDetailScreen({
    super.key,
    required this.desafioId,
    this.desafio,
    this.forAluno = false,
  });

  final int desafioId;
  final Desafio? desafio;
  final bool forAluno;

  @override
  ConsumerState<DesafioDetailScreen> createState() =>
      _DesafioDetailScreenState();
}

class _DesafioDetailScreenState extends ConsumerState<DesafioDetailScreen> {
  Desafio? _desafio;
  List<DesafioLeaderboardEntry> _ranking = [];
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  var _encerrando = false;

  String get _parent => widget.forAluno ? '/aluno/desafios' : '/desafios';

  @override
  void initState() {
    super.initState();
    _desafio = widget.desafio;
    _load();
  }

  void _leave() => safePopOrGo(context, _parent);

  DesafioRepository get _repo => DesafioRepository(ref.read(apiClientProvider));

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      if (widget.forAluno) {
        await _repo.participar(widget.desafioId);
      }
      final found = await _repo.buscar(widget.desafioId);
      final ranking =
          found.ranking ?? await _repo.leaderboard(widget.desafioId);
      if (!mounted) return;
      setState(() {
        _desafio = found;
        _ranking = ranking;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  /// Editar e Encerrar agora no ativo; Excluir (por último, em vermelho)
  /// só enquanto ninguém contou. Cada ação tem a própria confirmação.
  Future<void> _maisOpcoes() async {
    final desafio = _desafio;
    if (desafio == null || _encerrando) return;
    final acoes = desafioMenuAcoes(
      ativo: desafio.ativo,
      podeExcluir: desafio.podeExcluir,
    );
    if (acoes.isEmpty) return;
    final acao = await showFxGroupedActionSheet<String>(
      context,
      titulo: desafio.titulo,
      grupos: [
        if (desafio.ativo)
          const FxActionGroup('Desafio', [
            FxActionItem(
              valor: 'editar',
              rotulo: 'Editar',
              icone: FxIcons.editar,
              descricao: 'Nome, meta e data final.',
            ),
            FxActionItem(
              valor: 'encerrar',
              rotulo: 'Encerrar agora',
              icone: FxIcons.fechar,
              descricao: 'O ranking para de contar.',
            ),
          ]),
      ],
      destrutiva:
          acoes.contains('excluir')
              ? const FxActionItem(
                valor: 'excluir',
                rotulo: 'Excluir',
                icone: FxIcons.excluir,
              )
              : null,
      confirmar: false,
    );
    if (!mounted) return;
    switch (acao) {
      case 'editar':
        final salvou = await showDesafioEditarSheet(
          context,
          desafio: desafio,
          repo: _repo,
        );
        if (!mounted || !salvou) return;
        FeedbackHelper.showSuccess(context, 'Desafio salvo');
        await _load();
      case 'encerrar':
        final ok = await showFxConfirmSheet(
          context,
          title: 'Encerrar o desafio?',
          message: 'O ranking para de contar e o desafio sai da lista.',
          confirmLabel: 'Encerrar',
          destructive: true,
        );
        if (ok) {
          await _executar(
            () => _repo.encerrar(desafio.id),
            'Desafio encerrado',
          );
        }
      case 'excluir':
        final ok = await showFxConfirmSheet(
          context,
          title: 'Excluir ${desafio.titulo}?',
          message:
              'Ninguém contou ainda. O desafio some da lista dos alunos. Não dá para desfazer.',
          confirmLabel: 'Excluir',
          destructive: true,
        );
        if (ok) {
          await _executar(() => _repo.excluir(desafio.id), 'Desafio excluído');
        }
    }
  }

  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    if (!mounted) return;
    setState(() => _encerrando = true);
    try {
      await acao();
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, sucesso);
      _leave();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _encerrando = false);
    }
  }

  void _alunoSticky() {
    final tipo = _desafio?.tipo ?? 'HABITOS';
    context.push(desafioStickyAlunoPath(tipo));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final desafio = _desafio;
    final titulo = desafio?.titulo ?? 'Desafio';
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final meId = widget.forAluno ? ref.watch(alunoMeProvider).value?.id : null;

    return fxScreenA11yScope(
      label: titulo,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _leave();
        },
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Desafio',
            subtitle: freshness,
            onBack: _leave,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar este desafio',
                onTap:
                    () => showFxHelpSheet(
                      context,
                      title: 'Desafio',
                      subtitle:
                          'Uma disputa com prazo: quem fizer mais sobe no ranking.',
                      tips: [
                        FxHelpTip(
                          'O que conta',
                          desafioRegraFrase(desafio?.tipo ?? 'TREINOS'),
                        ),
                        FxHelpTip(
                          widget.forAluno
                              ? 'Subir no ranking'
                              : 'Editar, encerrar ou excluir',
                          widget.forAluno
                              ? 'O botão leva ao treino ou ao hábito que conta.'
                              : 'No ⋯ do topo. Excluir só enquanto ninguém contou.',
                        ),
                      ],
                    ),
              ),
              if (!widget.forAluno &&
                  desafio != null &&
                  desafioMenuAcoes(
                    ativo: desafio.ativo,
                    podeExcluir: desafio.podeExcluir,
                  ).isNotEmpty)
                IconButton(
                  tooltip: 'Mais opções',
                  onPressed: _encerrando ? null : _maisOpcoes,
                  icon: const Icon(FxIcons.mais),
                ),
            ],
          ),
          body:
              _loading && desafio == null
                  ? const Padding(
                    padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                    child: SkeletonList(count: 5),
                  )
                  : _erro != null && desafio == null
                  ? FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    title: 'Não conseguimos carregar o desafio',
                    message: _erro!,
                    onRetry: _load,
                  )
                  : desafio == null
                  ? FxEmptyState(
                    icon: FxIcons.ia,
                    title: 'Desafio não encontrado',
                    subtitle:
                        'Ele pode ter sido encerrado. Volte à lista e escolha outro.',
                    action: FxEmptyAction(label: 'Voltar', onTap: _leave),
                  )
                  : _DesafioDetailBody(
                    desafio: desafio,
                    ranking: _ranking,
                    forAluno: widget.forAluno,
                    meId: meId,
                    onRefresh: _load,
                    onAlunoSticky: _alunoSticky,
                  ),
        ),
      ),
    );
  }
}

class _DesafioDetailBody extends StatelessWidget {
  const _DesafioDetailBody({
    required this.desafio,
    required this.ranking,
    required this.forAluno,
    required this.meId,
    required this.onRefresh,
    required this.onAlunoSticky,
  });

  final Desafio desafio;
  final List<DesafioLeaderboardEntry> ranking;
  final bool forAluno;
  final int? meId;
  final Future<void> Function() onRefresh;
  final VoidCallback onAlunoSticky;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final sobre = fxPaletaSobreMarca(context, accent: primary);
    final descricao = desafio.descricao?.trim();
    final meuIndex = desafioMeuIndex(ranking.map((e) => e.alunoId), meId);
    final minhaContagem = meuIndex == null ? 0 : ranking[meuIndex].pontos;
    final ninguemContou = ranking.every((e) => e.pontos <= 0);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: primary,
            onRefresh: onRefresh,
            child: FxContentWidthLimiter(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s4,
                  FxSettingsLayout.pageInset,
                  TokensStrip.s6,
                ),
                children: [
                  FxStripCard(
                    marca: true,
                    accent: primary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          desafio.titulo,
                          style: FocuxHubTypography.cardTitle(color: sobre.ink),
                        ),
                        const SizedBox(height: TokensStrip.s1),
                        Text(
                          desafioRegraDetalhe(desafio),
                          style: FocuxHubTypography.bodyMuted(
                            color: sobre.mute,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s2),
                        Text(
                          desafio.ativo
                              ? desafioFaltamTitulo(desafio.fim)
                              : 'Encerrado',
                          style: FocuxHubTypography.rotulo(color: sobre.ink),
                        ),
                        if (forAluno) ...[
                          const SizedBox(height: TokensStrip.s3),
                          Text(
                            desafioMeuResumo(
                              tipo: desafio.tipo,
                              index: meuIndex,
                              contagem: minhaContagem,
                              meta: desafio.metaPontos,
                            ),
                            style: FocuxHubTypography.body(color: sobre.ink),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (descricao != null && descricao.isNotEmpty) ...[
                    const SizedBox(height: TokensStrip.s3),
                    Text(
                      descricao,
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                  ],
                  const SizedBox(height: TokensStrip.s5),
                  const DashboardSectionHeader(title: 'Ranking'),
                  const SizedBox(height: TokensStrip.s2),
                  if (ranking.isEmpty || ninguemContou)
                    Padding(
                      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
                      child: Text(
                        '${desafioRegraFrase(desafio.tipo)} Quando alguém contar o primeiro, o ranking começa.',
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                    ),
                  for (var i = 0; i < ranking.length; i++)
                    DesafioLinhaRanking(
                      posicao: i,
                      entrada: ranking[i],
                      meta: desafio.metaPontos,
                      voce:
                          forAluno &&
                          meId != null &&
                          ranking[i].alunoId == meId,
                      onTap:
                          forAluno || ranking[i].alunoId <= 0
                              ? null
                              : () =>
                                  context.push('/alunos/${ranking[i].alunoId}'),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (forAluno && desafio.ativo)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
                FxSettingsLayout.pageInset,
                TokensStrip.s3,
              ),
              child: FxLiquidPrimaryButton(
                label: desafioStickyAlunoLabel(desafio.tipo),
                onPressed: onAlunoSticky,
              ),
            ),
          ),
      ],
    );
  }
}
