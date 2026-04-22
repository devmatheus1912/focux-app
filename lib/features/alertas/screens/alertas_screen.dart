import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
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

  Future<void> _resolverAlerta(AlertaRisco alerta) async {
    try {
      await AlertasRepository(ref.read(apiClientProvider)).resolver(alerta.alunoId);
      setState(() => _alertas.removeWhere((a) => a.alunoId == alerta.alunoId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerta resolvido!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _enviarMensagemChat(AlertaRisco alerta) async {
    final ctrl = TextEditingController(text: 'Olá ${alerta.alunoNome.split(' ').first}! Vi que faz um tempo que não treina. Que tal retomarmos hoje? Estou aqui para ajudar! 💪');
    bool enviando = false;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Enviar mensagem'),
          content: TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton.icon(
              onPressed: enviando ? null : () => Navigator.pop(ctx, true),
              icon: enviando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send),
              label: Text(enviando ? 'Enviando...' : 'Enviar'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || ctrl.text.trim().isEmpty) return;

    try {
      await AlertasRepository(ref.read(apiClientProvider)).enviarMensagemChat(alerta.alunoId, ctrl.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mensagem enviada!')));
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
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                          const Icon(Icons.check_circle, size: 64, color: EagleTokens.good),
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
                          onResolver: () => _resolverAlerta(_filtrados[i]),
                          onMensagemChat: () => _enviarMensagemChat(_filtrados[i]),
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
      const Icon(Icons.settings, size: 16, color: EagleTokens.inkMute),
      const SizedBox(width: 6),
      Text('Sem treino > ${config.diasSemTreino} dias  ·  Aderência < ${config.aderenciaMinima}%',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: EagleTokens.inkMute)),
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
        selectedColor: EagleTokens.bad.withValues(alpha: 0.2),
        onSelected: (_) => onChanged(selecionado == 2 ? null : 2),
      ),
      const SizedBox(width: 8),
      FilterChip(
        label: const Text('Score = 1 (médio)'),
        selected: selecionado == 1,
        selectedColor: EagleTokens.warn.withValues(alpha: 0.2),
        onSelected: (_) => onChanged(selecionado == 1 ? null : 1),
      ),
    ]),
  );
}

class _AlertaCard extends StatelessWidget {
  final AlertaRisco alerta;
  final VoidCallback onTap;
  final VoidCallback onResolver;
  final VoidCallback onMensagemChat;

  const _AlertaCard({required this.alerta, required this.onTap, required this.onResolver, required this.onMensagemChat});

  Color get _cor => alerta.score >= 2 ? EagleTokens.bad : EagleTokens.warn;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Column(
        children: [
          ListTile(
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
                  style: const TextStyle(fontSize: 11, color: EagleTokens.inkMute)),
            ]),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: EagleTokens.inkMute.withValues(alpha: 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onMensagemChat,
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Mensagem'),
                ),
                TextButton.icon(
                  onPressed: onResolver,
                  icon: const Icon(Icons.check_circle_outline, size: 16, color: EagleTokens.good),
                  label: const Text('Resolvido', style: TextStyle(color: EagleTokens.good)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ScoreBadge extends StatelessWidget {
  final int score;
  const _ScoreBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 2 ? EagleTokens.bad : EagleTokens.warn;
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
