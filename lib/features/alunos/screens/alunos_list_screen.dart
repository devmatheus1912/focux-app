import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/router/safe_navigation.dart';
import '../data/aluno_repository.dart';
import '../providers/alunos_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/skeleton_loader.dart';

enum AlunoFiltro { todos, ativos, inadimplentes, risco, novos }

class AlunosListScreen extends ConsumerStatefulWidget {
  const AlunosListScreen({super.key});

  @override
  ConsumerState<AlunosListScreen> createState() => _AlunosListScreenState();
}

class _AlunosListScreenState extends ConsumerState<AlunosListScreen> {
  AlunoFiltro _filtro = AlunoFiltro.todos;
  bool _modoSelecao = false;
  final Set<int> _selecionados = {};
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
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
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excluir alunos?'),
            content: Text(
              '${_plural(total, 'aluno selecionado', 'alunos selecionados')} '
              '${total == 1 ? 'será excluído' : 'serão excluídos'} permanentemente. '
              'Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_deletedMessage(sucesso))));
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
    if (busca.isEmpty) return porStatus;

    return porStatus.where((a) {
      final alvo = _fold(
        '${a.nome} ${a.email} ${a.objetivo ?? ''} ${a.statusFinanceiro}',
      );
      return alvo.contains(busca);
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    final alunosAsync = ref.watch(alunosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      body: alunosAsync.when(
        loading: () => const SkeletonList(count: 6),
        error: (e, _) => Center(child: Text('Erro: $e')),
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
                              style: GoogleFonts.spaceGrotesk(
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
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : EagleTokens.line,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, size: 22, color: ink),
                          ),
                        ),
                      ] else ...[
                        InkWell(
                          onTap: _toggleModoSelecao,
                          borderRadius: BorderRadius.circular(44),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : EagleTokens.card,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isDark
                                        ? EagleTokens.darkLine
                                        : EagleTokens.line,
                              ),
                            ),
                            child: Icon(
                              Icons.checklist_rounded,
                              size: 22,
                              color:
                                  isDark
                                      ? EagleTokens.darkInk
                                      : EagleTokens.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () async {
                            final criado = await context.push<bool>(
                              '/alunos/novo',
                            );
                            if (criado == true) ref.invalidate(alunosProvider);
                          },
                          borderRadius: BorderRadius.circular(44),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.5),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                    spreadRadius: -6,
                                  ),
                              ],
                            ),
                            child: Icon(
                              Icons.add,
                              size: 24,
                              color: isDark ? EagleTokens.ink : Colors.white,
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 20, color: mute),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() => _query = value);
                            },
                            textInputAction: TextInputAction.search,
                            style: TextStyle(fontSize: 14, color: ink),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Buscar por nome ou objetivo',
                              hintStyle: TextStyle(fontSize: 14, color: mute),
                              border: InputBorder.none,
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
                          Icon(Icons.tune, size: 20, color: primary),
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
                                return _AlunoCardFX(
                                  aluno: a,
                                  modoSelecao: _modoSelecao,
                                  isSelected: _selecionados.contains(a.id),
                                  onToggle: () => _toggleSelecionado(a.id),
                                  onLongPress:
                                      _modoSelecao ? null : _toggleModoSelecao,
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
            : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white);
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

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: border,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Colors.white.withValues(alpha: isDark ? 0.16 : 0.18)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : EagleTokens.paper),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color:
                        isSelected
                            ? color
                            : (isDark
                                ? EagleTokens.darkInkMute
                                : EagleTokens.inkMute),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1,
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
              style: GoogleFonts.spaceGrotesk(
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

  const _AlunoCardFX({
    required this.aluno,
    this.modoSelecao = false,
    this.isSelected = false,
    this.onToggle,
    this.onLongPress,
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
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

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
              Color(0xFF2B4A9E),
              Color(0xFF3D5FBE),
              Color(0xFF1F3881),
              Color(0xFF4A6FD1),
              Color(0xFF243B7A),
              Color(0xFF6482D9),
            ]
            : const [
              Color(0xFF2B4A9E),
              Color(0xFF3D5FBE),
              Color(0xFF6482D9),
              Color(0xFF1F3881),
              Color(0xFF4A6FD1),
              Color(0xFF8DA4E2),
            ];
    final hash = displayName.isNotEmpty ? displayName.codeUnitAt(0) : 0;
    final avatarColor = palette[hash % palette.length];

    final sparkValues = (_dados ?? const <Map<String, dynamic>>[])
        .map((e) => (e['checkins'] as num?)?.toDouble() ?? 0.0)
        .toList(growable: false);
    final aderenciaPercent =
        sparkValues.isEmpty
            ? null
            : ((sparkValues.fold<double>(0, (p, v) => p + v) / 7.0) * 100)
                .round()
                .clamp(0, 100);
    final diasSem = 0;
    final aderColor = EagleTokens.aderenciaColor(
      (aderenciaPercent ?? 0).toDouble(),
      isDark: isDark,
    );

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
        decoration: BoxDecoration(
          color:
              isSelected
                  ? primary.withValues(alpha: isDark ? 0.18 : 0.08)
                  : cardBg,
          borderRadius: BorderRadius.circular(20),
          border:
              isSelected
                  ? Border.all(
                    color: primary.withValues(alpha: 0.5),
                    width: 1.5,
                  )
                  : Border.all(color: line),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                fxInitials(displayName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                            fontWeight: FontWeight.w600,
                            color: ink,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (statusText != 'ATIVO') ...[
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
                                  fontWeight: FontWeight.bold,
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
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: aderColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        aderenciaPercent == null ? '--%' : '$aderenciaPercent%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: aderColor,
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
                      Text(
                        diasSem == 0 ? 'Treinou hoje' : 'há ${diasSem}d',
                        style: TextStyle(fontSize: 11, color: mute),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Adherence rail + Chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _AdherenceRail(
                  value: (aderenciaPercent ?? 0).toDouble(),
                  color: aderColor,
                  line: line,
                ),
                const SizedBox(height: 10),
                Icon(Icons.chevron_right, size: 16, color: mute),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdherenceRail extends StatelessWidget {
  final double value;
  final Color color;
  final Color line;

  const _AdherenceRail({
    required this.value,
    required this.color,
    required this.line,
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
              Container(width: 54, height: 3, color: line),
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
