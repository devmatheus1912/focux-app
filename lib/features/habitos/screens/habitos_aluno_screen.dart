import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../features/subscription/models/subscription_plan.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lista = await ref.read(_repoProvider).meusHabitos();
      if (!mounted) return;
      setState(() {
        _habitos = lista;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  Future<void> _toggle(Habito h) async {
    try {
      final result = await ref.read(_repoProvider).toggleHoje(h.id);
      setState(() {
        _habitos = _habitos
            .map((x) => x.id == h.id
                ? Habito(
                    id: x.id,
                    titulo: x.titulo,
                    descricao: x.descricao,
                    icone: x.icone,
                    tipo: x.tipo,
                    metaDiaria: x.metaDiaria,
                    metaSemanal: x.metaSemanal,
                    feitosNaSemana: result.feito
                        ? x.feitosNaSemana + 1
                        : (x.feitosNaSemana - 1).clamp(0, 7),
                    feitoHoje: result.feito,
                    streakAtual: result.streak,
                    badgeSemana: result.streak >= 7,
                  )
                : x)
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      featureName: 'Habit Coaching',
      requiredPlan: SubscriptionPlan.PREMIUM,
      capability: 'habitCoaching',
      child: Scaffold(
      appBar: AppBar(title: const Text('Meus hábitos')),
      body: _loading
          ? const Center(child: FxLoading())
          : _error != null
              ? FxEmptyState(
                  icon: 'alert-triangle',
                  title: 'Erro ao carregar',
                  subtitle: _error,
                  action: FxEmptyAction(label: 'Tentar novamente', onTap: _carregar),
                )
              : RefreshIndicator(
              onRefresh: _carregar,
              child: _habitos.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        FxEmptyState(
                          icon: 'dumbbell',
                          title: 'Nenhum hábito ainda',
                          subtitle:
                              'Seu personal ainda não cadastrou hábitos. Avise para começar sua jornada.',
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
                                  Semantics(
                                    label: h.feitoHoje
                                        ? 'Desmarcar hábito ${h.titulo}'
                                        : 'Marcar hábito ${h.titulo}',
                                    child: Checkbox(
                                      value: h.feitoHoje,
                                      onChanged: (_) => _toggle(h),
                                    ),
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '🔥 ${h.streakAtual}',
                                      style: const TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
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
      ),
    );
  }
}
