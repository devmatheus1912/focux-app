import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/anamnese_repository.dart';

class AnamneseScreen extends ConsumerStatefulWidget {
  final int alunoId;
  const AnamneseScreen({super.key, required this.alunoId});
  @override
  ConsumerState<AnamneseScreen> createState() => _AnamneseScreenState();
}

class _AnamneseScreenState extends ConsumerState<AnamneseScreen> {
  final _objetivoCtrl = TextEditingController();
  final _nivelCtrl = TextEditingController();
  final _lesoesCtrl = TextEditingController();
  final _medicCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  bool _loading = true, _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = AnamneseRepository(ref.read(apiClientProvider));
      final a = await repo.buscar(widget.alunoId);
      _objetivoCtrl.text = a.objetivo ?? '';
      _nivelCtrl.text = a.nivelAtividade ?? '';
      _lesoesCtrl.text = a.lesoes ?? '';
      _medicCtrl.text = a.medicamentos ?? '';
      _obsCtrl.text = a.observacoes ?? '';
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    try {
      final repo = AnamneseRepository(ref.read(apiClientProvider));
      await repo.salvar(widget.alunoId, {
        'objetivo': _objetivoCtrl.text, 'nivelAtividade': _nivelCtrl.text,
        'lesoes': _lesoesCtrl.text, 'medicamentos': _medicCtrl.text,
        'observacoes': _obsCtrl.text,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anamnese salva!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Anamnese')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _field(_objetivoCtrl, 'Objetivo', maxLines: 2),
          _field(_nivelCtrl, 'Nível de atividade física'),
          _field(_lesoesCtrl, 'Lesões / Limitações', maxLines: 3),
          _field(_medicCtrl, 'Medicamentos em uso', maxLines: 2),
          _field(_obsCtrl, 'Observações', maxLines: 3),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _salvar,
            child: _saving ? const CircularProgressIndicator() : const Text('Salvar'),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) =>
      Padding(padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(controller: c, decoration: InputDecoration(labelText: label), maxLines: maxLines));
}
