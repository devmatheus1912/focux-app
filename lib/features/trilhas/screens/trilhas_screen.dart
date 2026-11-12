import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../models/trilha.dart';
import '../providers/trilhas_provider.dart';
import '../utils/trilhas_display.dart';
import '../widgets/trilha_cartao.dart';
import '../widgets/trilha_detalhe_sheet.dart';
import '../widgets/trilha_form_sheet.dart';
import '../widgets/trilhas_help_sheet.dart';

/// Trilhas do aluno, lado do personal: lista, "Nova trilha" e o detalhe
/// (mesmo cartão e mesma folha do aluno).
class TrilhasScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;

  const TrilhasScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  ConsumerState<TrilhasScreen> createState() => _TrilhasScreenState();
}

class _TrilhasScreenState extends ConsumerState<TrilhasScreen> {
  DateTime? _fetchedAt;
  final _mais = <TrilhaModel>[];
  var _nextPage = 1;
  var _hasMore = false;
  var _loadingMore = false;

  String get _primeiroNome => satelliteFirstName(widget.alunoNome);

  Future<void> _refresh() async {
    _mais.clear();
    _nextPage = 1;
    _hasMore = false;
    ref.invalidate(trilhasAlunoProvider(widget.alunoId));
    try {
      final lista = await ref.read(trilhasAlunoProvider(widget.alunoId).future);
      if (mounted) {
        setState(() {
          _fetchedAt = DateTime.now();
          _hasMore = lista.hasMore;
        });
      }
    } catch (_) {}
  }

  Future<void> _carregarMais() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await ref
          .read(trilhasRepositoryProvider)
          .listarPorAluno(widget.alunoId, page: _nextPage);
      if (!mounted) return;
      setState(() {
        _mais.addAll(next.items);
        _nextPage += 1;
        _hasMore = next.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMore = false);
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  void _stampFreshness() {
    if (_fetchedAt != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _fetchedAt != null) return;
      setState(() => _fetchedAt = DateTime.now());
    });
  }

  Future<void> _novaTrilha() async {
    HapticFeedback.selectionClick();
    final f = await showTrilhaFormSheet(context);
    if (f == null || !mounted) return;
    try {
      await ref
          .read(trilhasRepositoryProvider)
          .criarTrilha(
            NovaTrilhaRequest(
              alunoId: widget.alunoId,
              titulo: f.titulo,
              descricao: f.descricao,
              dataFim: f.dataFim,
              marcos: f.etapas,
            ),
          );
      if (!mounted) return;
      FeedbackHelper.showSuccess(
        context,
        'Trilha criada. $_primeiroNome recebe um aviso.',
      );
      await _refresh();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _abrir(TrilhaModel trilha) async {
    final saida = await showTrilhaDetalhe(
      context,
      trilha: trilha,
      doPersonal: true,
      onMudou: (_) => ref.invalidate(trilhasAlunoProvider(widget.alunoId)),
    );
    if (!mounted) return;
    switch (saida) {
      case TrilhaDetalheSaida.editar:
        await _editar(trilha);
      case TrilhaDetalheSaida.excluir:
        await _excluir(trilha);
      case null:
        break;
    }
  }

  Future<void> _editar(TrilhaModel trilha) async {
    final f = await showTrilhaFormSheet(context, editar: trilha);
    if (f == null || !mounted) return;
    try {
      await ref
          .read(trilhasRepositoryProvider)
          .editar(
            trilhaId: trilha.id,
            titulo: f.titulo,
            descricao: f.descricao,
            dataFim: f.dataFim,
          );
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Trilha atualizada.');
      await _refresh();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _excluir(TrilhaModel trilha) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Excluir trilha?',
      subtitle: trilha.titulo,
      message: 'Some para você e para o $_primeiroNome, com as etapas.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(trilhasRepositoryProvider).deletar(trilha.id);
      if (mounted) FeedbackHelper.showSuccess(context, 'Trilha excluída.');
      await _refresh();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final trilhasAsync = ref.watch(trilhasAlunoProvider(widget.alunoId));
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final showSticky = !trilhasAsync.isLoading && !trilhasAsync.hasError;

    return fxScreenA11yScope(
      label: 'Trilhas — ${widget.alunoNome}',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          safePopOrGo(context, '/alunos/${widget.alunoId}');
        },
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Trilhas',
            subtitle: FxHubFreshness.joinCount(_primeiroNome, freshness),
            onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar as trilhas',
                onTap: () => showTrilhasHelpSheet(context),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: trilhasAsync.when(
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
                        onRetry: _refresh,
                        title: 'Não conseguimos carregar as trilhas',
                      ),
                  data: (lista) {
                    _stampFreshness();
                    final merged = lista.append(
                      TrilhaLista(
                        items: _mais,
                        hasMore: _mais.isEmpty ? lista.hasMore : _hasMore,
                      ),
                    );
                    return FxContentWidthLimiter(
                      child: TrilhasLista(
                        semAndamento:
                            'Nenhuma trilha em andamento. Comece outra com Nova trilha.',
                        lista: merged,
                        vazio: FxEmptyState(
                          icon: FxIcons.rota,
                          title: 'Nenhuma trilha do $_primeiroNome',
                          subtitle:
                              'Monte um caminho em etapas até uma conquista: a primeira barra fixa, correr 5 km, agachar com técnica. O $_primeiroNome marca cada etapa quando conseguir.',
                        ),
                        loadingMore: _loadingMore,
                        onRefresh: _refresh,
                        onCarregarMais: _carregarMais,
                        onAbrir: _abrir,
                      ),
                    );
                  },
                ),
              ),
              if (showSticky)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s2,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s3,
                    ),
                    child: FxLiquidPrimaryButton(
                      label: 'Nova trilha',
                      onPressed: _novaTrilha,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista comum (personal e aluno): "Em andamento" e "Concluídas · N" fechado.
class TrilhasLista extends StatelessWidget {
  const TrilhasLista({
    super.key,
    this.semAndamento = 'Nenhuma trilha em andamento agora.',
    required this.lista,
    required this.vazio,
    required this.onRefresh,
    required this.onAbrir,
    this.loadingMore = false,
    this.onCarregarMais,
  });

  final TrilhaLista lista;
  final Widget vazio;
  final Future<void> Function() onRefresh;
  final ValueChanged<TrilhaModel> onAbrir;
  final bool loadingMore;
  final VoidCallback? onCarregarMais;

  /// Linha quieta quando não há trilha em andamento (só concluídas).
  final String semAndamento;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final grupos = trilhaGrupos(lista.items);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s3,
          FxSettingsLayout.pageInset,
          TokensStrip.s6,
        ),
        children: [
          if (lista.items.isEmpty)
            vazio
          else ...[
            if (grupos.andamento.isNotEmpty) ...[
              Text('Em andamento', style: FocuxHubTypography.chip(chrome.mute)),
              const SizedBox(height: TokensStrip.s2),
              for (final t in grupos.andamento)
                TrilhaCartao(trilha: t, onTap: () => onAbrir(t)),
            ],
            // Só concluídas: diz por que só aparece o histórico.
            if (grupos.andamento.isEmpty) ...[
              Text(
                semAndamento,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              const SizedBox(height: TokensStrip.s3),
            ],
            if (grupos.concluidas.isNotEmpty)
              _Concluidas(
                trilhas: grupos.concluidas,
                abertaNoInicio: grupos.andamento.isEmpty,
                onAbrir: onAbrir,
              ),
            if (lista.hasMore && onCarregarMais != null)
              Align(
                child: FxTonalButton(
                  label: loadingMore ? 'Carregando…' : 'Carregar mais',
                  compact: true,
                  onPressed: loadingMore ? null : onCarregarMais,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// "Concluídas · N": rótulo no mesmo estilo do "Em andamento", seta à direita.
class _Concluidas extends StatefulWidget {
  const _Concluidas({
    required this.trilhas,
    required this.abertaNoInicio,
    required this.onAbrir,
  });

  final List<TrilhaModel> trilhas;
  final bool abertaNoInicio;
  final ValueChanged<TrilhaModel> onAbrir;

  @override
  State<_Concluidas> createState() => _ConcluidasState();
}

class _ConcluidasState extends State<_Concluidas> {
  late var _aberta = widget.abertaNoInicio;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _aberta,
          child: InkWell(
            borderRadius: BorderRadius.circular(TokensStrip.rSm),
            onTap: () => setState(() => _aberta = !_aberta),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Concluídas · ${widget.trilhas.length}',
                      style: FocuxHubTypography.chip(chrome.mute),
                    ),
                  ),
                  Icon(
                    _aberta ? FxIcons.chevronCima : FxIcons.chevronBaixo,
                    size: 18,
                    color: chrome.mute,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_aberta)
          for (final t in widget.trilhas)
            TrilhaCartao(trilha: t, onTap: () => widget.onAbrir(t)),
      ],
    );
  }
}
