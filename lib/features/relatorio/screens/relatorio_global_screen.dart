import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/relatorio_repository.dart';

class RelatorioGlobalScreen extends ConsumerStatefulWidget {
  const RelatorioGlobalScreen({super.key});

  @override
  ConsumerState<RelatorioGlobalScreen> createState() =>
      _RelatorioGlobalScreenState();
}

class _RelatorioGlobalScreenState extends ConsumerState<RelatorioGlobalScreen> {
  ResumoGlobal? _dados;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final repo = RelatorioRepository(ref.read(apiClientProvider));
      final dados = await repo.resumoGlobal();
      if (mounted) {
        setState(() {
          _dados = dados;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório Global'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 12),
                        Text('Erro ao carregar: $_erro',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _load,
                            child: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                )
              : _dados == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeroCard(dados: _dados!),
                          const SizedBox(height: 24),
                          _SectionTitle(
                            icon: '🏆',
                            title: 'Mais comprometidos',
                            color: EagleTokens.success,
                          ),
                          const SizedBox(height: 8),
                          ..._dados!.maisComprometidos
                              .take(5)
                              .toList()
                              .asMap()
                              .entries
                              .map((e) => _AlunoRankCard(
                                    aluno: e.value,
                                    posicao: e.key + 1,
                                    tipo: _TipoRank.top,
                                  )),
                          const SizedBox(height: 20),
                          _SectionTitle(
                            icon: '⚠️',
                            title: 'Precisam de atenção',
                            color: EagleTokens.danger,
                          ),
                          const SizedBox(height: 8),
                          ..._dados!.menosComprometidos
                              .take(5)
                              .map((a) => _AlunoRankCard(
                                    aluno: a,
                                    posicao: -1,
                                    tipo: _TipoRank.atencao,
                                  )),
                        ],
                      ),
                    ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final ResumoGlobal dados;
  const _HeroCard({required this.dados});

  @override
  Widget build(BuildContext context) {
    final aderencia = dados.aderenciaMediaGeral;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: EagleTokens.heroGradient(dark: isDark),
        borderRadius: BorderRadius.circular(EagleTokens.radiusCard),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aderência média geral',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '${aderencia.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.group_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                '${dados.totalAlunos} alunos',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String icon;
  final String title;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    );
  }
}

enum _TipoRank { top, atencao }

class _AlunoRankCard extends StatelessWidget {
  final ResumoAluno aluno;
  final int posicao;
  final _TipoRank tipo;

  const _AlunoRankCard({
    required this.aluno,
    required this.posicao,
    required this.tipo,
  });

  Widget _leadingIcon() {
    if (tipo == _TipoRank.atencao) {
      return const CircleAvatar(
        backgroundColor: Color(0x1FF44336),
        child: Icon(Icons.warning_amber_rounded, color: EagleTokens.danger, size: 20),
      );
    }
    switch (posicao) {
      case 1:
        return const CircleAvatar(
          backgroundColor: Color(0x33FFC107),
          child: Text('🥇', style: TextStyle(fontSize: 18)),
        );
      case 2:
        return const CircleAvatar(
          backgroundColor: Color(0x33B0BEC5),
          child: Text('🥈', style: TextStyle(fontSize: 18)),
        );
      case 3:
        return const CircleAvatar(
          backgroundColor: Color(0x33FF7043),
          child: Text('🥉', style: TextStyle(fontSize: 18)),
        );
      default:
        return CircleAvatar(
          backgroundColor: EagleTokens.success.withValues(alpha: 0.12),
          child: Text(
            '$posicao',
            style: const TextStyle(
                color: EagleTokens.success, fontWeight: FontWeight.bold),
          ),
        );
    }
  }

  double get _aderencia {
    if (aluno.totalTreinos == 0) return 0;
    return (aluno.treinosConcluidos / aluno.totalTreinos) * 100;
  }

  @override
  Widget build(BuildContext context) {
    final aderencia = _aderencia;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _leadingIcon(),
        title: Text(
          aluno.alunoNome,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${aluno.treinosConcluidos} treinos concluídos',
          style: const TextStyle(fontSize: 12, color: EagleTokens.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: tipo == _TipoRank.top
                ? EagleTokens.success.withValues(alpha: 0.12)
                : EagleTokens.danger.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${aderencia.toStringAsFixed(0)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: tipo == _TipoRank.top ? EagleTokens.success : EagleTokens.danger,
            ),
          ),
        ),
      ),
    );
  }
}
