import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/avaliacao_repository.dart';

class AvaliacaoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  const AvaliacaoScreen({super.key, required this.alunoId});
  @override
  ConsumerState<AvaliacaoScreen> createState() => _AvaliacaoScreenState();
}

class _AvaliacaoScreenState extends ConsumerState<AvaliacaoScreen> {
  List<AvaliacaoFisica> _avaliacoes = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await AvaliacaoRepository(ref.read(apiClientProvider)).listar(widget.alunoId);
      setState(() { _avaliacoes = r; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avaliações Físicas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => _NovaAvaliacaoScreen(alunoId: widget.alunoId)));
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _avaliacoes.isEmpty
              ? const Center(child: Text('Nenhuma avaliação registrada.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _avaliacoes.length,
                  itemBuilder: (_, i) {
                    final a = _avaliacoes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(padding: const EdgeInsets.all(16), child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.avaliadoEm?.substring(0, 10) ?? '', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 16, children: [
                            if (a.pesoKg != null) _stat('Peso', '${a.pesoKg} kg'),
                            if (a.alturaCm != null) _stat('Altura', '${a.alturaCm} cm'),
                            if (a.percGordura != null) _stat('% Gordura', '${a.percGordura}%'),
                            if (a.percMassa != null) _stat('% Massa', '${a.percMassa}%'),
                          ]),
                        ],
                      )),
                    );
                  },
                ),
    );
  }

  Widget _stat(String label, String value) => Column(children: [
    Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
  ]);
}

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
  bool _saving = false;

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
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Avaliação')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        _num(_peso, 'Peso (kg)'), _num(_altura, 'Altura (cm)'),
        _num(_gordura, '% Gordura'), _num(_massa, '% Massa muscular'),
        _num(_cintura, 'Cintura (cm)'), _num(_quadril, 'Quadril (cm)'),
        _field(_obs, 'Observações', maxLines: 3),
        const SizedBox(height: 16),
        FilledButton(onPressed: _saving ? null : _salvar, child: const Text('Registrar')),
      ])),
    );
  }

  Widget _num(TextEditingController c, String label) =>
      Padding(padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(controller: c,
          decoration: InputDecoration(labelText: label),
          keyboardType: const TextInputType.numberWithOptions(decimal: true)));

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) =>
      Padding(padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(controller: c, decoration: InputDecoration(labelText: label), maxLines: maxLines));
}
