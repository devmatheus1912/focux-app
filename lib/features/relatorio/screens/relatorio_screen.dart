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
      final dados = await repo.aderencia(widget.alunoId, dias: _dias);
      if (mounted) {
        setState(() {
          _dados = dados;
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
