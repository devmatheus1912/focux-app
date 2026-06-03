import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/env.dart';
import '../../../core/router/safe_navigation.dart';
import '../data/aluno_contact_utils.dart';
import '../data/aluno_followup_store.dart';
import '../data/aluno_list_preferences_store.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_followup_provider.dart';
import '../providers/alunos_provider.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_premium_entrance.dart';

enum AlunoFiltro { todos, contatoHoje, ativos, inadimplentes, risco, novos }

enum AlunoOrdenacao { prioridade, nome, semFoto }

String _alunosSelectionTitle(int count) =>
    count == 1 ? '1 aluno selecionado' : '$count alunos selecionados';

String _mensalidadesPagasMessage(int count) =>
    count == 1
        ? '1 mensalidade marcada como paga'
        : '$count mensalidades marcadas como pagas';

String _alunosAtualizadosMessage(int count) =>
    count == 1 ? '1 aluno atualizado' : '$count alunos atualizados';

/// Texto secundário da lista — contraste WCAG AA em fundos de card.
Color _alunoListSecondaryInk(bool isDark) =>
    isDark ? const Color(0xFF9AA8B4) : const Color(0xFF4B5563);

/// Badge «Risco alto» — cores calibradas para leitura em 10px.
(Color, Color) _riscoAltoBadgeColors(bool isDark) => isDark
    ? (const Color(0xFFFFB088), const Color(0xFF3D2A18))
    : (const Color(0xFF8A4F00), const Color(0xFFFFE8CC));

/// Fade na borda direita para indicar scroll horizontal nos filtros.
class _HorizontalScrollPeek extends StatelessWidget {
  const _HorizontalScrollPeek({
    required this.child,
    required this.showPeek,
  });

  final Widget child;
  final bool showPeek;

  @override
  Widget build(BuildContext context) {
    if (!showPeek) return child;

    final base = Theme.of(context).scaffoldBackgroundColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Semantics(
          label: 'Deslize horizontalmente para ver mais filtros',
          child: child,
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    base.withValues(alpha: 0),
                    base.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AlunosListScreen extends ConsumerStatefulWidget {
  final AlunoFiltro initialFiltro;

  const AlunosListScreen({super.key, this.initialFiltro = AlunoFiltro.todos});

  @override
  ConsumerState<AlunosListScreen> createState() => _AlunosListScreenState();
}

class _AlunosListScreenState extends ConsumerState<AlunosListScreen> {
  AlunoFiltro _filtro = AlunoFiltro.todos;
  AlunoOrdenacao _ordenacao = AlunoOrdenacao.prioridade;
  bool _modoSelecao = false;
  final Set<int> _selecionados = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';
  bool _ignoredDeepLinkFiltro = false;
  bool _listaCompacta = false;

  @override
  void initState() {
    super.initState();
    _filtro = widget.initialFiltro;
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _loadListPreferences();
  }

  Future<void> _loadListPreferences() async {
    final prefs = await AlunoListPreferencesStore.load();
    if (mounted) setState(() => _listaCompacta = prefs.compact);
  }

  @override
  void didUpdateWidget(covariant AlunosListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFiltro != widget.initialFiltro) {
      setState(() {
        _filtro = widget.initialFiltro;
        _ignoredDeepLinkFiltro = false;
      });
    }
  }

  bool _hasDeepLinkFiltro(BuildContext context) {
    if (_ignoredDeepLinkFiltro) return false;
    return GoRouterState.of(context).uri.queryParameters.containsKey('filtro') ||
        widget.initialFiltro != AlunoFiltro.todos;
  }

  void _handleHeaderBack() {
    HapticFeedback.selectionClick();
    final fromDashboard = _hasDeepLinkFiltro(context);

    setState(() {
      _filtro = AlunoFiltro.todos;
      _ignoredDeepLinkFiltro = true;
    });

    if (!fromDashboard) return;

    safePopOrGo(context, '/dashboard/personal');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleModoSelecao() {
    HapticFeedback.mediumImpact();
    setState(() {
      _modoSelecao = !_modoSelecao;
      _selecionados.clear();
    });
  }

  Future<void> _adicionarAluno() async {
    HapticFeedback.selectionClick();
    final criado = await context.push<bool>('/alunos/novo');
    if (criado == true) {
      ref.invalidate(alunosProvider);
    }
  }

  void _toggleSelecionado(int id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selecionados.contains(id)) {
        _selecionados.remove(id);
      } else {
        _selecionados.add(id);
      }
    });
  }

  Future<void> _excluirSelecionados() async {
    final total = _selecionados.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmar = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder: (_) => _ExcluirAlunosSheet(count: total, isDark: isDark),
    );
    if (confirmar != true) return;

    final repo = AlunoRepository(ref.read(apiClientProvider));
    int sucesso = 0;
    for (final id in List<int>.from(_selecionados)) {
      try {
        await repo.excluirAluno(id);
        sucesso++;
      } catch (e) {
        debugPrint('[Focux] Error excluir aluno $id: $e');
      }
    }
    if (mounted) {
      ref.invalidate(alunosProvider);
      FeedbackHelper.showSuccess(context, _deletedMessage(sucesso));
      setState(() {
        _modoSelecao = false;
        _selecionados.clear();
      });
    }
  }

  Future<void> _marcarPagosSelecionados() async {
    if (_selecionados.isEmpty) return;
    try {
      await ref.read(apiClientProvider).dio.post(
        '/api/financeiro/mensalidades/lote-pago',
        data: {'alunoIds': _selecionados.toList()},
      );
      if (mounted) {
        ref.invalidate(alunosProvider);
        FeedbackHelper.showSuccess(
          context,
          _mensalidadesPagasMessage(_selecionados.length),
        );
        setState(() {
          _modoSelecao = false;
          _selecionados.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, 'Erro ao marcar pagamentos: $e');
      }
    }
  }

  Future<void> _atualizarStatusSelecionados(String novoStatus) async {
    if (_selecionados.isEmpty) return;
    final repo = AlunoRepository(ref.read(apiClientProvider));
    try {
      await repo.atualizarStatusLote(_selecionados.toList(), novoStatus);
      if (mounted) {
        ref.invalidate(alunosProvider);
        ref.invalidate(alunosStatsProvider);
        FeedbackHelper.showSuccess(
          context,
          _alunosAtualizadosMessage(_selecionados.length),
        );
        setState(() {
          _modoSelecao = false;
          _selecionados.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, 'Erro ao atualizar status: $e');
      }
    }
  }

  void _showBulkActionsSheet() {
    if (_selecionados.isEmpty) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final qtd = _selecionados.length;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (sheetContext) => _AlunosBulkActionsSheet(
            count: qtd,
            isDark: isDark,
            onMarcarPagos: () {
              Navigator.pop(sheetContext);
              _marcarPagosSelecionados();
            },
            onAtualizarStatus: (status) {
              Navigator.pop(sheetContext);
              _atualizarStatusSelecionados(status);
            },
            onExcluir: () {
              Navigator.pop(sheetContext);
              _excluirSelecionados();
            },
          ),
    );
  }

  List<Aluno> _filtrarAlunos(List<Aluno> todos, {required int diasSemTreinoLimite}) {
    final porStatus = switch (_filtro) {
      AlunoFiltro.todos => todos,
      AlunoFiltro.contatoHoje =>
        todos
            .where(
              (a) => alunoPrecisaContatoHoje(
                a,
                diasSemTreinoLimite: diasSemTreinoLimite,
              ),
            )
            .toList(),
      AlunoFiltro.ativos =>
        todos
            .where(
              (a) =>
                  a.status == 'ATIVO' && a.statusFinanceiro != 'INADIMPLENTE',
            )
            .toList(),
      AlunoFiltro.inadimplentes =>
        todos
            .where(
              (a) => a.statusFinanceiro == 'INADIMPLENTE' || a.inadimplente,
            )
            .toList(),
      AlunoFiltro.risco => todos.where((a) => a.emRisco).toList(),
      AlunoFiltro.novos =>
        todos.where((a) => a.senhaProvisoria != null).toList(),
    };

    final busca = _fold(_query.trim());
    if (busca.isEmpty) {
      return _ordenarAlunos(porStatus, diasSemTreinoLimite: diasSemTreinoLimite);
    }

    final encontrados =
        porStatus.where((a) {
          final alvo = _fold(
            '${a.nome} ${a.email} ${a.objetivo ?? ''} ${a.statusFinanceiro} '
            '${a.telefone ?? ''} ${a.whatsapp ?? ''}',
          );
          return alvo.contains(busca);
        }).toList();

    return _ordenarAlunos(encontrados, diasSemTreinoLimite: diasSemTreinoLimite);
  }

  bool get _hasActiveFilter => _filtro != AlunoFiltro.todos;

  String _filtroLabel(AlunoFiltro filtro) => switch (filtro) {
    AlunoFiltro.todos => 'todos',
    AlunoFiltro.contatoHoje => 'precisando de contato hoje',
    AlunoFiltro.ativos => 'ativos',
    AlunoFiltro.inadimplentes => 'inadimplentes',
    AlunoFiltro.risco => 'em risco',
    AlunoFiltro.novos => 'convites pendentes',
  };

  int _contatoHojeCount(List<Aluno> alunos, {required int diasSemTreinoLimite}) {
    return alunos
        .where(
          (a) => alunoPrecisaContatoHoje(
            a,
            diasSemTreinoLimite: diasSemTreinoLimite,
          ),
        )
        .length;
  }

  List<Aluno> _ordenarAlunos(
    List<Aluno> alunos, {
    required int diasSemTreinoLimite,
  }) {
    final ordenados = List<Aluno>.from(alunos);
    switch (_ordenacao) {
      case AlunoOrdenacao.prioridade:
        ordenados.sort((a, b) {
          final scoreA =
              _priorityScore(a, diasSemTreinoLimite: diasSemTreinoLimite);
          final scoreB =
              _priorityScore(b, diasSemTreinoLimite: diasSemTreinoLimite);
          final score = scoreB.compareTo(scoreA);
          if (score != 0) return score;
          final diasA = a.diasSemTreino ?? 0;
          final diasB = b.diasSemTreino ?? 0;
          final diasCmp = diasB.compareTo(diasA);
          if (diasCmp != 0) return diasCmp;
          final aderA = a.aderenciaPercent ?? 100;
          final aderB = b.aderenciaPercent ?? 100;
          final aderCmp = aderA.compareTo(aderB);
          if (aderCmp != 0) return aderCmp;
          return _fold(a.nome).compareTo(_fold(b.nome));
        });
      case AlunoOrdenacao.nome:
        ordenados.sort((a, b) => _fold(a.nome).compareTo(_fold(b.nome)));
      case AlunoOrdenacao.semFoto:
        ordenados.sort((a, b) {
          final photo = _hasPhoto(
            a,
          ).toString().compareTo(_hasPhoto(b).toString());
          if (photo != 0) return photo;
          return _fold(a.nome).compareTo(_fold(b.nome));
        });
    }
    return ordenados;
  }

  int _priorityScore(Aluno aluno, {required int diasSemTreinoLimite}) {
    var score = 0;
    score += alunoContatoPriorityBoost(
      aluno,
      diasSemTreinoLimite: diasSemTreinoLimite,
    );
    if (aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente) {
      score += 8;
    }
    if (aluno.emRisco) score += 6;
    final dias = aluno.diasSemTreino ?? 0;
    if (dias >= 7) {
      score += 4;
    } else if (dias >= diasSemTreinoLimite) {
      score += 2;
    }
    final aderencia = aluno.aderenciaPercent;
    if (aderencia != null && aderencia < 40) score += 2;
    if (aluno.senhaProvisoria != null) score += 3;
    if (!_hasPhoto(aluno)) score += 1;
    return score;
  }

  bool _hasPhoto(Aluno aluno) {
    return aluno.fotoUrl != null && aluno.fotoUrl!.trim().isNotEmpty;
  }

  static String _fold(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp('[áàâãä]'), 'a')
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[íìîï]'), 'i')
        .replaceAll(RegExp('[óòôõö]'), 'o')
        .replaceAll(RegExp('[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }

  static String _plural(int count, String singular, String plural) {
    return '$count ${count == 1 ? singular : plural}';
  }

  static String _deletedMessage(int total) {
    if (total == 0) return 'Nenhum aluno foi excluído.';
    return '${_plural(total, 'aluno excluído', 'alunos excluídos')}.';
  }

  String _selectionSummary() {
    if (_selecionados.isEmpty) return 'Selecione os alunos';
    return _plural(_selecionados.length, 'selecionado', 'selecionados');
  }

  Future<void> _showListOptions() async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final chrome = ShellChrome.forDark(isDark);
        final ink = chrome.ink;
        final mute = chrome.mute;
        final line = chrome.line;
        final primary = Theme.of(ctx).colorScheme.primary;
        final linkColor = BrandPalette.sectionLink(primary, dark: isDark);

        Widget option({
          required String title,
          required String subtitle,
          required IconData icon,
          required bool selected,
          required VoidCallback onTap,
        }) {
          return InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
              Navigator.pop(ctx);
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    selected
                        ? primary.withValues(alpha: isDark ? 0.2 : 0.08)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      selected
                          ? primary.withValues(alpha: 0.35)
                          : line.withValues(alpha: 0.75),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? primary
                              : primary.withValues(alpha: isDark ? 0.18 : 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      selected ? Icons.check_rounded : icon,
                      color: selected ? Colors.white : primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.inter(
                            color: ink,
                            fontSize: TokensStrip.fontBody,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTypography.inter(
                            color: mute,
                            fontSize: TokensStrip.fontBodySm,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final sheetMaxHeight = MediaQuery.sizeOf(ctx).height * 0.72;

        return DecoratedBox(
          decoration: chrome.bottomSheet(),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: sheetMaxHeight),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Organizar alunos',
                          style: AppTypography.inter(
                            color: ink,
                            fontSize: TokensStrip.fontH2,
                            fontWeight: TokensStrip.weightH2,
                            letterSpacing: TokensStrip.trackingH2,
                            height: 1.2,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _filtro = AlunoFiltro.todos;
                            _ordenacao = AlunoOrdenacao.prioridade;
                          });
                          Navigator.pop(ctx);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: linkColor,
                          textStyle: AppTypography.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: TokensStrip.fontBodySm,
                          ),
                        ),
                        child: const Text('Redefinir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Escolha como a lista deve aparecer agora.',
                    style: AppTypography.inter(
                      color: mute,
                      fontSize: TokensStrip.fontBodySm,
                      height: 1.35,
                    ),
                  ),
                const SizedBox(height: TokensStrip.s4),
                option(
                  title: 'Prioridade do dia',
                  subtitle:
                      'Risco, inadimplência e convites aparecem primeiro.',
                  icon: Icons.priority_high_rounded,
                  selected: _ordenacao == AlunoOrdenacao.prioridade,
                  onTap:
                      () => setState(
                        () => _ordenacao = AlunoOrdenacao.prioridade,
                      ),
                ),
                const SizedBox(height: 8),
                option(
                  title: 'Nome A-Z',
                  subtitle: 'Lista alfabética para encontrar alunos rápido.',
                  icon: Icons.sort_by_alpha_rounded,
                  selected: _ordenacao == AlunoOrdenacao.nome,
                  onTap: () => setState(() => _ordenacao = AlunoOrdenacao.nome),
                ),
                const SizedBox(height: 8),
                option(
                  title: 'Sem foto primeiro',
                  subtitle:
                      'Ajuda a completar perfis que ainda parecem genéricos.',
                  icon: Icons.no_photography_outlined,
                  selected: _ordenacao == AlunoOrdenacao.semFoto,
                  onTap:
                      () => setState(() => _ordenacao = AlunoOrdenacao.semFoto),
                ),
                const SizedBox(height: 8),
                option(
                  title: 'Lista compacta',
                  subtitle:
                      'Menos ruído: oculta e-mail na lista e reduz o card.',
                  icon: Icons.density_small_rounded,
                  selected: _listaCompacta,
                  onTap: () async {
                    final next = !_listaCompacta;
                    setState(() => _listaCompacta = next);
                    await AlunoListPreferencesStore.saveCompact(next);
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  'Atalhos de foco',
                  style: AppTypography.inter(
                    color: ink,
                    fontSize: TokensStrip.fontBodySm,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SheetShortcutChip(
                      label: 'Contato hoje',
                      selected: _filtro == AlunoFiltro.contatoHoje,
                      onTap: () {
                        setState(() => _filtro = AlunoFiltro.contatoHoje);
                        Navigator.pop(ctx);
                      },
                    ),
                    _SheetShortcutChip(
                      label: 'Risco alto',
                      selected: _filtro == AlunoFiltro.risco,
                      onTap: () {
                        setState(() => _filtro = AlunoFiltro.risco);
                        Navigator.pop(ctx);
                      },
                    ),
                    _SheetShortcutChip(
                      label: 'Inadimplentes',
                      selected: _filtro == AlunoFiltro.inadimplentes,
                      onTap: () {
                        setState(() => _filtro = AlunoFiltro.inadimplentes);
                        Navigator.pop(ctx);
                      },
                    ),
                    _SheetShortcutChip(
                      label: 'Convites',
                      selected: _filtro == AlunoFiltro.novos,
                      onTap: () {
                        setState(() => _filtro = AlunoFiltro.novos);
                        Navigator.pop(ctx);
                      },
                    ),
                    _SheetShortcutChip(
                      label: 'Todos',
                      selected: _filtro == AlunoFiltro.todos,
                      onTap: () {
                        setState(() => _filtro = AlunoFiltro.todos);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final alunosAsync = ref.watch(alunosProvider);
    final statsAsync = ref.watch(alunosStatsProvider);
    final configAsync = ref.watch(alertasConfigProvider);
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final diasLimite =
        configAsync.valueOrNull?.diasSemTreino ??
        AlunoFollowUpStore.diasSemTreinoLimite;

    return PopScope(
      canPop: !_hasActiveFilter,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_hasActiveFilter) _handleHeaderBack();
      },
      child: Scaffold(
      backgroundColor: shellScaffoldColor,
      body: alunosAsync.when(
        loading:
            () => const SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(TokensStrip.s4, 86, TokensStrip.s4, 0),
                child: SkeletonList(count: 6),
              ),
            ),
        error:
            (e, _) => _AlunosErrorState(
              isDark: isDark,
              primary: primary,
              onRetry: () {
                ref.invalidate(alunosProvider);
                ref.invalidate(alunosStatsProvider);
              },
            ),
        data: (alunos) {
          final stats = statsAsync.valueOrNull;
          final filtrados = _filtrarAlunos(
            alunos,
            diasSemTreinoLimite: diasLimite,
          );
          final ativosCount =
              stats?.totalAtivos ??
              alunos
                  .where(
                    (a) =>
                        a.status == 'ATIVO' &&
                        a.statusFinanceiro != 'INADIMPLENTE',
                  )
                  .length;
          final inadCount =
              stats?.totalInadimplentes ??
              alunos
                  .where(
                    (a) =>
                        a.statusFinanceiro == 'INADIMPLENTE' || a.inadimplente,
                  )
                  .length;
          final riscoCount =
              stats?.totalRiscoAlto ?? alunos.where((a) => a.emRisco).length;
          final contatoCount = _contatoHojeCount(
            alunos,
            diasSemTreinoLimite: diasLimite,
          );
          final novosCount =
              stats?.totalConvites ??
              alunos.where((a) => a.senhaProvisoria != null).length;
          final headerOps =
              _modoSelecao
                  ? _selectionSummary()
                  : '$contatoCount contato · $riscoCount risco · $novosCount convites';
          final showHeaderBack = !_modoSelecao && _hasActiveFilter;
          final headerBackFromDashboard = _hasDeepLinkFiltro(context);
          final triageContextActive =
              !_modoSelecao &&
              _filtro == AlunoFiltro.todos &&
              (contatoCount > 0 || riscoCount > 0);
          final listBottomGap = MediaQuery.sizeOf(context).width < 390 ? 28.0 : 36.0;

          return SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FxPremiumEntrance(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                // Header (Alunos + Botão Adicionar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 14, 20, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (showHeaderBack) ...[
                        Semantics(
                          button: true,
                          label:
                              headerBackFromDashboard
                                  ? 'Voltar para Hoje'
                                  : 'Limpar filtro',
                          child: InkWell(
                            onTap: _handleHeaderBack,
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: chrome.headerAction(radius: 20),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: ink,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              headerOps,
                              style: AppTypography.inter(
                                fontSize: TokensStrip.fontBodySm,
                                color: _modoSelecao
                                    ? BrandPalette.sectionAction(
                                      primary,
                                      dark: isDark,
                                    )
                                    : mute,
                                fontWeight:
                                    _modoSelecao
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                letterSpacing: _modoSelecao ? 1.2 : 0,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Alunos',
                              style: AppTypography.inter(
                                fontSize: TokensStrip.fontH1,
                                color: ink,
                                fontWeight: TokensStrip.weightH1,
                                letterSpacing: TokensStrip.trackingH1,
                                height: 1.15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_modoSelecao) ...[
                        InkWell(
                          onTap: _toggleModoSelecao,
                          borderRadius: BorderRadius.circular(44),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: chrome.headerAction(radius: 22),
                            child: Icon(Icons.close, size: 22, color: ink),
                          ),
                        ),
                      ] else ...[
                        const ShellThemeToggle(size: 40),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _toggleModoSelecao,
                          borderRadius: BorderRadius.circular(44),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: chrome.headerAction(radius: 22),
                            child: Icon(
                              Icons.checklist_rounded,
                              size: 22,
                              color: ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FxGlowSurface(
                          color: primary,
                          enabled: true,
                          intensity: 0.9,
                          borderRadius: 44,
                          child: FxSpringButton(
                            onTap: _adicionarAluno,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.fromLTRB(13, 3, 8, 3),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? EagleTokens.darkCard
                              : Colors.white.withValues(alpha: 0.86),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color:
                            _searchFocusNode.hasFocus
                                ? primary.withValues(alpha: 0.32)
                                : (isDark
                                    ? EagleTokens.darkLine
                                    : TokensStrip.borderDefault),
                        width: _searchFocusNode.hasFocus ? 1.2 : 1,
                      ),
                      boxShadow: [
                        if (_searchFocusNode.hasFocus && !isDark)
                          BoxShadow(
                            color: primary.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                            spreadRadius: -12,
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color:
                                _searchFocusNode.hasFocus
                                    ? primary.withValues(alpha: 0.08)
                                    : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: _searchFocusNode.hasFocus ? primary : mute,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: (value) {
                              setState(() => _query = value);
                            },
                            textInputAction: TextInputAction.search,
                            cursorColor: primary,
                            style: AppTypography.inter(
                              fontSize: TokensStrip.fontBody,
                              color: ink,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              hintText: 'Buscar por nome ou objetivo',
                              hintStyle: AppTypography.inter(
                                fontSize: TokensStrip.fontBody,
                                color: mute,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          InkWell(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            borderRadius: BorderRadius.circular(999),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.close, size: 18, color: mute),
                            ),
                          )
                        else
                          Tooltip(
                            message: 'Organizar lista',
                            child: InkWell(
                              onTap: _showListOptions,
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: primary.withValues(
                                    alpha: isDark ? 0.14 : 0.07,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 18,
                                      color: primary,
                                    ),
                                    if (_ordenacao !=
                                            AlunoOrdenacao.prioridade ||
                                        _filtro != AlunoFiltro.todos)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            color: primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  isDark
                                                      ? EagleTokens.darkCard
                                                      : TokensStrip.cardBg,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Filter Chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 4, 16, 10),
                  child: _HorizontalScrollPeek(
                    showPeek: true,
                    child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FxChip(
                          label: 'Todos',
                          count: alunos.length,
                          isSelected: _filtro == AlunoFiltro.todos,
                          isDark: isDark,
                          onTap:
                              () => setState(() => _filtro = AlunoFiltro.todos),
                        ),
                        const SizedBox(width: 8),
                        _FxChip(
                          label: 'Contato hoje',
                          count: contatoCount,
                          isSelected: _filtro == AlunoFiltro.contatoHoje,
                          isDark: isDark,
                          onTap:
                              () => setState(
                                () => _filtro = AlunoFiltro.contatoHoje,
                              ),
                        ),
                        const SizedBox(width: 8),
                        _FxChip(
                          label: 'Ativos',
                          count: ativosCount,
                          isSelected: _filtro == AlunoFiltro.ativos,
                          isDark: isDark,
                          onTap:
                              () => setState(() => _filtro = AlunoFiltro.ativos),
                        ),
                        const SizedBox(width: 8),
                        _FxChip(
                          label: 'Inadimplentes',
                          count: inadCount,
                          isSelected: _filtro == AlunoFiltro.inadimplentes,
                          isDark: isDark,
                          onTap:
                              () => setState(
                                () => _filtro = AlunoFiltro.inadimplentes,
                              ),
                        ),
                        const SizedBox(width: 8),
                        _FxChip(
                          label: 'Risco alto',
                          count: riscoCount,
                          isSelected: _filtro == AlunoFiltro.risco,
                          isDark: isDark,
                          onTap:
                              () => setState(() => _filtro = AlunoFiltro.risco),
                        ),
                        const SizedBox(width: 8),
                        _FxChip(
                          label: 'Convites',
                          count: novosCount,
                          isSelected: _filtro == AlunoFiltro.novos,
                          isDark: isDark,
                          onTap:
                              () => setState(() => _filtro = AlunoFiltro.novos),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
                    ],
                  ),
                ),

                if (!_modoSelecao &&
                    _filtro == AlunoFiltro.todos &&
                    contatoCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _AlunosTriageBanner(
                      count: contatoCount,
                      isDark: isDark,
                      title:
                          '$contatoCount precisam de contato hoje',
                      subtitle:
                          'Risco, inadimplência ou $diasLimite+ dias sem treino',
                      onTap:
                          () => setState(
                            () => _filtro = AlunoFiltro.contatoHoje,
                          ),
                    ),
                  )
                else if (!_modoSelecao &&
                    _filtro == AlunoFiltro.todos &&
                    riscoCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _AlunosTriageBanner(
                      count: riscoCount,
                      isDark: isDark,
                      title: '$riscoCount aluno${riscoCount == 1 ? '' : 's'} em risco',
                      subtitle: 'Priorize contato e retomada de treino hoje',
                      onTap:
                          () => setState(() => _filtro = AlunoFiltro.risco),
                    ),
                  ),

                // List
                Expanded(
                  child:
                      filtrados.isEmpty
                          ? _EmptyAlunosState(
                            hasQuery: _query.trim().isNotEmpty,
                            hasActiveFilter: _hasActiveFilter,
                            filtroLabel: _filtroLabel(_filtro),
                            isDark: isDark,
                            onAdd: _adicionarAluno,
                            onClear:
                                _query.trim().isEmpty
                                    ? null
                                    : () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                            onClearFilter:
                                _hasActiveFilter
                                    ? () => setState(
                                      () => _filtro = AlunoFiltro.todos,
                                    )
                                    : null,
                          )
                          : RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(alunosProvider);
                              ref.invalidate(alunosStatsProvider);
                              ref.invalidate(alertasConfigProvider);
                            },
                            child: ListView.separated(
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 8,
                                bottom: listBottomGap,
                              ),
                              itemCount: filtrados.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final a = filtrados[i];
                                return FxStaggerItem(
                                  index: i,
                                  child: _AlunoCardFX(
                                    aluno: a,
                                    modoSelecao: _modoSelecao,
                                    isSelected: _selecionados.contains(a.id),
                                    onToggle: () => _toggleSelecionado(a.id),
                                    onLongPress:
                                        _modoSelecao
                                            ? null
                                            : _toggleModoSelecao,
                                    activeFiltro: _filtro,
                                    triageContextActive: triageContextActive,
                                    diasSemTreinoLimite: diasLimite,
                                    compact: _listaCompacta,
                                  ),
                                );
                              },
                            ),
                          ),
                ),

                // Bottom action bar (seleção)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: (_modoSelecao && _selecionados.isNotEmpty) ? null : 0,
                  child:
                      (_modoSelecao && _selecionados.isNotEmpty)
                          ? SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 8, 16, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          if (_selecionados.length ==
                                              filtrados.length) {
                                            _selecionados.clear();
                                          } else {
                                            _selecionados.addAll(
                                              filtrados.map((a) => a.id),
                                            );
                                          }
                                        });
                                      },
                                      icon: const Icon(
                                        Icons.select_all,
                                        size: 18,
                                      ),
                                      label: Text(
                                        _selecionados.length == filtrados.length
                                            ? 'Desmarcar todos'
                                            : 'Selecionar todos',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color:
                                              isDark
                                                  ? EagleTokens.darkLine
                                                  : TokensStrip.borderDefault,
                                        ),
                                        foregroundColor: ink,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _showBulkActionsSheet,
                                      icon: const Icon(
                                        Icons.bolt_rounded,
                                        size: 18,
                                      ),
                                      label: Text(
                                        'Ações (${_selecionados.length})',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primary,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    ),
    );
  }
}

class _FxChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FxChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final action = BrandPalette.sectionAction(primary, dark: isDark);
    final bg =
        isSelected
            ? primary
            : (isDark
                ? Colors.white.withValues(alpha: 0.055)
                : Colors.white.withValues(alpha: 0.78));
    final color = isSelected ? Colors.white : (isDark ? EagleTokens.darkInk : TokensStrip.textPrimary);
    final border =
        isSelected
            ? Border.all(color: action.withValues(alpha: isDark ? 0.45 : 0.28))
            : Border.all(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.09)
                      : TokensStrip.borderDefault,
            );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: border,
          boxShadow: [
            if (isSelected && !isDark)
              BoxShadow(
                color: primary.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: -6,
              ),
            if (isSelected && isDark)
              BoxShadow(
                color: action.withValues(alpha: 0.28),
                blurRadius: 12,
                spreadRadius: -2,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTypography.inter(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
                height: 1.15,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.white
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : TokensStrip.pageBg),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: AppTypography.inter(
                  color:
                      isSelected
                          ? primary
                          : (isDark
                              ? EagleTokens.darkInkMute
                              : TokensStrip.textSecondary),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetShortcutChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SheetShortcutChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected
                  ? primary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : TokensStrip.cardBg),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected
                    ? primary
                    : (isDark ? EagleTokens.darkLine : TokensStrip.borderDefault),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.inter(
            color: selected ? Colors.white : ink,
            fontSize: TokensStrip.fontBodySm,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _EmptyAlunosState extends StatelessWidget {
  final bool hasQuery;
  final bool hasActiveFilter;
  final String filtroLabel;
  final bool isDark;
  final VoidCallback? onClear;
  final VoidCallback? onClearFilter;
  final VoidCallback? onAdd;

  const _EmptyAlunosState({
    required this.hasQuery,
    this.hasActiveFilter = false,
    this.filtroLabel = '',
    required this.isDark,
    this.onClear,
    this.onClearFilter,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final primary = Theme.of(context).colorScheme.primary;
    final filteredEmpty = hasActiveFilter && !hasQuery;

    final title =
        hasQuery
            ? 'Nenhum aluno encontrado'
            : filteredEmpty
            ? 'Nenhum aluno neste filtro'
            : 'Nenhum aluno cadastrado';
    final subtitle =
        hasQuery
            ? 'Tente buscar por outro nome, objetivo ou e-mail.'
            : filteredEmpty
            ? 'Não há alunos $filtroLabel no momento. Limpe o filtro ou mude a visualização.'
            : 'Adicione o primeiro aluno para montar treinos e acompanhar a evolução.';
    final icon =
        hasQuery
            ? Icons.search_off_rounded
            : filteredEmpty
            ? Icons.filter_alt_off_rounded
            : Icons.group_add_rounded;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.18 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primary, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                color: ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: mute, fontSize: 13, height: 1.35),
            ),
            if (onClearFilter != null) ...[
              const SizedBox(height: TokensStrip.s4),
              OutlinedButton(
                onPressed: onClearFilter,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Limpar filtro'),
              ),
            ] else if (onClear != null) ...[
              const SizedBox(height: TokensStrip.s4),
              OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Limpar busca'),
              ),
            ] else if (onAdd != null) ...[
              const SizedBox(height: 20),
              FxLiquidPrimaryButton(
                label: 'Adicionar aluno',
                icon: Icons.person_add_rounded,
                onPressed: onAdd,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlunoCardFX extends ConsumerStatefulWidget {
  final Aluno aluno;
  final bool modoSelecao;
  final bool isSelected;
  final VoidCallback? onToggle;
  final VoidCallback? onLongPress;

  /// Active filter — used to suppress redundant status badges.
  final AlunoFiltro activeFiltro;
  final bool triageContextActive;
  final int diasSemTreinoLimite;
  final bool compact;

  const _AlunoCardFX({
    required this.aluno,
    this.modoSelecao = false,
    this.isSelected = false,
    this.onToggle,
    this.onLongPress,
    this.activeFiltro = AlunoFiltro.todos,
    this.triageContextActive = false,
    this.diasSemTreinoLimite = AlunoFollowUpStore.diasSemTreinoLimite,
    this.compact = false,
  });

  @override
  ConsumerState<_AlunoCardFX> createState() => _AlunoCardFXState();
}

class _AlunoCardFXState extends ConsumerState<_AlunoCardFX> {
  List<Map<String, dynamic>>? _dados;

  @override
  void initState() {
    super.initState();
    if (widget.aluno.aderenciaPercent == null) {
      _loadSparkline();
    }
  }

  Future<void> _loadSparkline() async {
    try {
      final repo = AlunoRepository(ref.read(apiClientProvider));
      final res = await repo.aderenciaSemanal(widget.aluno.id);
      if (mounted) setState(() => _dados = res);
    } catch (e) {
      debugPrint('[Focux] Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final secondaryInk = _alunoListSecondaryInk(isDark);
    final line = chrome.line;
    final cardPadding = widget.compact ? 10.0 : 14.0;

    final aluno = widget.aluno;
    final displayName = fxTitleCaseName(aluno.nome);
    final objetivo = _prettyObjective(aluno.objetivo);

    // FxStatus pill colors
    Color statusBg, statusColor;
    String statusText;

    if (aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente) {
      statusBg = isDark ? const Color(0x24FF8B8B) : EagleTokens.badSoft;
      statusColor = isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad;
      statusText = 'Inadimplente';
    } else if (aluno.status == 'INATIVO') {
      statusBg = isDark ? const Color(0x24E2B46F) : EagleTokens.warnSoft;
      statusColor = isDark ? const Color(0xFFE2B46F) : EagleTokens.warn;
      statusText = 'Inativo';
    } else if (aluno.emRisco) {
      final riscoColors = _riscoAltoBadgeColors(isDark);
      statusBg = riscoColors.$2;
      statusColor = riscoColors.$1;
      statusText = 'Risco alto';
    } else {
      statusBg = isDark ? const Color(0x1F6FE296) : EagleTokens.goodSoft;
      statusColor = isDark ? const Color(0xFF6FE296) : EagleTokens.good;
      statusText = 'Ativo';
    }

    // Avatar color hashing (deterministic)
    final palette =
        isDark
            ? const [
              Color(0xFF1EC8C8),
              Color(0xFF26A8A8),
              Color(0xFF159A9A),
              Color(0xFF32D4D4),
              Color(0xFF0F7A7A),
              Color(0xFF5EEAD4),
            ]
            : const [
              Color(0xFF1EC8C8),
              Color(0xFF26A8A8),
              Color(0xFF5EEAD4),
              Color(0xFF159A9A),
              Color(0xFF32D4D4),
              Color(0xFF8BF0E0),
            ];
    final hash = displayName.isNotEmpty ? displayName.codeUnitAt(0) : 0;
    final avatarColor = palette[hash % palette.length];

    final sparkValues = (_dados ?? const <Map<String, dynamic>>[])
        .map((e) => (e['checkins'] as num?)?.toDouble() ?? 0.0)
        .toList(growable: false);
    final weeklyCheckins = sparkValues.fold<double>(0, (p, v) => p + v).round();
    final aderenciaPercent =
        widget.aluno.aderenciaPercent ??
        (sparkValues.isEmpty
            ? null
            : ((weeklyCheckins / 7.0) * 100).round().clamp(0, 100));
    final aderColor = EagleTokens.aderenciaColor(
      (aderenciaPercent ?? 0).toDouble(),
      isDark: isDark,
    );
    final adherenceLabel = _adherenceActivityLabel(
      aluno: aluno,
      weeklyCheckins: weeklyCheckins,
    );
    final hasTreinoRecente =
        (aluno.diasSemTreino ?? 1) == 0 ||
        weeklyCheckins > 0 ||
        (aderenciaPercent ?? 0) > 0;
    final isSelected = widget.isSelected;
    final modoSelecao = widget.modoSelecao;
    final needsOutreach =
        !modoSelecao &&
        alunoPrecisaContatoHoje(
          aluno,
          diasSemTreinoLimite: widget.diasSemTreinoLimite,
        );
    final whatsappNumber = (aluno.whatsapp ?? '').replaceAll(RegExp(r'\D'), '');
    final hasWhatsapp = whatsappNumber.isNotEmpty;

    return InkWell(
      onTap:
          modoSelecao
              ? widget.onToggle
              : () => context.push('/alunos/${aluno.id}'),
      onLongPress: widget.onLongPress,
      borderRadius: BorderRadius.circular(TokensStrip.rCard),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(cardPadding),
        decoration: ShellChrome.forDark(isDark).listCard(
          selected: isSelected,
          primary: primary,
          radius: TokensStrip.rCard,
        ),
        child: Row(
          children: [
            // Checkbox em modo seleção
            if (modoSelecao) ...[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  key: ValueKey(isSelected),
                  color:
                      isSelected
                          ? primary
                          : (isDark
                              ? EagleTokens.darkInkMute
                              : TokensStrip.textSecondary),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
            ],
            // FxAvatar
            _AlunoPhotoAvatar(
              name: displayName,
              photoUrl: aluno.fotoUrl,
              fallbackColor: avatarColor,
            ),
            const SizedBox(width: 12),

            // Middle Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: AppTypography.inter(
                            fontSize: TokensStrip.fontBody,
                            fontWeight: FontWeight.w700,
                            color: ink,
                            letterSpacing: -0.15,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Only show badge when it adds information
                      // (suppress when the active filter already implies the status)
                      if (_shouldShowBadge(
                        statusText,
                        widget.activeFiltro,
                        triageContextActive: widget.triageContextActive,
                      )) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                statusText,
                                style: AppTypography.inter(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.15,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (!widget.compact) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$objetivo · ${maskEmailForList(aluno.email)}',
                      style: AppTypography.inter(
                        fontSize: TokensStrip.fontBodySm,
                        color: secondaryInk,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ] else ...[
                    const SizedBox(height: 2),
                    Text(
                      objetivo,
                      style: AppTypography.inter(
                        fontSize: TokensStrip.fontBodySm,
                        color: secondaryInk,
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  SizedBox(height: widget.compact ? 6 : 8),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: aderColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        aderenciaPercent == null ? '—' : '$aderenciaPercent%',
                        style: AppTypography.mono(
                          fontSize: 12.5,
                          fontWeight:
                              hasTreinoRecente
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                          color: hasTreinoRecente ? aderColor : secondaryInk,
                          height: 1.1,
                        ),
                      ),
                      if (!widget.compact && adherenceLabel.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '·',
                            style: AppTypography.inter(
                              fontSize: 11,
                              color: secondaryInk.withValues(alpha: 0.85),
                              height: 1.1,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            adherenceLabel,
                            style: AppTypography.inter(
                              fontSize: 11,
                              color: secondaryInk,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Rail (só fora da fila de contato) ou ações rápidas compactas
            if (needsOutreach)
              _AlunoOutreachActions(
                alunoId: aluno.id,
                displayName: displayName,
                whatsappNumber: whatsappNumber,
                hasWhatsapp: hasWhatsapp,
                emRisco: aluno.emRisco,
                primary: primary,
                isDark: isDark,
                mute: mute,
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AdherenceRail(
                    value: (aderenciaPercent ?? 0).toDouble(),
                    color: aderColor,
                    line: line,
                    isEmpty: !hasTreinoRecente,
                  ),
                  const SizedBox(height: 6),
                  Semantics(
                    label: 'Abrir ficha de $displayName',
                    button: true,
                    child: Tooltip(
                      message: 'Ver detalhes',
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: secondaryInk.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AlunoPhotoAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final Color fallbackColor;

  const _AlunoPhotoAvatar({
    required this.name,
    required this.photoUrl,
    required this.fallbackColor,
  });

  static const double _photoOuter = 46;
  static const double _initialsSize = 44;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final neon = BrandPalette.accent(primary);
    final resolvedUrl = _resolveMediaUrl(photoUrl);

    if (resolvedUrl != null) {
      const ring = 2.0;
      const gap = 2.0;
      final avatarRadius = (_photoOuter - ring * 2 - gap * 2) / 2;

      return Container(
        width: _photoOuter,
        height: _photoOuter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: neon.withValues(alpha: isDark ? 0.96 : 0.88),
            width: ring,
          ),
          boxShadow: [
            BoxShadow(
              color: neon.withValues(alpha: isDark ? 0.42 : 0.36),
              blurRadius: isDark ? 14 : 12,
            ),
          ],
        ),
        padding: const EdgeInsets.all(gap),
        child: ClipOval(
          child: Image.network(
            resolvedUrl,
            width: avatarRadius * 2,
            height: avatarRadius * 2,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return _AlunoInitials(name: name, size: avatarRadius * 2);
            },
            errorBuilder:
                (context, error, stackTrace) =>
                    _AlunoInitials(name: name, size: avatarRadius * 2),
          ),
        ),
      );
    }

    return Container(
      width: _initialsSize,
      height: _initialsSize,
      decoration: BoxDecoration(
        color: fallbackColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: BrandPalette.sectionAccent(primary, dark: isDark).withValues(
            alpha: isDark ? 0.28 : 0.18,
          ),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _AlunoInitials(name: name, size: _initialsSize),
    );
  }
}

class _AlunoInitials extends StatelessWidget {
  final String name;
  final double size;

  const _AlunoInitials({required this.name, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        fxInitials(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdherenceRail extends StatelessWidget {
  final double value;
  final Color color;
  final Color line;
  final bool isEmpty;

  const _AdherenceRail({
    required this.value,
    required this.color,
    required this.line,
    required this.isEmpty,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / 100).clamp(0.0, 1.0);

    return SizedBox(
      width: 58,
      height: 22,
      child: Align(
        alignment: Alignment.centerRight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Stack(
            children: [
              Container(
                width: 54,
                height: 3,
                color: isEmpty ? line.withValues(alpha: 0.55) : line,
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 54 * progress,
                height: 3,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _adherenceActivityLabel({
  required Aluno aluno,
  required int weeklyCheckins,
}) {
  final dias = aluno.diasSemTreino;
  if (dias != null && dias > 0) {
    return '${dias}d s/ treino';
  }
  if (weeklyCheckins == 0) return 's/ treinos';
  return '$weeklyCheckins ${weeklyCheckins == 1 ? 'treino' : 'treinos'}';
}

Future<void> _openWhatsappOutreach(
  BuildContext context, {
  required String displayName,
  required String whatsappNumber,
  required bool emRisco,
}) async {
  HapticFeedback.selectionClick();
  final firstName = displayName.split(' ').first;
  final mensagem =
      emRisco
          ? 'Oi $firstName, tudo bem? Vi que faz um tempo sem registrarmos treino. Posso te ajudar a retomar a rotina?'
          : 'Oi $firstName, tudo bem? Passando para alinhar sua mensalidade pendente.';
  final uri = Uri.parse(
    'https://wa.me/55$whatsappNumber?text=${Uri.encodeComponent(mensagem)}',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return;
  }
  await Clipboard.setData(ClipboardData(text: mensagem));
  if (context.mounted) {
    FeedbackHelper.showSnackBar(
      context,
      const SnackBar(content: Text('Mensagem copiada para a área de transferência')),
    );
  }
}

/// Returns true if the status badge should be shown on the card.
/// When a filter is active that already implies the status, the badge is
/// redundant and just adds visual noise to every card.
bool _shouldShowBadge(
  String statusText,
  AlunoFiltro activeFiltro, {
  bool triageContextActive = false,
}) {
  if (statusText == 'Ativo') return false;
  if (statusText == 'Risco alto') {
    if (activeFiltro == AlunoFiltro.risco) return false;
    if (activeFiltro == AlunoFiltro.contatoHoje) return false;
    if (activeFiltro == AlunoFiltro.todos && triageContextActive) {
      return false;
    }
  }
  if (statusText == 'Inadimplente') {
    if (activeFiltro == AlunoFiltro.inadimplentes) return false;
    if (activeFiltro == AlunoFiltro.contatoHoje) return false;
  }
  if (statusText == 'Inativo' && activeFiltro == AlunoFiltro.ativos) {
    return false;
  }
  return true;
}

String? _resolveMediaUrl(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return null;

  final uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) return raw;

  final base =
      Env.apiUrl.endsWith('/')
          ? Env.apiUrl.substring(0, Env.apiUrl.length - 1)
          : Env.apiUrl;
  final path = raw.startsWith('/') ? raw : '/$raw';
  return '$base$path';
}

String _prettyObjective(String? value) {
  final raw = (value ?? '').trim();
  if (raw.isEmpty) return 'Objetivo não definido';

  final normalized =
      raw
          .toLowerCase()
          .replaceAll('_', ' ')
          .replaceAll('-', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
  if (normalized.isEmpty) return 'Objetivo não definido';

  return switch (normalized) {
    'musculacao' || 'musculaçao' => 'Musculação',
    'emagrecimento' => 'Emagrecimento',
    'hipertrofia' => 'Hipertrofia',
    'condicionamento' => 'Condicionamento',
    'forca' => 'Força',
    _ => normalized[0].toUpperCase() + normalized.substring(1),
  };
}

// ──────────────────────────────────────────────
// Triage + bulk actions
// ──────────────────────────────────────────────
class _AlunosTriageBanner extends StatelessWidget {
  final int count;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _AlunosTriageBanner({
    required this.count,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final warn = isDark ? const Color(0xFFFFB77A) : EagleTokens.warn;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: fxStripCardDecoration(
            context,
            accent: warn,
            radius: TokensStrip.rCard,
            glowStrength: 0.16,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: warn.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.warning_amber_rounded, size: 18, color: warn),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.inter(
                        fontSize: TokensStrip.fontBodySm,
                        fontWeight: FontWeight.w700,
                        color: ink,
                        height: 1.25,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.inter(
                        fontSize: 11.5,
                        color: mute,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Ver lista',
                style: AppTypography.inter(
                  fontSize: TokensStrip.fontBodySm,
                  fontWeight: FontWeight.w700,
                  color: BrandPalette.sectionLink(primary, dark: isDark),
                  height: 1.1,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: BrandPalette.sectionLink(primary, dark: isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlunoOutreachActions extends ConsumerWidget {
  const _AlunoOutreachActions({
    required this.alunoId,
    required this.displayName,
    required this.whatsappNumber,
    required this.hasWhatsapp,
    required this.emRisco,
    required this.primary,
    required this.isDark,
    required this.mute,
  });

  final int alunoId;
  final String displayName;
  final String whatsappNumber;
  final bool hasWhatsapp;
  final bool emRisco;
  final Color primary;
  final bool isDark;
  final Color mute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AlunoQuickActionIcon(
          compact: true,
          icon: Icons.forum_outlined,
          tooltip: 'Chat in-app',
          color: BrandPalette.sectionAction(primary, dark: isDark),
          onTap:
              () => context.push(
                '/alunos/$alunoId/chat',
                extra: displayName,
              ),
        ),
        if (hasWhatsapp) ...[
          const SizedBox(width: 3),
          _AlunoQuickActionIcon(
            compact: true,
            icon: Icons.chat_rounded,
            tooltip: 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap: () => _openWhatsappOutreach(
              context,
              displayName: displayName,
              whatsappNumber: whatsappNumber,
              emRisco: emRisco,
            ),
          ),
        ],
        const SizedBox(width: 3),
        _AlunoQuickActionIcon(
          compact: true,
          icon: Icons.snooze_rounded,
          tooltip: 'Adiar 24h',
          color: mute,
          onTap: () async {
            await ref.read(alunoFollowUpActionsProvider).snooze(alunoId);
            if (context.mounted) {
              FeedbackHelper.showSuccess(context, 'Lembrete adiado por 24h');
            }
          },
        ),
        const SizedBox(width: 3),
        _AlunoQuickActionIcon(
          compact: true,
          icon: Icons.check_circle_outline_rounded,
          tooltip: 'Contato feito',
          color: EagleTokens.good,
          onTap: () async {
            await ref.read(alunoFollowUpActionsProvider).markContactDone(alunoId);
            if (context.mounted) {
              FeedbackHelper.showSuccess(context, 'Contato registrado');
            }
          },
        ),
      ],
    );
  }
}

class _AlunoQuickActionIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  final bool compact;

  const _AlunoQuickActionIcon({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 24.0 : 28.0;
    final iconSize = compact ? 14.0 : 15.0;

    return Semantics(
      label: tooltip,
      button: true,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: compact ? 0.1 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: iconSize, color: color),
          ),
        ),
      ),
    );
  }
}

class _AlunosBulkActionsSheet extends StatefulWidget {
  final int count;
  final bool isDark;
  final VoidCallback onMarcarPagos;
  final void Function(String status) onAtualizarStatus;
  final VoidCallback onExcluir;

  const _AlunosBulkActionsSheet({
    required this.count,
    required this.isDark,
    required this.onMarcarPagos,
    required this.onAtualizarStatus,
    required this.onExcluir,
  });

  @override
  State<_AlunosBulkActionsSheet> createState() =>
      _AlunosBulkActionsSheetState();
}

class _AlunosBulkActionsSheetState extends State<_AlunosBulkActionsSheet> {
  String _statusSelecionado = 'ATIVO';

  static const _statusOptions = <({String value, String label})>[
    (value: 'ATIVO', label: 'Ativo'),
    (value: 'INATIVO', label: 'Inativo'),
    (value: 'BLOQUEADO', label: 'Bloqueado'),
  ];

  @override
  Widget build(BuildContext context) {
    final ink = widget.isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final line = widget.isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final primary = Theme.of(context).colorScheme.primary;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        math.max(12, MediaQuery.paddingOf(context).bottom + 8),
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: widget.isDark ? EagleTokens.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Semantics(
                header: true,
                child: Text(
                  _alunosSelectionTitle(widget.count),
                  style: AppTypography.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: 'Marcar mensalidade como paga',
                child: SizedBox(
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: widget.onMarcarPagos,
                    icon: const Icon(Icons.attach_money_rounded, size: 18),
                    label: const Text('Marcar mensalidade como paga'),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Atualizar status',
                style: TextStyle(color: ink, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in _statusOptions)
                    Semantics(
                      button: true,
                      selected: _statusSelecionado == option.value,
                      label: 'Status ${option.label}',
                      child: _SheetShortcutChip(
                        label: option.label,
                        selected: _statusSelecionado == option.value,
                        onTap:
                            () => setState(
                              () => _statusSelecionado = option.value,
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => widget.onAtualizarStatus(_statusSelecionado),
                icon: const Icon(Icons.update_rounded, size: 18),
                label: const Text('Aplicar status'),
              ),
              const SizedBox(height: 12),
              Semantics(
                button: true,
                label: 'Excluir alunos selecionados',
                child: OutlinedButton.icon(
                  onPressed: widget.onExcluir,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Excluir selecionados'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EagleTokens.bad,
                    side: const BorderSide(color: EagleTokens.bad),
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

// ──────────────────────────────────────────────
// Premium delete confirmation bottom sheet
// ──────────────────────────────────────────────
class _ExcluirAlunosSheet extends StatelessWidget {
  final int count;
  final bool isDark;

  const _ExcluirAlunosSheet({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    final label =
        count == 1
            ? '1 aluno selecionado será excluído permanentemente.'
            : '$count alunos selecionados serão excluídos permanentemente.';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: line,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: EagleTokens.bad.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: EagleTokens.bad,
              size: 26,
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
          Text(
            'Excluir alunos?',
            style: AppTypography.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
              color: ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: mute, fontSize: 13.4, height: 1.35),
          ),
          const SizedBox(height: 6),
          Text(
            'Esta ação não pode ser desfeita.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EagleTokens.bad.withValues(alpha: 0.78),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.heavyImpact();
                Navigator.of(context).pop(true);
              },
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: Text('Excluir $count ${count == 1 ? 'aluno' : 'alunos'}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EagleTokens.bad,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(color: mute, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Premium composed error state
// ──────────────────────────────────────────────
class _AlunosErrorState extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final VoidCallback onRetry;

  const _AlunosErrorState({
    required this.isDark,
    required this.primary,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: EagleTokens.bad.withValues(
                    alpha: isDark ? 0.18 : 0.08,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: EagleTokens.bad,
                  size: 26,
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              Text(
                'Erro ao carregar alunos',
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  color: ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Verifique sua conexão e tente novamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: mute, fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Tentar novamente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
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
