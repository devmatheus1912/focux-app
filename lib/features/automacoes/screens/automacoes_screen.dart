import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';

import '../../../core/theme/tokens_strip.dart';

import '../../../core/utils/friendly_error.dart';

import '../../../core/widgets/feature_gate.dart';

import '../../../core/widgets/feedback_helper.dart';

import '../../../core/widgets/fx_empty_state.dart';

import '../../../core/widgets/fx_loading.dart';

import '../../../core/widgets/fx_motion.dart';

import '../../../core/widgets/fx_shell_scaffold.dart';

import '../../auth/providers/auth_provider.dart';

import '../../subscription/models/subscription_plan.dart';

import '../data/automacao_repository.dart';

final _repo = Provider(
  (ref) => AutomacaoRepository(ref.read(apiClientProvider)),
);

class AutomacoesScreen extends ConsumerStatefulWidget {
  const AutomacoesScreen({super.key});

  @override
  ConsumerState<AutomacoesScreen> createState() => _AutomacoesScreenState();
}

class _AutomacoesScreenState extends ConsumerState<AutomacoesScreen> {
  List<AutomacaoFluxo> _fluxos = [];

  List<AutomacaoTemplate> _templates = [];

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
      final repo = ref.read(_repo);

      final r = await Future.wait([repo.listar(), repo.templates()]);

      if (!mounted) return;

      setState(() {
        _fluxos = r[0] as List<AutomacaoFluxo>;

        _templates = r[1] as List<AutomacaoTemplate>;

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

  Future<void> _ativar(AutomacaoTemplate t) async {
    try {
      await ref.read(_repo).ativarTemplate(t.id);

      await _load();

      if (!mounted) return;

      FeedbackHelper.showSuccess(context, 'Template "${t.nome}" ativado');
    } catch (e) {
      if (!mounted) return;

      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FeatureGate(
      featureName: 'Automações',

      requiredPlan: SubscriptionPlan.ENTERPRISE,

      capability: 'automacoes',

      child: FxShellScaffold(
        appBar: const FxShellAppBar(
          title: 'Automações',

          subtitle: 'Templates e fluxos ativos',
        ),

        body:
            _loading
                ? const Center(child: FxLoading())
                : _error != null
                ? FxEmptyState(
                  icon: 'alert-triangle',

                  title: 'Erro ao carregar',

                  subtitle: _error,

                  action: FxEmptyAction(
                    label: 'Tentar novamente',
                    onTap: _load,
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _load,

                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,

                      TokensStrip.s2,

                      TokensStrip.s4,

                      96,
                    ),

                    physics: const AlwaysScrollableScrollPhysics(),

                    children: [
                      Text(
                        'Templates',

                        style: AppTypography.inter(
                          fontSize: 14,

                          fontWeight: FontWeight.w700,

                          color: scheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: TokensStrip.s2),

                      ..._templates.asMap().entries.map(
                        (e) => FxStaggerItem(
                          index: e.key,

                          child: Semantics(
                            label: 'Ativar template ${e.value.nome}',

                            button: true,

                            child: FxSatelliteListTile(
                              title: e.value.nome,

                              titleCase: false,

                              leading: Icon(
                                Icons.bolt_outlined,

                                color: scheme.primary,
                              ),

                              subtitle: Text(e.value.descricao),

                              trailing: FilledButton(
                                onPressed: () => _ativar(e.value),

                                child: const Text('Ativar'),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: TokensStrip.s4),

                      Text(
                        'Fluxos ativos',

                        style: AppTypography.inter(
                          fontSize: 14,

                          fontWeight: FontWeight.w700,

                          color: scheme.onSurface,
                        ),
                      ),

                      if (_fluxos.isEmpty)
                        const FxEmptyState(
                          icon: 'zap',

                          title: 'Nenhum fluxo ativo',

                          subtitle:
                              'Ative um template acima para começar automações.',
                        )
                      else
                        ..._fluxos.asMap().entries.map(
                          (e) => FxStaggerItem(
                            index: e.key + _templates.length,

                            child: Semantics(
                              label:
                                  'Fluxo ${e.value.nome}, ${e.value.triggerTipo}',

                              child: FxSatelliteListTile(
                                title: e.value.nome,

                                titleCase: false,

                                leading: Icon(
                                  e.value.ativo
                                      ? Icons.play_circle_rounded
                                      : Icons.pause_circle_rounded,

                                  color: scheme.primary,
                                ),

                                subtitle: Text(e.value.triggerTipo),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }
}
