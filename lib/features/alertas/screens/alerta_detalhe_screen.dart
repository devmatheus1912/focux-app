import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/alertas_repository.dart';

class AlrtaDetalheScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;

  const AlrtaDetalheScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  ConsumerState<AlrtaDetalheScreen> createState() => _AlrtaDetalheScreenState();
}

class _AlrtaDetalheScreenState extends ConsumerState<AlrtaDetalheScreen> {
  AlertaDetalhe? _detalhe;
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
      final repo = AlertasRepository(ref.read(apiClientProvider));
      final detalhe = await repo.detalheAluno(widget.alunoId);
      if (mounted) {
        setState(() {
          _detalhe = detalhe;
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
        title: Text('Análise — ${widget.alunoNome}'),
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
                            onPressed: _load, child: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                )
              : _detalhe == null
                  ? const SizedBox.shrink()
                  : _Body(
                      detalhe: _detalhe!,
                      alunoId: widget.alunoId,
                      alunoNome: widget.alunoNome,
                    ),
    );
  }
}

class _Body extends StatelessWidget {
  final AlertaDetalhe detalhe;
  final int alunoId;
  final String alunoNome;

  const _Body({
    required this.detalhe,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardUltimoTreino(ultimoTreino: detalhe.ultimoTreino),
          const SizedBox(height: 12),
          _CardCheckIns(checkIns: detalhe.checkIns30Dias),
          const SizedBox(height: 12),
          _CardFinanceiro(status: detalhe.statusFinanceiro),
          const SizedBox(height: 12),
          _CardSugestaoIa(sugestao: detalhe.sugestaoIa),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('Enviar mensagem'),
                  onPressed: () => context.push('/alunos/$alunoId'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Ver relatório'),
                  onPressed: () => context.push(
                    '/alunos/$alunoId/relatorio',
                    extra: alunoNome,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardUltimoTreino extends StatelessWidget {
  final String? ultimoTreino;
  const _CardUltimoTreino({required this.ultimoTreino});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.fitness_center, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Último Treino',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ultimoTreino ?? 'Sem treinos recentes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ultimoTreino == null ? Colors.grey : null,
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
}

class _CardCheckIns extends StatelessWidget {
  final int checkIns;
  const _CardCheckIns({required this.checkIns});

  Color get _cor {
    if (checkIns > 10) return Colors.green;
    if (checkIns > 5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final progress = (checkIns / 20).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: _cor),
                const SizedBox(width: 12),
                Text(
                  'Check-ins (30d)',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  '$checkIns',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _cor,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: _cor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(_cor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardFinanceiro extends StatelessWidget {
  final String status;
  const _CardFinanceiro({required this.status});

  Color _cor(String s) {
    final lower = s.toLowerCase();
    if (lower.contains('em dia') || lower.contains('ok') || lower.contains('ativo')) {
      return Colors.green;
    }
    if (lower.contains('atraso') || lower.contains('inadimplente') || lower.contains('cancelado')) {
      return Colors.red;
    }
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final cor = _cor(status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: cor),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Situação Financeira',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Chip(
                  label: Text(
                    status,
                    style: TextStyle(
                      color: cor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: cor.withValues(alpha: 0.12),
                  side: BorderSide(color: cor.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardSugestaoIa extends StatelessWidget {
  final String sugestao;
  const _CardSugestaoIa({required this.sugestao});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb,
                    color: theme.colorScheme.onSecondaryContainer),
                const SizedBox(width: 8),
                Text(
                  'Sugestão da IA',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              sugestao,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
