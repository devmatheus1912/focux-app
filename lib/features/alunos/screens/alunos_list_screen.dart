import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/aluno_repository.dart';
import '../providers/alunos_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/design_tokens.dart';

enum AlunoFiltro { todos, ativos, inadimplentes, risco }

class AlunosListScreen extends ConsumerStatefulWidget {
  const AlunosListScreen({super.key});

  @override
  ConsumerState<AlunosListScreen> createState() => _AlunosListScreenState();
}

class _AlunosListScreenState extends ConsumerState<AlunosListScreen> {
  AlunoFiltro _filtro = AlunoFiltro.todos;
  bool _modoSelecao = false;
  final Set<int> _selecionados = {};

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
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir alunos?'),
        content: Text('${_selecionados.length} aluno(s) serão excluídos permanentemente. Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$sucesso aluno(s) excluído(s)')),
      );
      setState(() {
        _modoSelecao = false;
        _selecionados.clear();
      });
    }
  }

  List<Aluno> _filtrarAlunos(List<Aluno> todos) {
    switch (_filtro) {
      case AlunoFiltro.todos:
        return todos;
      case AlunoFiltro.ativos:
        return todos.where((a) => a.status == 'ATIVO' && a.statusFinanceiro != 'INADIMPLENTE').toList();
      case AlunoFiltro.inadimplentes:
        return todos.where((a) => a.statusFinanceiro == 'INADIMPLENTE' || a.inadimplente).toList();
      case AlunoFiltro.risco:
        return todos.where((a) => a.emRisco).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final alunosAsync = ref.watch(alunosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      body: alunosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (alunos) {
          final filtrados = _filtrarAlunos(alunos);
          final ativosCount = alunos.where((a) => a.status == 'ATIVO').length;
          final inadCount = alunos.where((a) => a.statusFinanceiro == 'INADIMPLENTE' || a.inadimplente).length;

          return SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header (Alunos + Botão Adicionar)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (context.canPop()) ...[
                        InkWell(
                          onTap: () => context.pop(),
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                            child: Icon(Icons.arrow_back_ios_new, size: 20, color: ink),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _modoSelecao
                                  ? (_selecionados.isEmpty ? 'SELECIONE OS ALUNOS' : '${_selecionados.length} SELECIONADO(S)')
                                  : '$ativosCount ativos · $inadCount inadimpl.'.toUpperCase(),
                              style: TextStyle(fontSize: 12, color: _modoSelecao ? EagleTokens.brand : mute, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Alunos',
                              style: TextStyle(fontSize: 32, color: ink, fontWeight: FontWeight.w600, letterSpacing: -0.5),
                            ),
                          ],
                        ),
                      ),
                      if (_modoSelecao) ...[
                        InkWell(
                          onTap: _toggleModoSelecao,
                          borderRadius: BorderRadius.circular(44),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : EagleTokens.line,
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
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : EagleTokens.card,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                            ),
                            child: Icon(Icons.checklist_rounded, size: 22, color: isDark ? EagleTokens.darkInk : EagleTokens.ink),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () async {
                            final criado = await context.push<bool>('/alunos/novo');
                            if (criado == true) ref.invalidate(alunosProvider);
                          },
                          borderRadius: BorderRadius.circular(44),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white : EagleTokens.brand,
                              shape: BoxShape.circle,
                              boxShadow: [
                                if (!isDark) BoxShadow(color: EagleTokens.brand.withValues(alpha: 0.5), blurRadius: 16, offset: const Offset(0, 6), spreadRadius: -6)
                              ],
                            ),
                            child: Icon(Icons.add, size: 24, color: isDark ? EagleTokens.ink : Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                      borderRadius: BorderRadius.circular(14),
                      border: isDark ? null : Border.all(color: EagleTokens.line),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 20, color: mute),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('Buscar por nome, objetivo...', style: TextStyle(fontSize: 14, color: mute)),
                        ),
                        Icon(Icons.tune, size: 20, color: isDark ? EagleTokens.brandAccent : EagleTokens.brand),
                      ],
                    ),
                  ),
                ),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _FxChip(label: 'Todos', isSelected: _filtro == AlunoFiltro.todos, isDark: isDark, onTap: () => setState(() => _filtro = AlunoFiltro.todos)),
                      _FxChip(label: 'Ativos', isSelected: _filtro == AlunoFiltro.ativos, isDark: isDark, onTap: () => setState(() => _filtro = AlunoFiltro.ativos)),
                      _FxChip(label: 'Inadimplentes', isSelected: _filtro == AlunoFiltro.inadimplentes, isDark: isDark, onTap: () => setState(() => _filtro = AlunoFiltro.inadimplentes)),
                      _FxChip(label: 'Risco alto', isSelected: _filtro == AlunoFiltro.risco, isDark: isDark, onTap: () => setState(() => _filtro = AlunoFiltro.risco)),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: filtrados.isEmpty
                      ? const Center(child: Text('Nenhum aluno encontrado.'))
                      : RefreshIndicator(
                          onRefresh: () async => ref.invalidate(alunosProvider),
                          child: ListView.separated(
                            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 120),
                            itemCount: filtrados.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final a = filtrados[i];
                              return _AlunoCardFX(
                                aluno: a,
                                modoSelecao: _modoSelecao,
                                isSelected: _selecionados.contains(a.id),
                                onToggle: () => _toggleSelecionado(a.id),
                                onLongPress: _modoSelecao ? null : _toggleModoSelecao,
                              );
                            },
                          ),
                        ),
                ),

                // Bottom action bar (seleção)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: (_modoSelecao && _selecionados.isNotEmpty) ? null : 0,
                  child: (_modoSelecao && _selecionados.isNotEmpty)
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
                                        if (_selecionados.length == filtrados.length) {
                                          _selecionados.clear();
                                        } else {
                                          _selecionados.addAll(filtrados.map((a) => a.id));
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.select_all, size: 18),
                                    label: Text(_selecionados.length == filtrados.length ? 'Desmarcar todos' : 'Selec. todos'),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                                      foregroundColor: ink,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _excluirSelecionados,
                                    icon: const Icon(Icons.delete_outline, size: 18),
                                    label: Text('Excluir (${_selecionados.length})'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: EagleTokens.bad,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
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
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  
  const _FxChip({required this.label, required this.isSelected, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = isSelected 
        ? (isDark ? Colors.white : EagleTokens.ink) 
        : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white);
    final color = isSelected 
        ? (isDark ? EagleTokens.ink : Colors.white) 
        : (isDark ? EagleTokens.darkInk : EagleTokens.ink);
    final border = isSelected 
        ? null 
        : Border.all(color: isDark ? Colors.white.withValues(alpha: 0.09) : EagleTokens.line);

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
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.2),
          ),
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
    } catch (e) { debugPrint('[Focux] Error: $e');}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    
    final aluno = widget.aluno;

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
    final palette = isDark
        ? const [Color(0xFF2B4A9E), Color(0xFF3D5FBE), Color(0xFF1F3881), Color(0xFF4A6FD1), Color(0xFF243B7A), Color(0xFF6482D9)]
        : const [Color(0xFF2B4A9E), Color(0xFF3D5FBE), Color(0xFF6482D9), Color(0xFF1F3881), Color(0xFF4A6FD1), Color(0xFF8DA4E2)];
    final hash = aluno.nome.isNotEmpty ? aluno.nome.codeUnitAt(0) : 0;
    final avatarColor = palette[hash % palette.length];

    // Mocks for now as we don't have this in real model
    final aderenciaMock = 85; 
    final diasSem = 0;
    final aderColor = EagleTokens.aderenciaColor(aderenciaMock.toDouble(), isDark: isDark);

    final isSelected = widget.isSelected;
    final modoSelecao = widget.modoSelecao;

    return InkWell(
      onTap: modoSelecao ? widget.onToggle : () => context.push('/alunos/${aluno.id}'),
      onLongPress: widget.onLongPress,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? EagleTokens.brand.withValues(alpha: isDark ? 0.18 : 0.08) : cardBg,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: EagleTokens.brand.withValues(alpha: 0.5), width: 1.5)
              : (isDark ? null : Border.all(color: line)),
        ),
        child: Row(
          children: [
            // Checkbox em modo seleção
            if (modoSelecao) ...[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  key: ValueKey(isSelected),
                  color: isSelected ? EagleTokens.brand : (isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
            ],
            // FxAvatar
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                aluno.nome.isNotEmpty ? aluno.nome[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                      Flexible(child: Text(aluno.nome, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: ink), overflow: TextOverflow.ellipsis)),
                      if (statusText != 'ATIVO') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(999)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 5, height: 5, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('${aluno.objetivo ?? 'Emagrecimento'} · ${aluno.email}', style: TextStyle(fontSize: 12, color: mute), maxLines: 1, overflow: TextOverflow.ellipsis),
                  
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: aderColor, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text('$aderenciaMock%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ink)),
                      const SizedBox(width: 4),
                      Text('aderência', style: TextStyle(fontSize: 11, color: mute)),
                      
                      const SizedBox(width: 10),
                      Container(width: 1, height: 10, color: line),
                      const SizedBox(width: 10),
                      Text(diasSem == 0 ? 'Treinou hoje' : 'há ${diasSem}d', style: TextStyle(fontSize: 11, color: mute)),
                    ],
                  )
                ],
              ),
            ),
            
            // Sparkline + Chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_dados != null && _dados!.isNotEmpty)
                  SizedBox(
                    width: 60, height: 24,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _dados!.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['checkins'] as num).toDouble())).toList(),
                            isCurved: true,
                            color: aderColor,
                            barWidth: 1.75,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => index == barData.spots.length - 1 ? FlDotCirclePainter(radius: 2.5, color: aderColor, strokeWidth: 0) : FlDotCirclePainter(radius: 0)),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 60, height: 24),
                  
                const SizedBox(height: 6),
                Icon(Icons.chevron_right, size: 16, color: mute),
              ],
            )
          ],
        ),
      ),
    );
  }
}
