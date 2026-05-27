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
    final tituloCtrl = TextEditingController();
    final localCtrl = TextEditingController();
    var inicio = DateTime.now().add(const Duration(days: 1));
    var fim = inicio.add(const Duration(hours: 1));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova aula em grupo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: tituloCtrl, decoration: const InputDecoration(labelText: 'Título')),
              TextField(controller: localCtrl, decoration: const InputDecoration(labelText: 'Local')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Criar')),
        ],
      ),
    );
    if (ok != true || tituloCtrl.text.trim().isEmpty) return;

    try {
      await GrupoAulaRepository(ref.read(apiClientProvider)).criar(
        titulo: tituloCtrl.text.trim(),
        inicio: inicio,
        fim: fim,
        localAula: localCtrl.text.trim().isEmpty ? null : localCtrl.text.trim(),
      );
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
              child: ListView.separated(
                padding: const EdgeInsets.all(TokensStrip.s4),
                itemCount: _aulas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final a = _aulas[i];
                  return Card(
                    child: ListTile(
                      title: Text(a.titulo),
                      subtitle: Text('${_fmt(a.inicio)} · ${a.inscritos}/${a.capacidadeMax} inscritos'
                          '${a.localAula != null ? ' · ${a.localAula}' : ''}'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
