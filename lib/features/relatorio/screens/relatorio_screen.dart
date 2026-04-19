import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/relatorio_repository.dart';

class RelatorioScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;

  const RelatorioScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  ConsumerState<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends ConsumerState<RelatorioScreen> {
  int _dias = 30;
  AderenciaData? _dados;
  ComparativoPeriodo? _comparativo;
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final repo = RelatorioRepository(ref.read(apiClientProvider));
      final results = await Future.wait([
        repo.aderencia(widget.alunoId, dias: _dias),
        repo.comparativo(widget.alunoId, dias: _dias).catchError((_) => null),
      ]);
      if (mounted) {
        setState(() {
          _dados = results[0] as AderenciaData;
          _comparativo = results[1] as ComparativoPeriodo?;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.toString();
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório — ${widget.alunoNome}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SeletorPeriodo(
              diasSelecionado: _dias,
              onChanged: (dias) {
                setState(() => _dias = dias);
                _carregarDados();
              },
            ),
            const SizedBox(height: 20),
            if (_carregando)
              const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_erro != null)
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Erro ao carregar relatório: $_erro',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              )
            else if (_dados != null) ...[
              _CardAderencia(dados: _dados!),
              const SizedBox(height: 16),
              if (_comparativo != null) ...[
                _CardComparativo(comparativo: _comparativo!),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: _CardInfo(
                      icone: Icons.check_circle_outline,
                      titulo: 'Treinos Concluídos',
                      valor: '${_dados!.treinosConcluidos} / ${_dados!.treinosTotal}',
                      cor: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _CardInfo(
                      icone: Icons.calendar_today_outlined,
                      titulo: 'Dias Analisados',
                      valor: '${_dados!.diasAnalisados}',
                      cor: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeletorPeriodo extends StatelessWidget {
  final int diasSelecionado;
  final ValueChanged<int> onChanged;

  const _SeletorPeriodo({
    required this.diasSelecionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Período de análise',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 30, label: Text('30 dias')),
                ButtonSegment(value: 60, label: Text('60 dias')),
                ButtonSegment(value: 90, label: Text('90 dias')),
              ],
              selected: {diasSelecionado},
              onSelectionChanged: (sel) => onChanged(sel.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardAderencia extends StatelessWidget {
  final AderenciaData dados;

  const _CardAderencia({required this.dados});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taxa = dados.taxaAderenciaPercent.clamp(0.0, 100.0);
    final cor = taxa >= 75
        ? Colors.green
        : taxa >= 50
            ? Colors.orange
            : theme.colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Taxa de Aderência',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: taxa / 100,
                      strokeWidth: 14,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(cor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${taxa.toStringAsFixed(1)}%',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cor,
                        ),
                      ),
                      Text(
                        _labelAderencia(taxa),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelAderencia(double taxa) {
    if (taxa >= 75) return 'Excelente';
    if (taxa >= 50) return 'Regular';
    return 'Baixa';
  }
}

class _CardInfo extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;
  final Color cor;

  const _CardInfo({
    required this.icone,
    required this.titulo,
    required this.valor,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 32),
            const SizedBox(height: 8),
            Text(
              valor,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardComparativo extends StatelessWidget {
  final ComparativoPeriodo comparativo;

  const _CardComparativo({required this.comparativo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = comparativo.deltaPercent;
    final isPositivo = delta >= 0;
    final deltaColor = isPositivo ? Colors.green : Colors.red;
    final deltaIcon = isPositivo ? Icons.arrow_upward : Icons.arrow_downward;
    final deltaText = isPositivo
        ? '+${delta.toStringAsFixed(1)}%'
        : '${delta.toStringAsFixed(1)}%';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'vs. período anterior',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      'Este período',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${comparativo.aderenciaAtual.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${comparativo.checkInsAtual} check-ins',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: deltaColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(deltaIcon, color: deltaColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        deltaText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: deltaColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Text(
                      'Anterior',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${comparativo.aderenciaAnterior.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${comparativo.checkInsAnterior} check-ins',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
