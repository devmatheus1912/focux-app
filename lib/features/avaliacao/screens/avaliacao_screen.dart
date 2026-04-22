import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/avaliacao_repository.dart';

String _formatarData(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final dt = DateTime.parse(iso);
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    if (dt.hour == 0 && dt.minute == 0 && dt.second == 0) {
      return '$d/$m/$y';
    }
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  } catch (_) {
    return iso.length >= 10 ? iso.substring(0, 10) : iso;
  }
}

class AvaliacaoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const AvaliacaoScreen({super.key, required this.alunoId, this.alunoNome = 'Aluno'});
  @override
  ConsumerState<AvaliacaoScreen> createState() => _AvaliacaoScreenState();
}

class _AvaliacaoScreenState extends ConsumerState<AvaliacaoScreen> {
  List<AvaliacaoFisica> _avaliacoes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await AvaliacaoRepository(ref.read(apiClientProvider)).listar(widget.alunoId);
      setState(() { _avaliacoes = r; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _excluir(AvaliacaoFisica a) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir avaliação'),
        content: Text('Deseja excluir a avaliação de ${_formatarData(a.avaliadoEm)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EagleTokens.bad),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await AvaliacaoRepository(ref.read(apiClientProvider)).excluir(widget.alunoId, a.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avaliação excluída.')));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir: $e')));
    }
  }

  Future<void> _editar(AvaliacaoFisica a) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EditarAvaliacaoSheet(
        alunoId: widget.alunoId,
        avaliacao: a,
      ),
    );
    _load();
  }

  void _irParaComparativo() {
    context.push('/alunos/${widget.alunoId}/evolucao-comparativo',
        extra: widget.alunoNome);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? EagleTokens.darkInk : EagleTokens.ink),
        title: const Text('Avaliações Físicas'),
        actions: [
          IconButton(
            icon: Icon(Icons.compare_arrows, color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
            tooltip: 'Comparativo evolutivo',
            onPressed: _irParaComparativo,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => _NovaAvaliacaoScreen(alunoId: widget.alunoId)));
          _load();
        },
        backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: EagleTokens.brand))
          : _avaliacoes.isEmpty
              ? const Center(child: Text('Nenhuma avaliação registrada.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _avaliacoes.length,
                  itemBuilder: (_, i) {
                    final a = _avaliacoes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _formatarData(a.avaliadoEm),
                                    style: const TextStyle(color: EagleTokens.inkMute),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'editar') _editar(a);
                                    if (v == 'excluir') _excluir(a);
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'editar', child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    )),
                                    PopupMenuItem(value: 'excluir', child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 18, color: EagleTokens.bad),
                                        SizedBox(width: 8),
                                        Text('Excluir', style: TextStyle(color: EagleTokens.bad)),
                                      ],
                                    )),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(spacing: 16, runSpacing: 8, children: [
                              if (a.pesoKg != null) _stat('Peso', '${a.pesoKg} kg'),
                              if (a.alturaCm != null) _stat('Altura', '${a.alturaCm} cm'),
                              if (a.imc != null) _stat('IMC', a.imc!.toStringAsFixed(1)),
                              if (a.percGordura != null) _stat('% Gordura', '${a.percGordura}%'),
                              if (a.percentualGordura != null) _stat('% Gordura V2', '${a.percentualGordura}%'),
                              if (a.percMassa != null) _stat('% Massa', '${a.percMassa}%'),
                              if (a.massaMuscular != null) _stat('Massa Musc.', '${a.massaMuscular} kg'),
                              if (a.cinturaCm != null) _stat('Cintura', '${a.cinturaCm} cm'),
                              if (a.circCintura != null) _stat('Circ. Cintura', '${a.circCintura} cm'),
                              if (a.quadrilCm != null) _stat('Quadril', '${a.quadrilCm} cm'),
                              if (a.circQuadril != null) _stat('Circ. Quadril', '${a.circQuadril} cm'),
                              if (a.circBraco != null) _stat('Circ. Braço', '${a.circBraco} cm'),
                              if (a.circCoxa != null) _stat('Circ. Coxa', '${a.circCoxa} cm'),
                            ]),
                            if (a.observacoesAvaliacao != null && a.observacoesAvaliacao!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(a.observacoesAvaliacao!,
                                  style: const TextStyle(color: EagleTokens.inkMute, fontSize: 12)),
                            ],
                            if (a.enviadaAoAluno) ...[
                              const SizedBox(height: 4),
                              const Row(children: [
                                Icon(Icons.check_circle, size: 14, color: EagleTokens.good),
                                SizedBox(width: 4),
                                Text('Enviada ao aluno',
                                    style: TextStyle(fontSize: 11, color: EagleTokens.good)),
                              ]),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _stat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    Text(label, style: const TextStyle(color: EagleTokens.inkMute, fontSize: 12)),
  ]);
}

// ─────────────────────────────────────────────
// Bottom sheet de edição
// ─────────────────────────────────────────────

class _EditarAvaliacaoSheet extends ConsumerStatefulWidget {
  final int alunoId;
  final AvaliacaoFisica avaliacao;
  const _EditarAvaliacaoSheet({required this.alunoId, required this.avaliacao});
  @override
  ConsumerState<_EditarAvaliacaoSheet> createState() => _EditarAvaliacaoSheetState();
}

class _EditarAvaliacaoSheetState extends ConsumerState<_EditarAvaliacaoSheet> {
  late final TextEditingController _peso, _altura, _gordura, _massa,
      _cintura, _quadril, _obs, _imc, _percGordura, _massaMuscular,
      _circCintura, _circQuadril, _circBraco, _circCoxa, _obsAvaliacao;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.avaliacao;
    _peso = TextEditingController(text: a.pesoKg?.toString() ?? '');
    _altura = TextEditingController(text: a.alturaCm?.toString() ?? '');
    _gordura = TextEditingController(text: a.percGordura?.toString() ?? '');
    _massa = TextEditingController(text: a.percMassa?.toString() ?? '');
    _cintura = TextEditingController(text: a.cinturaCm?.toString() ?? '');
    _quadril = TextEditingController(text: a.quadrilCm?.toString() ?? '');
    _obs = TextEditingController(text: a.observacoes ?? '');
    _imc = TextEditingController(text: a.imc?.toString() ?? '');
    _percGordura = TextEditingController(text: a.percentualGordura?.toString() ?? '');
    _massaMuscular = TextEditingController(text: a.massaMuscular?.toString() ?? '');
    _circCintura = TextEditingController(text: a.circCintura?.toString() ?? '');
    _circQuadril = TextEditingController(text: a.circQuadril?.toString() ?? '');
    _circBraco = TextEditingController(text: a.circBraco?.toString() ?? '');
    _circCoxa = TextEditingController(text: a.circCoxa?.toString() ?? '');
    _obsAvaliacao = TextEditingController(text: a.observacoesAvaliacao ?? '');
  }

  @override
  void dispose() {
    _peso.dispose(); _altura.dispose(); _gordura.dispose(); _massa.dispose();
    _cintura.dispose(); _quadril.dispose(); _obs.dispose();
    _imc.dispose(); _percGordura.dispose(); _massaMuscular.dispose();
    _circCintura.dispose(); _circQuadril.dispose(); _circBraco.dispose();
    _circCoxa.dispose(); _obsAvaliacao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    try {
      await AvaliacaoRepository(ref.read(apiClientProvider)).editar(
        widget.alunoId,
        widget.avaliacao.id,
        {
          if (_peso.text.isNotEmpty) 'pesoKg': double.tryParse(_peso.text),
          if (_altura.text.isNotEmpty) 'alturaCm': double.tryParse(_altura.text),
          if (_gordura.text.isNotEmpty) 'percGordura': double.tryParse(_gordura.text),
          if (_massa.text.isNotEmpty) 'percMassa': double.tryParse(_massa.text),
          if (_cintura.text.isNotEmpty) 'cinturaCm': double.tryParse(_cintura.text),
          if (_quadril.text.isNotEmpty) 'quadrilCm': double.tryParse(_quadril.text),
          if (_obs.text.isNotEmpty) 'observacoes': _obs.text,
          if (_imc.text.isNotEmpty) 'imc': double.tryParse(_imc.text),
          if (_percGordura.text.isNotEmpty) 'percentualGordura': double.tryParse(_percGordura.text),
          if (_massaMuscular.text.isNotEmpty) 'massaMuscular': double.tryParse(_massaMuscular.text),
          if (_circCintura.text.isNotEmpty) 'circCintura': double.tryParse(_circCintura.text),
          if (_circQuadril.text.isNotEmpty) 'circQuadril': double.tryParse(_circQuadril.text),
          if (_circBraco.text.isNotEmpty) 'circBraco': double.tryParse(_circBraco.text),
          if (_circCoxa.text.isNotEmpty) 'circCoxa': double.tryParse(_circCoxa.text),
          if (_obsAvaliacao.text.isNotEmpty) 'observacoesAvaliacao': _obsAvaliacao.text,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avaliação atualizada!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Editar Avaliação',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 8),
            _secao('Dados Básicos'),
            _num(_peso, 'Peso (kg)'), _num(_altura, 'Altura (cm)'), _num(_imc, 'IMC'),
            _secao('Composição Corporal'),
            _num(_gordura, '% Gordura (legacy)'), _num(_percGordura, '% Gordura'),
            _num(_massa, '% Massa muscular'), _num(_massaMuscular, 'Massa muscular (kg)'),
            _secao('Circunferências (cm)'),
            _num(_cintura, 'Cintura'), _num(_circCintura, 'Circ. Cintura'),
            _num(_quadril, 'Quadril'), _num(_circQuadril, 'Circ. Quadril'),
            _num(_circBraco, 'Circ. Braço'), _num(_circCoxa, 'Circ. Coxa'),
            _secao('Observações'),
            _field(_obs, 'Observações gerais', maxLines: 2),
            _field(_obsAvaliacao, 'Observações da avaliação', maxLines: 2),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _salvar,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Salvar'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _secao(String titulo) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: EagleTokens.inkMute)),
  );

  Widget _num(TextEditingController c, String label) =>
      Padding(padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          decoration: InputDecoration(labelText: label),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ));

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) =>
      Padding(padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(controller: c, decoration: InputDecoration(labelText: label), maxLines: maxLines));
}

// ─────────────────────────────────────────────
// Nova avaliação
// ─────────────────────────────────────────────

class _NovaAvaliacaoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  const _NovaAvaliacaoScreen({required this.alunoId});
  @override
  ConsumerState<_NovaAvaliacaoScreen> createState() => _NovaAvaliacaoScreenState();
}

class _NovaAvaliacaoScreenState extends ConsumerState<_NovaAvaliacaoScreen> {
  final _peso = TextEditingController(), _altura = TextEditingController(),
      _gordura = TextEditingController(), _massa = TextEditingController(),
      _cintura = TextEditingController(), _quadril = TextEditingController(),
      _obs = TextEditingController();
  final _imc = TextEditingController(), _percGordura = TextEditingController(),
      _massaMuscular = TextEditingController(), _circCintura = TextEditingController(),
      _circQuadril = TextEditingController(), _circBraco = TextEditingController(),
      _circCoxa = TextEditingController(), _obsAvaliacao = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _peso.dispose(); _altura.dispose(); _gordura.dispose(); _massa.dispose();
    _cintura.dispose(); _quadril.dispose(); _obs.dispose();
    _imc.dispose(); _percGordura.dispose(); _massaMuscular.dispose();
    _circCintura.dispose(); _circQuadril.dispose(); _circBraco.dispose();
    _circCoxa.dispose(); _obsAvaliacao.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    try {
      await AvaliacaoRepository(ref.read(apiClientProvider)).registrar(widget.alunoId, {
        if (_peso.text.isNotEmpty) 'pesoKg': double.tryParse(_peso.text),
        if (_altura.text.isNotEmpty) 'alturaCm': double.tryParse(_altura.text),
        if (_gordura.text.isNotEmpty) 'percGordura': double.tryParse(_gordura.text),
        if (_massa.text.isNotEmpty) 'percMassa': double.tryParse(_massa.text),
        if (_cintura.text.isNotEmpty) 'cinturaCm': double.tryParse(_cintura.text),
        if (_quadril.text.isNotEmpty) 'quadrilCm': double.tryParse(_quadril.text),
        if (_obs.text.isNotEmpty) 'observacoes': _obs.text,
        if (_imc.text.isNotEmpty) 'imc': double.tryParse(_imc.text),
        if (_percGordura.text.isNotEmpty) 'percentualGordura': double.tryParse(_percGordura.text),
        if (_massaMuscular.text.isNotEmpty) 'massaMuscular': double.tryParse(_massaMuscular.text),
        if (_circCintura.text.isNotEmpty) 'circCintura': double.tryParse(_circCintura.text),
        if (_circQuadril.text.isNotEmpty) 'circQuadril': double.tryParse(_circQuadril.text),
        if (_circBraco.text.isNotEmpty) 'circBraco': double.tryParse(_circBraco.text),
        if (_circCoxa.text.isNotEmpty) 'circCoxa': double.tryParse(_circCoxa.text),
        if (_obsAvaliacao.text.isNotEmpty) 'observacoesAvaliacao': _obsAvaliacao.text,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? EagleTokens.darkInk : EagleTokens.ink),title: const Text('Nova Avaliação')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _secao('Dados Básicos'),
          _num(_peso, 'Peso (kg)'), _num(_altura, 'Altura (cm)'), _num(_imc, 'IMC'),
          _secao('Composição Corporal'),
          _num(_gordura, '% Gordura (legacy)'), _num(_percGordura, '% Gordura'),
          _num(_massa, '% Massa muscular'), _num(_massaMuscular, 'Massa muscular (kg)'),
          _secao('Circunferências (cm)'),
          _num(_cintura, 'Cintura'), _num(_circCintura, 'Circ. Cintura'),
          _num(_quadril, 'Quadril'), _num(_circQuadril, 'Circ. Quadril'),
          _num(_circBraco, 'Circ. Braço'), _num(_circCoxa, 'Circ. Coxa'),
          _secao('Observações'),
          _field(_obs, 'Observações gerais', maxLines: 2),
          _field(_obsAvaliacao, 'Observações da avaliação', maxLines: 2),
          const SizedBox(height: 16),
          FilledButton(onPressed: _saving ? null : _salvar, child: const Text('Registrar')),
          const SizedBox(height: 24),
        ],
      )),
    );
  }

  Widget _secao(String titulo) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: EagleTokens.inkMute)),
  );

  Widget _num(TextEditingController c, String label) =>
      Padding(padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(controller: c,
          decoration: InputDecoration(labelText: label),
          keyboardType: const TextInputType.numberWithOptions(decimal: true)));

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) =>
      Padding(padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(controller: c, decoration: InputDecoration(labelText: label), maxLines: maxLines));
}
