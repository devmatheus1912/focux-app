import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/alertas_repository.dart';

class AlertasScreen extends ConsumerStatefulWidget {
  const AlertasScreen({super.key});

  @override
  ConsumerState<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends ConsumerState<AlertasScreen> {
  List<AlertaRisco> _alertas = [];
  AlertasConfiguracao? _config;
  bool _loading = true;
  int? _filtroScoreMin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = AlertasRepository(ref.read(apiClientProvider));
      final results = await Future.wait([repo.listarRiscos(), repo.getConfiguracao()]);
      if (mounted) setState(() {
        _alertas = results[0] as List<AlertaRisco>;
        _config = results[1] as AlertasConfiguracao;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editarConfiguracao() async {
    if (_config == null) return;
    int dias = _config!.diasSemTreino;
    int aderencia = _config!.aderenciaMinima;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Configurar Alertas'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Dias sem treino: $dias'),
            Slider(
              value: dias.toDouble(),
              min: 1, max: 30, divisions: 29,
              label: '$dias dias',
              onChanged: (v) => set(() => dias = v.toInt()),
            ),
            const SizedBox(height: 8),
            Text('Aderência mínima: $aderencia%'),
            Slider(
              value: aderencia.toDouble(),
              min: 10, max: 100, divisions: 18,
              label: '$aderencia%',
              onChanged: (v) => set(() => aderencia = v.toInt()),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (confirm != true) return;
    try {
      await AlertasRepository(ref.read(apiClientProvider))
          .atualizarConfiguracao(dias, aderencia);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  List<AlertaRisco> get _filtrados {
    if (_filtroScoreMin == null) return _alertas;
    return _alertas.where((a) => a.score >= _filtroScoreMin!).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas de Risco'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () => context.push('/alertas/config'),
          ),
          if (_config != null)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Configurar',
              onPressed: _editarConfiguracao,
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              if (_config != null)
                _ConfigBar(config: _config!),
              _FiltroBar(
                selecionado: _filtroScoreMin,
                onChanged: (v) => setState(() => _filtroScoreMin = v),
              ),
              Expanded(
                child: _filtrados.isEmpty
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.check_circle, size: 64, color: Colors.green),
                          const SizedBox(height: 12),
                          Text(
                            _alertas.isEmpty
                                ? 'Nenhum aluno em risco!'
                                : 'Nenhum aluno com score ≥ ${_filtroScoreMin ?? 1}.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtrados.length,
                        itemBuilder: (_, i) => _AlertaCard(
                          alerta: _filtrados[i],
                          onTap: () => context.push(
                            '/alertas/aluno/${_filtrados[i].alunoId}',
                            extra: _filtrados[i].alunoNome,
                          ),
                        ),
                      ),
              ),
            ]),
    );
  }
}

class _ConfigBar extends StatelessWidget {
  final AlertasConfiguracao config;
  const _ConfigBar({required this.config});

  @override
  Widget build(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(children: [
      const Icon(Icons.settings, size: 16, color: Colors.grey),
      const SizedBox(width: 6),
      Text('Sem treino > ${config.diasSemTreino} dias  ·  Aderência < ${config.aderenciaMinima}%',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
    ]),
  );
}

class _FiltroBar extends StatelessWidget {
  final int? selecionado;
  final ValueChanged<int?> onChanged;
  const _FiltroBar({required this.selecionado, required this.onChanged});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(children: [
      FilterChip(
        label: const Text('Todos'),
        selected: selecionado == null,
        onSelected: (_) => onChanged(null),
      ),
      const SizedBox(width: 8),
      FilterChip(
        label: const Text('Score ≥ 2 (alto)'),
        selected: selecionado == 2,
        selectedColor: Colors.red.withValues(alpha: 0.2),
        onSelected: (_) => onChanged(selecionado == 2 ? null : 2),
      ),
      const SizedBox(width: 8),
      FilterChip(
        label: const Text('Score = 1 (médio)'),
        selected: selecionado == 1,
        selectedColor: Colors.orange.withValues(alpha: 0.2),
        onSelected: (_) => onChanged(selecionado == 1 ? null : 1),
      ),
    ]),
  );
}

class _AlertaCard extends StatelessWidget {
  final AlertaRisco alerta;
  final VoidCallback onTap;
  const _AlertaCard({required this.alerta, required this.onTap});

  Color get _cor => alerta.score >= 2 ? Colors.red : Colors.orange;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _cor.withValues(alpha: 0.15),
        child: Icon(Icons.warning_amber_rounded, color: _cor),
      ),
      title: Row(children: [
        Flexible(child: Text(alerta.alunoNome,
          style: const TextStyle(fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        _ScoreBadge(score: alerta.score),
      ]),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: alerta.motivos.map((m) => Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(children: [
            Icon(Icons.circle, size: 6, color: _cor),
            const SizedBox(width: 6),
            Flexible(child: Text(m, style: TextStyle(color: _cor, fontSize: 12))),
          ]),
        )).toList(),
      ),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (alerta.diasSemTreino != null)
          Text('${alerta.diasSemTreino}d',
            style: TextStyle(fontWeight: FontWeight.bold, color: _cor)),
        if (alerta.aderenciaPercent != null)
          Text('${alerta.aderenciaPercent!.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ]),
    ),
  );
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 2 ? Colors.red : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$score',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
