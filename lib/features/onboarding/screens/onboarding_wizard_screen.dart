import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/onboarding_repository.dart';

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends ConsumerState<OnboardingWizardScreen> {
  OnboardingWizard? _wizard;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final w = await OnboardingRepository(ref.read(apiClientProvider)).wizard();
      if (mounted) setState(() { _wizard = w; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _concluir() async {
    await OnboardingRepository(ref.read(apiClientProvider)).marcarCompleto();
    if (mounted) context.go('/dashboard/personal');
  }

  /// Empurra a rota e recarrega o wizard quando o usuário voltar.
  Future<void> _abrirStep(String route) async {
    await context.push<dynamic>(route);
    if (mounted) await _load();
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'person': return Icons.person_outline;
      case 'person_add': return Icons.person_add_outlined;
      case 'fitness_center': return Icons.fitness_center;
      case 'inventory_2': return Icons.inventory_2_outlined;
      case 'repeat': return Icons.repeat;
      case 'attach_money': return Icons.attach_money;
      case 'link': return Icons.link;
      default: return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return FxShellScaffold(
      appBar: FxShellAppBar(
        title: 'Setup D0',
        subtitle: 'Primeira vitória em 10 min',
        onBack: () => context.go('/dashboard/personal'),
      ),
      body: _loading
          ? const Center(child: FxLoading())
          : _wizard == null
              ? const Center(child: Text('Não foi possível carregar o wizard.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _wizard!.totalCount > 0 ? _wizard!.completedCount / _wizard!.totalCount : 0,
                        backgroundColor: primary.withValues(alpha: 0.15),
                        color: primary,
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(TokensStrip.s4),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Text(
                              '${_wizard!.progressPercent}% concluído',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text('Próximo: ${_wizard!.nextActionLabel}'),
                            const SizedBox(height: 16),
                            ..._wizard!.steps.map((s) => Card(
                              child: ListTile(
                                leading: Icon(_iconFor(s.icon), color: s.completed ? Colors.green : primary),
                                title: Text(s.title),
                                subtitle: Text('${s.description}\n~${s.estimatedMinutes} min'),
                                isThreeLine: true,
                                trailing: s.completed
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : Icon(Icons.arrow_forward_ios, size: 16, color: primary),
                                onTap: s.completed ? null : () => _abrirStep(s.actionRoute),
                              ),
                            )),
                          ],
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(TokensStrip.s4),
                          child: FilledButton(
                            onPressed: _wizard!.allStepsDone || _wizard!.wizardCompleto
                                ? _concluir
                                : () => _abrirStep(_wizard!.nextActionRoute),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: primary,
                            ),
                            child: Text(_wizard!.allStepsDone ? 'Concluir setup' : 'Continuar setup'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
