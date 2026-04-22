import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/alimentar_repository.dart';

class PlanoAlimentarDetailScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final PlanoAlimentar plano;

  const PlanoAlimentarDetailScreen({
    super.key,
    required this.alunoId,
    required this.plano,
  });

  @override
  ConsumerState<PlanoAlimentarDetailScreen> createState() =>
      _PlanoAlimentarDetailScreenState();
}

class _PlanoAlimentarDetailScreenState
    extends ConsumerState<PlanoAlimentarDetailScreen> {
  List<Refeicao> _refeicoes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = AlimentarRepository(ref.read(apiClientProvider));
      final lista = await repo.listarRefeicoes(widget.alunoId, widget.plano.id);
      if (mounted) setState(() { _refeicoes = lista; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar refeições: $e')),
        );
      }
    }
  }

  Future<void> _excluir(Refeicao r) async {
    try {
      final repo = AlimentarRepository(ref.read(apiClientProvider));
      await repo.excluirRefeicao(widget.alunoId, widget.plano.id, r.id);
      if (mounted) {
        setState(() => _refeicoes.removeWhere((x) => x.id == r.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refeição removida.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover: $e')),
        );
      }
    }
  }

  void _abrirNovaRefeicao() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NovaRefeicaoSheet(
        alunoId: widget.alunoId,
        planoId: widget.plano.id,
        onSalvo: _load,
      ),
    );
  }

  Future<void> _abrirGerarIa() async {
    final objetivoCtrl = TextEditingController(text: 'Hipertrofia');
    final calCtrl = TextEditingController(text: '2500');
    final refCtrl = TextEditingController(text: '4');
    bool gerando = false;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.auto_awesome, color: EagleTokens.brand),
            SizedBox(width: 8),
            Text('Gerar Dieta com IA')
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('A IA vai criar refeições estruturadas e adicionar diretamente neste plano.'),
              const SizedBox(height: 16),
              TextField(controller: objetivoCtrl, decoration: const InputDecoration(labelText: 'Objetivo (ex: Hipertrofia)')),
              const SizedBox(height: 8),
              TextField(controller: calCtrl, decoration: const InputDecoration(labelText: 'Calorias Alvo'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Nº de Refeições'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton.icon(
              onPressed: gerando ? null : () => Navigator.pop(ctx, true),
              icon: gerando ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
              label: Text(gerando ? 'Gerando...' : 'Gerar'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await AlimentarRepository(ref.read(apiClientProvider)).gerarDietaIa(
        widget.alunoId,
        widget.plano.id,
        objetivo: objetivoCtrl.text,
        caloriasAlvo: int.tryParse(calCtrl.text),
        numeroRefeicoes: int.tryParse(refCtrl.text),
      );
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dieta gerada com sucesso!')));
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na IA: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plano;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(p.nome),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: EagleTokens.brand),
            tooltip: 'Gerar Dieta IA',
            onPressed: _abrirGerarIa,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovaRefeicao,
        icon: const Icon(Icons.add),
        label: const Text('Refeição'),
      ),
      body: Column(
        children: [
          // Resumo de macros do plano
          if (p.caloriasDia != null ||
              p.proteinaG != null ||
              p.carboidratoG != null ||
              p.gorduraG != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (p.caloriasDia != null)
                    _MacroChip('${p.caloriasDia} kcal', EagleTokens.warn),
                  if (p.proteinaG != null)
                    _MacroChip('${p.proteinaG}g prot', EagleTokens.bad),
                  if (p.carboidratoG != null)
                    _MacroChip('${p.carboidratoG}g carbo', EagleTokens.warn),
                  if (p.gorduraG != null)
                    _MacroChip('${p.gorduraG}g gord', Colors.yellow.shade700),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _refeicoes.isEmpty
                    ? const Center(
                        child: Text('Nenhuma refeição cadastrada.\nToque em + para adicionar.',
                            textAlign: TextAlign.center))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                        itemCount: _refeicoes.length,
                        itemBuilder: (_, i) => _RefeicaoCard(
                          refeicao: _refeicoes[i],
                          onDelete: () => _excluir(_refeicoes[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MacroChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        backgroundColor: color.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
}

class _RefeicaoCard extends StatelessWidget {
  final Refeicao refeicao;
  final VoidCallback onDelete;
  const _RefeicaoCard({required this.refeicao, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final r = refeicao;
    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF87171),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(r.nomeRefeicao,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  if (r.horario != null)
                    Row(children: [
                      const Icon(Icons.access_time, size: 14, color: EagleTokens.inkMute),
                      const SizedBox(width: 4),
                      Text(r.horario!,
                          style: const TextStyle(color: EagleTokens.inkMute, fontSize: 13)),
                    ]),
                ],
              ),
              if (r.calorias != null) ...[
                const SizedBox(height: 6),
                Text('${r.calorias} kcal',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600)),
              ],
              if (r.proteinaG != null || r.carboG != null || r.gorduraG != null) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    if (r.proteinaG != null)
                      _MacroChip('${r.proteinaG}g prot', EagleTokens.bad),
                    if (r.carboG != null)
                      _MacroChip('${r.carboG}g carbo', EagleTokens.warn),
                    if (r.gorduraG != null)
                      _MacroChip('${r.gorduraG}g gord', Colors.yellow.shade700),
                  ],
                ),
              ],
              if (r.alimentos != null && r.alimentos!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Text(r.alimentos!,
                    style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Bottom Sheet ----

class _NovaRefeicaoSheet extends ConsumerStatefulWidget {
  final int alunoId;
  final int planoId;
  final VoidCallback onSalvo;

  const _NovaRefeicaoSheet({
    required this.alunoId,
    required this.planoId,
    required this.onSalvo,
  });

  @override
  ConsumerState<_NovaRefeicaoSheet> createState() => _NovaRefeicaoSheetState();
}

class _NovaRefeicaoSheetState extends ConsumerState<_NovaRefeicaoSheet> {
  final _nome = TextEditingController();
  final _horario = TextEditingController();
  final _cal = TextEditingController();
  final _prot = TextEditingController();
  final _carbo = TextEditingController();
  final _gord = TextEditingController();
  final _alimentos = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nome.dispose();
    _horario.dispose();
    _cal.dispose();
    _prot.dispose();
    _carbo.dispose();
    _gord.dispose();
    _alimentos.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nome.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome da refeição é obrigatório.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = AlimentarRepository(ref.read(apiClientProvider));
      await repo.criarRefeicao(widget.alunoId, widget.planoId, {
        'nomeRefeicao': _nome.text.trim(),
        if (_horario.text.isNotEmpty) 'horario': _horario.text.trim(),
        if (_cal.text.isNotEmpty) 'calorias': int.tryParse(_cal.text),
        if (_prot.text.isNotEmpty) 'proteinaG': int.tryParse(_prot.text),
        if (_carbo.text.isNotEmpty) 'carboG': int.tryParse(_carbo.text),
        if (_gord.text.isNotEmpty) 'gorduraG': int.tryParse(_gord.text),
        if (_alimentos.text.isNotEmpty) 'alimentos': _alimentos.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSalvo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nova Refeição',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _field(_nome, 'Nome da refeição *'),
            _field(_horario, 'Horário (ex: 07:30)'),
            _num(_cal, 'Calorias (kcal)'),
            _num(_prot, 'Proteína (g)'),
            _num(_carbo, 'Carboidrato (g)'),
            _num(_gord, 'Gordura (g)'),
            _field(_alimentos, 'Alimentos', maxLines: 4),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _salvar,
              child: _saving
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Adicionar Refeição'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          decoration: InputDecoration(labelText: label),
          maxLines: maxLines,
        ),
      );

  Widget _num(TextEditingController c, String label) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          decoration: InputDecoration(labelText: label),
          keyboardType: TextInputType.number,
        ),
      );
}
