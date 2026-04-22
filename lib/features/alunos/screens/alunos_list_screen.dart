import 'package:flutter/material.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Alunos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final criado = await context.push<bool>('/alunos/novo');
          if (criado == true) ref.invalidate(alunosProvider);
        },
        child: const Icon(Icons.add),
      ),
      body: alunosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (alunos) {
          final filtrados = _filtrarAlunos(alunos);
          final ativosCount = alunos.where((a) => a.status == 'ATIVO').length;
          final inadCount = alunos.where((a) => a.statusFinanceiro == 'INADIMPLENTE' || a.inadimplente).length;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Text(
                      '$ativosCount ATIVOS · $inadCount INADIMPL.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF4B5563),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected: _filtro == AlunoFiltro.todos,
                      onSelected: (_) => setState(() => _filtro = AlunoFiltro.todos),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Ativos'),
                      selected: _filtro == AlunoFiltro.ativos,
                      selectedColor: EagleTokens.success.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _filtro = AlunoFiltro.ativos),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Inadimplentes'),
                      selected: _filtro == AlunoFiltro.inadimplentes,
                      selectedColor: EagleTokens.danger.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _filtro = AlunoFiltro.inadimplentes),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Em risco'),
                      selected: _filtro == AlunoFiltro.risco,
                      selectedColor: EagleTokens.warning.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _filtro = AlunoFiltro.risco),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtrados.isEmpty
                    ? const Center(child: Text('Nenhum aluno encontrado.'))
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(alunosProvider),
                        child: ListView.builder(
                          itemCount: filtrados.length,
                          itemBuilder: (context, i) => _AlunoTile(aluno: filtrados[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AlunoTile extends ConsumerStatefulWidget {
  final Aluno aluno;
  const _AlunoTile({required this.aluno});

  @override
  ConsumerState<_AlunoTile> createState() => _AlunoTileState();
}

class _AlunoTileState extends ConsumerState<_AlunoTile> {
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
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final aluno = widget.aluno;
    final Color dotColor;
    final Color chipColor;
    final String chipLabel;

    if (aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente) {
      dotColor = EagleTokens.danger;
      chipColor = EagleTokens.danger;
      chipLabel = 'Inadimplente';
    } else if (aluno.status == 'INATIVO') {
      dotColor = EagleTokens.warning;
      chipColor = EagleTokens.warning;
      chipLabel = 'Inativo';
    } else {
      dotColor = EagleTokens.success;
      chipColor = EagleTokens.success;
      chipLabel = 'Ativo';
    }

    return ListTile(
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 22,
            child: Text(aluno.nome.isNotEmpty ? aluno.nome[0].toUpperCase() : 'A'),
          ),
          Positioned(
            right: -2, top: -2,
            child: Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Row(children: [
        Flexible(child: Text(aluno.nome, style: const TextStyle(fontWeight: FontWeight.w600))),
        if (aluno.emRisco) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: EagleTokens.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: EagleTokens.warning.withValues(alpha: 0.5)),
            ),
            child: const Text('Risco CHURN', style: TextStyle(fontSize: 9, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
          ),
        ],
      ]),
      subtitle: Text(aluno.objetivo ?? aluno.email, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_dados != null && _dados!.isNotEmpty)
            SizedBox(
              width: 50,
              height: 24,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _dados!.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['checkins'] as num).toDouble())).toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right, color: EagleTokens.textSecondary),
        ],
      ),
      onTap: () => context.push('/alunos/${aluno.id}'),
    );
  }
}
