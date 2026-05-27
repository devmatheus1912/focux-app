import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/habito_repository.dart';

final _repoProvider = Provider(
  (ref) => HabitoRepository(ref.read(apiClientProvider)),
);

class HabitosAlunoScreen extends ConsumerStatefulWidget {
  const HabitosAlunoScreen({super.key});

  @override
  ConsumerState<HabitosAlunoScreen> createState() => _HabitosAlunoScreenState();
}

class _HabitosAlunoScreenState extends ConsumerState<HabitosAlunoScreen> {
  List<Habito> _habitos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final lista = await ref.read(_repoProvider).meusHabitos();
      if (!mounted) return;
      setState(() {
        _habitos = lista;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(Habito h) async {
    try {
      final novo = await ref.read(_repoProvider).toggleHoje(h.id);
      setState(() {
        _habitos = _habitos
            .map((x) => x.id == h.id
                ? Habito(
                    id: x.id,
                    titulo: x.titulo,
                    descricao: x.descricao,
                    icone: x.icone,
                    metaSemanal: x.metaSemanal,
                    feitosNaSemana: novo
                        ? x.feitosNaSemana + 1
                        : (x.feitosNaSemana - 1).clamp(0, 7),
                    feitoHoje: novo,
                  )
                : x)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus hábitos')),
      body: _loading
          ? const Center(child: FxLoading())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: _habitos.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'Seu personal ainda não cadastrou hábitos.\nAvise para começar a sua jornada de consistência.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _habitos.length,
                      itemBuilder: (_, i) {
                        final h = _habitos[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _toggle(h),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: h.feitoHoje,
                                    onChanged: (_) => _toggle(h),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          h.titulo,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            decoration: h.feitoHoje
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        if (h.descricao != null &&
                                            h.descricao!.isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 2),
                                            child: Text(
                                              h.descricao!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: .12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${h.feitosNaSemana}/${h.metaSemanal}',
                                      style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
