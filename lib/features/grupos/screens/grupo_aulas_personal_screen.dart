import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/grupo_aula_repository.dart';

class GrupoAulasPersonalScreen extends ConsumerStatefulWidget {
  const GrupoAulasPersonalScreen({super.key});

  @override
  ConsumerState<GrupoAulasPersonalScreen> createState() => _GrupoAulasPersonalScreenState();
}

class _GrupoAulasPersonalScreenState extends ConsumerState<GrupoAulasPersonalScreen> {
  List<GrupoAula> _aulas = [];
  bool _loading = true;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final aulas = await GrupoAulaRepository(ref.read(apiClientProvider)).listarPersonal();
      if (mounted) setState(() { _aulas = aulas; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _criar() async {
    final result = await showModalBottomSheet<_NovaAulaResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _NovaAulaSheet(),
    );
    if (result == null) return;

    if (!result.fim.isAfter(result.inicio)) {
      if (mounted) {
        FeedbackHelper.showSnackBar(
          context,
          const SnackBar(content: Text('Horário de fim deve ser depois do início.')),
        );
      }
      return;
    }

    try {
      await GrupoAulaRepository(ref.read(apiClientProvider)).criar(
        titulo: result.titulo,
        descricao: result.descricao,
        inicio: result.inicio,
        fim: result.fim,
        capacidadeMax: result.capacidade,
        localAula: result.local,
      );
      if (mounted) {
        FeedbackHelper.showSnackBar(
          context,
          const SnackBar(content: Text('Aula criada!')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showSnackBar(context, SnackBar(content: Text(friendlyError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FxShellScaffold(
      appBar: FxShellAppBar(title: 'Aulas em grupo', onBack: () => context.pop()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _criar,
        icon: const Icon(Icons.add),
        label: const Text('Nova aula'),
      ),
      body: _loading
          ? const Center(child: FxLoading())
          : RefreshIndicator(
              onRefresh: _load,
              child: _aulas.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Nenhuma aula criada ainda. Toque em + para começar.')),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.all(TokensStrip.s4),
                      itemCount: _aulas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final a = _aulas[i];
                        final lotada = a.inscritos >= a.capacidadeMax;
                        return Card(
                          child: ListTile(
                            title: Text(a.titulo),
                            subtitle: Text('${_fmt(a.inicio)} · ${a.inscritos}/${a.capacidadeMax}'
                                '${a.localAula != null ? ' · ${a.localAula}' : ''}'),
                            trailing: lotada
                                ? const Chip(label: Text('Lotada'))
                                : Chip(label: Text('${a.capacidadeMax - a.inscritos} vagas')),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _NovaAulaResult {
  final String titulo;
  final String? descricao;
  final DateTime inicio;
  final DateTime fim;
  final int capacidade;
  final String? local;

  _NovaAulaResult({
    required this.titulo,
    required this.inicio,
    required this.fim,
    required this.capacidade,
    this.descricao,
    this.local,
  });
}

class _NovaAulaSheet extends StatefulWidget {
  const _NovaAulaSheet();

  @override
  State<_NovaAulaSheet> createState() => _NovaAulaSheetState();
}

class _NovaAulaSheetState extends State<_NovaAulaSheet> {
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _local = TextEditingController();
  final _capacidade = TextEditingController(text: '20');
  late DateTime _inicio;
  late DateTime _fim;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _inicio = DateTime(agora.year, agora.month, agora.day + 1, 7, 0);
    _fim = _inicio.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _local.dispose();
    _capacidade.dispose();
    super.dispose();
  }

  Future<void> _pickInicio() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _inicio,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_inicio),
    );
    if (time == null) return;
    setState(() {
      _inicio = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (!_fim.isAfter(_inicio)) _fim = _inicio.add(const Duration(hours: 1));
    });
  }

  Future<void> _pickFim() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fim,
      firstDate: _inicio,
      lastDate: _inicio.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fim),
    );
    if (time == null) return;
    setState(() {
      _fim = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _salvar() {
    if (_titulo.text.trim().isEmpty) {
      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(content: Text('Título é obrigatório.')),
      );
      return;
    }
    Navigator.pop(context, _NovaAulaResult(
      titulo: _titulo.text.trim(),
      descricao: _descricao.text.trim().isEmpty ? null : _descricao.text.trim(),
      local: _local.text.trim().isEmpty ? null : _local.text.trim(),
      capacidade: int.tryParse(_capacidade.text.trim()) ?? 20,
      inicio: _inicio,
      fim: _fim,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Nova aula em grupo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: _titulo,
              decoration: const InputDecoration(
                labelText: 'Título *',
                hintText: 'Ex: Funcional ao ar livre',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descricao,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickInicio,
                    icon: const Icon(Icons.event),
                    label: Text('Início ${_fmt(_inicio)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFim,
                    icon: const Icon(Icons.event_available),
                    label: Text('Fim ${_fmt(_fim)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _capacidade,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacidade'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _local,
                    decoration: const InputDecoration(
                      labelText: 'Local (opcional)',
                      hintText: 'Studio, Praia, Online…',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _salvar,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: const Text('Criar aula'),
            ),
          ],
        ),
      ),
    );
  }
}
