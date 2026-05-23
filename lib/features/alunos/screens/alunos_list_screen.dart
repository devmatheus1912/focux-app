import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/config/env.dart';
import '../../../core/router/safe_navigation.dart';
import '../data/aluno_repository.dart';
import '../providers/alunos_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_premium_entrance.dart';

enum AlunoFiltro { todos, ativos, inadimplentes, risco, novos }

enum AlunoOrdenacao { prioridade, nome, semFoto }

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

  @override
  void initState() {
    super.initState();
    _filtro = widget.initialFiltro;
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant AlunosListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFiltro != widget.initialFiltro) {
      setState(() => _filtro = widget.initialFiltro);
    }
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

  List<Aluno> _filtrarAlunos(List<Aluno> todos) {
    final porStatus = switch (_filtro) {
      AlunoFiltro.todos => todos,
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
    if (busca.isEmpty) return _ordenarAlunos(porStatus);

    final encontrados =
        porStatus.where((a) {
          final alvo = _fold(
            '${a.nome} ${a.email} ${a.objetivo ?? ''} ${a.statusFinanceiro}',
          );
          return alvo.contains(busca);
        }).toList();

    return _ordenarAlunos(encontrados);
  }

  List<Aluno> _ordenarAlunos(List<Aluno> alunos) {
    final ordenados = List<Aluno>.from(alunos);
    switch (_ordenacao) {
      case AlunoOrdenacao.prioridade:
        ordenados.sort((a, b) {
          final scoreA = _priorityScore(a);
          final scoreB = _priorityScore(b);
          final score = scoreB.compareTo(scoreA);
          if (score != 0) return score;
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

  int _priorityScore(Aluno aluno) {
    var score = 0;
    if (aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente) {
      score += 8;
    }
    if (aluno.emRisco) score += 6;
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
        final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
        final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
        final primary = Theme.of(ctx).colorScheme.primary;

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
                          style: TextStyle(
                            color: ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: mute,
                            fontSize: 12,
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

        return ConstrainedBox(
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
                        style: GoogleFonts.outfit(
                          color: ink,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
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
                      child: const Text('Redefinir'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Escolha como a lista deve aparecer agora.',
                  style: TextStyle(color: mute, fontSize: 13),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 18),
                Text(
                  'Atalhos de foco',
                  style: TextStyle(
                    color: ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final alunosAsync = ref.watch(alunosProvider);
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = chrome.mute;

    return Scaffold(
      backgroundColor: shellScaffoldColor,
      body: alunosAsync.when(
        loading:
            () => const SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 86, 16, 0),
                child: SkeletonList(count: 6),
              ),
            ),
        error:
            (e, _) => _AlunosErrorState(
              isDark: isDark,
              primary: primary,
              onRetry: () => ref.invalidate(alunosProvider),
            ),
        data: (alunos) {
          final filtrados = _filtrarAlunos(alunos);
          final ativosCount = alunos.where((a) => a.status == 'ATIVO').length;
          final inadCount =
              alunos
                  .where(
                    (a) =>
                        a.statusFinanceiro == 'INADIMPLENTE' || a.inadimplente,
                  )
                  .length;
          final riscoCount = alunos.where((a) => a.emRisco).length;
          final novosCount =
              alunos.where((a) => a.senhaProvisoria != null).length;

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
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap:
                            () => safePopOrGo(context, '/dashboard/personal'),
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            right: 12,
                            top: 4,
                            bottom: 4,
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: ink,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _modoSelecao
                                  ? _selectionSummary()
                                  : '${_plural(ativosCount, 'ativo', 'ativos')} · '
                                      '${_plural(inadCount, 'inadimplente', 'inadimplentes')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _modoSelecao ? primary : mute,
                                fontWeight:
                                    _modoSelecao
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                letterSpacing: _modoSelecao ? 1.2 : 0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Alunos',
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                color: ink,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1.0,
                                height: 1,
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
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              final criado = await context.push<bool>(
                                '/alunos/novo',
                              );
                              if (criado == true) {
                                ref.invalidate(alunosProvider);
                              }
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white : primary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add,
                                size: 24,
                                color: isDark ? EagleTokens.ink : Colors.white,
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
                                    : EagleTokens.line),
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
                            style: TextStyle(
                              fontSize: 14,
                              color: ink,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              hintText: 'Buscar por nome ou objetivo',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: mute.withValues(alpha: 0.9),
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
                                                      : EagleTokens.card,
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
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FxChip(
                        label: 'Todos',
                        count: alunos.length,
                        isSelected: _filtro == AlunoFiltro.todos,
                        isDark: isDark,
                        onTap:
                            () => setState(() => _filtro = AlunoFiltro.todos),
                      ),
                      _FxChip(
                        label: 'Ativos',
                        count: ativosCount,
                        isSelected: _filtro == AlunoFiltro.ativos,
                        isDark: isDark,
                        onTap:
                            () => setState(() => _filtro = AlunoFiltro.ativos),
                      ),
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
                      _FxChip(
                        label: 'Risco alto',
                        count: riscoCount,
                        isSelected: _filtro == AlunoFiltro.risco,
                        isDark: isDark,
                        onTap:
                            () => setState(() => _filtro = AlunoFiltro.risco),
                      ),
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
                    ],
                  ),
                ),

                // List
                Expanded(
                  child:
                      filtrados.isEmpty
                          ? _EmptyAlunosState(
                            hasQuery: _query.trim().isNotEmpty,
                            isDark: isDark,
                            onClear:
                                _query.trim().isEmpty
                                    ? null
                                    : () {
                                      _searchController.clear();
                                      setState(() => _query = '');
                                    },
                          )
                          : RefreshIndicator(
                            onRefresh:
                                () async => ref.invalidate(alunosProvider),
                            child: ListView.separated(
                              padding: const EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: 8,
                                bottom: 120,
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
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                                                  : EagleTokens.line,
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
                                      onPressed: _excluirSelecionados,
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                      ),
                                      label: Text(
                                        'Excluir (${_selecionados.length})',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: EagleTokens.bad,
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
    final bg =
        isSelected
            ? (isDark ? Colors.white : EagleTokens.ink)
            : (isDark
                ? Colors.white.withValues(alpha: 0.055)
                : Colors.white.withValues(alpha: 0.78));
    final color =
        isSelected
            ? (isDark ? EagleTokens.ink : Colors.white)
            : (isDark ? EagleTokens.darkInk : EagleTokens.ink);
    final border =
        isSelected
            ? null
            : Border.all(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.09)
                      : EagleTokens.line,
            );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: border,
          boxShadow: [
            if (isSelected && !isDark)
              BoxShadow(
                color: EagleTokens.ink.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 8),
                spreadRadius: -12,
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
                height: 1,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              constraints: const BoxConstraints(minWidth: 19),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.white.withValues(alpha: isDark ? 0.18 : 0.16)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.07)
                            : EagleTokens.paper),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: TextStyle(
                  color:
                      isSelected
                          ? color
                          : (isDark
                              ? EagleTokens.darkInkMute
                              : EagleTokens.inkMute),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  height: 1,
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
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;

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
                      : EagleTokens.card),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color:
                selected
                    ? primary
                    : (isDark ? EagleTokens.darkLine : EagleTokens.line),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyAlunosState extends StatelessWidget {
  final bool hasQuery;
  final bool isDark;
  final VoidCallback? onClear;

  const _EmptyAlunosState({
    required this.hasQuery,
    required this.isDark,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primary = Theme.of(context).colorScheme.primary;

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
              child: Icon(
                hasQuery ? Icons.search_off_rounded : Icons.group_add_rounded,
                color: primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasQuery ? 'Nenhum aluno encontrado' : 'Nenhum aluno cadastrado',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasQuery
                  ? 'Tente buscar por outro nome, objetivo ou e-mail.'
                  : 'Adicione o primeiro aluno para montar treinos e acompanhar a evolução.',
              textAlign: TextAlign.center,
              style: TextStyle(color: mute, fontSize: 13, height: 1.35),
            ),
            if (onClear != null) ...[
              const SizedBox(height: 16),
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

  const _AlunoCardFX({
    required this.aluno,
    this.modoSelecao = false,
    this.isSelected = false,
    this.onToggle,
    this.onLongPress,
    this.activeFiltro = AlunoFiltro.todos,
  });

  @override
  ConsumerState<_AlunoCardFX> createState() => _AlunoCardFXState();
}

class _AlunoCardFXState extends ConsumerState<_AlunoCardFX> {
  List<Map<String, dynamic>>? _dados;

  @override
  void initState() {
    super.initState();
    _loadSparkline();
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
    final cardBg = chrome.cardFill;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;

    final aluno = widget.aluno;
    final displayName = _titleCaseName(aluno.nome);
    final objetivo = _prettyObjective(aluno.objetivo);

    // FxStatus pill colors
    Color statusBg, statusColor;
    String statusText;

    if (aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente) {
      statusBg = isDark ? const Color(0x24FF8B8B) : EagleTokens.badSoft;
      statusColor = isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad;
      statusText = 'INADIMPLENTE';
    } else if (aluno.status == 'INATIVO') {
      statusBg = isDark ? const Color(0x24E2B46F) : EagleTokens.warnSoft;
      statusColor = isDark ? const Color(0xFFE2B46F) : EagleTokens.warn;
      statusText = 'INATIVO';
    } else if (aluno.emRisco) {
      statusBg = isDark ? const Color(0x24FFB77A) : EagleTokens.warnSoft;
      statusColor = isDark ? const Color(0xFFFFB77A) : EagleTokens.warn;
      statusText = 'RISCO ALTO';
    } else {
      statusBg = isDark ? const Color(0x1F6FE296) : EagleTokens.goodSoft;
      statusColor = isDark ? const Color(0xFF6FE296) : EagleTokens.good;
      statusText = 'ATIVO';
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
    final adherenceLabel =
        weeklyCheckins == 0
            ? 'sem treinos'
            : '$weeklyCheckins ${weeklyCheckins == 1 ? 'treino' : 'treinos'}';

    final isSelected = widget.isSelected;
    final modoSelecao = widget.modoSelecao;

    return InkWell(
      onTap:
          modoSelecao
              ? widget.onToggle
              : () => context.push('/alunos/${aluno.id}'),
      onLongPress: widget.onLongPress,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: ShellChrome.forDark(isDark).listCard(
          selected: isSelected,
          primary: primary,
          radius: 20,
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
                              : EagleTokens.inkMute),
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
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ink,
                            letterSpacing: -0.15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Only show badge when it adds information
                      // (suppress when the active filter already implies the status)
                      if (_shouldShowBadge(
                        statusText,
                        widget.activeFiltro,
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
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$objetivo · ${aluno.email.toLowerCase()}',
                    style: TextStyle(fontSize: 12, color: mute),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: aderColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        aderenciaPercent == null ? '—' : '$aderenciaPercent%',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12.5,
                          fontWeight:
                              weeklyCheckins > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                          color: weeklyCheckins > 0 ? aderColor : mute,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'aderência',
                        style: TextStyle(fontSize: 11, color: mute),
                      ),

                      const SizedBox(width: 10),
                      Container(width: 1, height: 10, color: line),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          adherenceLabel,
                          style: TextStyle(fontSize: 11, color: mute),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Adherence rail + Chevron
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _AdherenceRail(
                  value: (aderenciaPercent ?? 0).toDouble(),
                  color: aderColor,
                  line: line,
                  isEmpty: weeklyCheckins == 0,
                ),
                const SizedBox(height: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: mute.withValues(alpha: 0.5),
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

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveMediaUrl(photoUrl);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: fallbackColor, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child:
          resolvedUrl == null
              ? _AlunoInitials(name: name)
              : Image.network(
                resolvedUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return _AlunoInitials(name: name);
                },
                errorBuilder:
                    (context, error, stackTrace) => _AlunoInitials(name: name),
              ),
    );
  }
}

class _AlunoInitials extends StatelessWidget {
  final String name;

  const _AlunoInitials({required this.name});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        fxInitials(name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
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

/// Returns true if the status badge should be shown on the card.
/// When a filter is active that already implies the status, the badge is
/// redundant and just adds visual noise to every card.
bool _shouldShowBadge(String statusText, AlunoFiltro activeFiltro) {
  if (statusText == 'ATIVO') return false; // Never show badge for active
  // Suppress when the filter already communicates the status
  if (statusText == 'RISCO ALTO' && activeFiltro == AlunoFiltro.risco) {
    return false;
  }
  if (statusText == 'INADIMPLENTE' &&
      activeFiltro == AlunoFiltro.inadimplentes) {
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

String _titleCaseName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Aluno';

  return trimmed
      .split(RegExp(r'\s+'))
      .map((part) {
        if (part.isEmpty) return part;
        return part[0].toUpperCase() + part.substring(1).toLowerCase();
      })
      .join(' ');
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
// Premium delete confirmation bottom sheet
// ──────────────────────────────────────────────
class _ExcluirAlunosSheet extends StatelessWidget {
  final int count;
  final bool isDark;

  const _ExcluirAlunosSheet({required this.count, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

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
          const SizedBox(height: 16),
          Text(
            'Excluir alunos?',
            style: GoogleFonts.outfit(
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
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

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
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar alunos',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
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
