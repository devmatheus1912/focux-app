import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/equipe_repository.dart';
import '../models/tenant_membro.dart';

final equipeRepositoryProvider = Provider(
  (ref) => EquipeRepository(ref.read(apiClientProvider)),
);

class EquipeScreen extends ConsumerStatefulWidget {
  const EquipeScreen({super.key});

  @override
  ConsumerState<EquipeScreen> createState() => _EquipeScreenState();
}

class _EquipeScreenState extends ConsumerState<EquipeScreen> {
  List<TenantMembro> _membros = [];
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
      _membros = await ref.read(equipeRepositoryProvider).listar();
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

  Future<void> _convidar() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Convidar assistente'),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Convidar'),
              ),
            ],
          ),
    );

    if (ok != true || ctrl.text.trim().isEmpty) return;

    try {
      await ref
          .read(equipeRepositoryProvider)
          .convidar(email: ctrl.text.trim());
      await _load();
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Convite enviado');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FeatureGate(
      featureName: 'Equipe',
      requiredPlan: SubscriptionPlan.ENTERPRISE,
      capability: 'equipeRbac',
      child: fxScreenA11yScope(
        label: 'Equipe',
        child: FxShellScaffold(
          appBar: const FxShellAppBar(
            title: 'Equipe',
            subtitle: 'Assistentes e permissões',
          ),
          floatingActionButton: Semantics(
            label: 'Convidar membro da equipe',
            button: true,
            child: FloatingActionButton.extended(
              onPressed: _convidar,
              icon: const Icon(Icons.person_add),
              label: const Text('Convidar'),
            ),
          ),
          body:
              _loading
                  ? const Center(child: FxLoading())
                  : _error != null
                  ? FxErrorState(
                    chromeOnDark:
                        Theme.of(context).brightness == Brightness.dark,
                    primary: scheme.primary,
                    message: _error!,
                    onRetry: _load,
                    title: 'Não conseguimos carregar a equipe',
                  )
                  : _membros.isEmpty
                  ? FxEmptyState(
                    icon: 'users',
                    title: 'Nenhum membro',
                    subtitle: 'Convide assistentes para escalar sua operação.',
                    action: FxEmptyAction(label: 'Convidar', onTap: _convidar),
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
                      itemCount: _membros.length,
                      itemBuilder: (_, i) {
                        final membro = _membros[i];
                        return FxStaggerItem(
                          index: i,
                          child: Semantics(
                            label: 'Membro ${membro.userEmail}',
                            child: FxSatelliteListTile(
                              accent: scheme.primary,
                              title: membro.userEmail,
                              titleCase: false,
                              subtitle: Text(
                                '${membro.role} · ${membro.status}',
                              ),
                              leading: Icon(
                                Icons.person_outline,
                                color: scheme.primary,
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
