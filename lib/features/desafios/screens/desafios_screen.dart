import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';

import '../../../core/utils/friendly_error.dart';

import '../../../core/widgets/feature_gate.dart';

import '../../../core/widgets/feedback_helper.dart';

import '../../../core/widgets/fx_empty_state.dart';

import '../../../core/widgets/fx_error_state.dart';

import '../../../core/widgets/fx_motion.dart';

import '../../../core/widgets/skeleton_loader.dart';

import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

import '../../auth/providers/auth_provider.dart';

import '../../subscription/models/subscription_plan.dart';

import '../data/desafio_repository.dart';

final _repo = Provider((ref) => DesafioRepository(ref.read(apiClientProvider)));

class DesafiosScreen extends ConsumerStatefulWidget {
  const DesafiosScreen({super.key});

  @override
  ConsumerState<DesafiosScreen> createState() => _DesafiosScreenState();
}

class _DesafiosScreenState extends ConsumerState<DesafiosScreen> {
  List<Desafio> _desafios = [];

  bool _loading = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;

      _error = null;
    });

    try {
      _desafios = await ref.read(_repo).listar();

      if (!mounted) return;

      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;

        _error = friendlyError(e);
      });
    }
  }

  Future<void> _criar() async {
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,

      builder:
          (ctx) => AlertDialog(
            title: const Text('Novo desafio'),

            content: TextField(
              controller: ctrl,

              decoration: const InputDecoration(labelText: 'Título'),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),

              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Criar'),
              ),
            ],
          ),
    );

    if (ok != true || ctrl.text.trim().isEmpty) return;

    try {
      await ref.read(_repo).criar(titulo: ctrl.text.trim());

      await _load();

      if (!mounted) return;

      FeedbackHelper.showSuccess(context, 'Desafio criado');
    } catch (e) {
      if (!mounted) return;

      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _abrirLeaderboard(Desafio d) async {
    try {
      final lb = await ref.read(_repo).leaderboard(d.id);

      if (!mounted) return;

      showModalBottomSheet<void>(
        context: context,

        builder:
            (_) => ListView(
              padding: const EdgeInsets.all(16),

              children: [
                Text(
                  'Ranking — ${d.titulo}',

                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 12),

                if (lb.isEmpty)
                  const Text('Nenhum participante com pontos ainda.')
                else
                  ...lb.asMap().entries.map(
                    (e) => ListTile(
                      leading: CircleAvatar(child: Text('${e.key + 1}')),

                      title: Text(e.value['alunoNome'] as String? ?? ''),

                      trailing: Text('${e.value['pontos']} pts'),
                    ),
                  ),
              ],
            ),
      );
    } catch (e) {
      if (!mounted) return;

      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);

    final scheme = Theme.of(context).colorScheme;

    return fxScreenA11yScope(
      label: 'Desafios',
      child: FeatureGate(
        featureName: 'Desafios',

        requiredPlan: SubscriptionPlan.ENTERPRISE,

        capability: 'comunidadeGrupos',

        child: FxShellScaffold(
          useMesh: true,

          appBar: const FxShellAppBar(
            title: 'Desafios',

            subtitle: 'Ranking e metas da comunidade',
          ),

        floatingActionButton: Semantics(
          label: 'Criar novo desafio',

          button: true,

          child: FloatingActionButton.extended(
            onPressed: _criar,

            icon: const Icon(Icons.add),

            label: const Text('Novo'),
          ),
        ),

        body:
            _loading
                ? const SkeletonList(count: 5)
                : _error != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: scheme.primary,
                  message: _error!,
                  onRetry: _load,
                )
                : _desafios.isEmpty
                ? FxEmptyState(
                  icon: 'spark',

                  title: 'Nenhum desafio',

                  subtitle: 'Crie o primeiro desafio para engajar seus alunos.',

                  action: FxEmptyAction(label: 'Criar desafio', onTap: _criar),
                )
                : RefreshIndicator(
                  onRefresh: _load,

                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,

                      TokensStrip.s2,

                      TokensStrip.s4,

                      96,
                    ),

                    itemCount: _desafios.length,

                    itemBuilder: (_, i) {
                      final d = _desafios[i];

                      return FxStaggerItem(
                        index: i,

                        child: Semantics(
                          label: 'Desafio ${d.titulo}',

                          button: true,

                          child: FxSatelliteListTile(
                            title: d.titulo,

                            titleCase: false,

                            onTap: () => _abrirLeaderboard(d),

                            leading: Icon(
                              Icons.emoji_events_outlined,

                              color: scheme.primary,
                            ),

                            subtitle: Text(
                              '${d.tipo} · meta ${d.metaPontos} pts',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}
