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
                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                          if (a.enviadaAoAluno) ...[
                            const SizedBox(height: 4),
                            const Row(children: [
                              Icon(Icons.check_circle, size: 14, color: Colors.green),
                              SizedBox(width: 4),
                              Text('Enviada ao aluno',
                                  style: TextStyle(fontSize: 11, color: Colors.green)),
                            ]),
                          ],
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
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Avaliação')),
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
    child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
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
