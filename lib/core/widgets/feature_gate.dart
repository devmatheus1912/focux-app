import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/subscription/models/subscription_plan.dart';
import '../../features/planos/providers/plano_features_provider.dart';
import '../../features/planos/data/planos_repository.dart';

class FeatureGate extends ConsumerWidget {
  final SubscriptionPlan requiredPlan;
  final Widget child;
  final Widget? lockedBuilder;
  final String featureName;

  /// Capability flag específica (ex.: "iaCopiloto", "whiteLabel"). Quando
  /// passado, o gate consulta a flag no backend (via `/api/planos/me`)
  /// e ignora `requiredPlan`. Use isto para evitar inferir features a
  /// partir do nome do plano.
  final String? capability;

  const FeatureGate({
    super.key,
    required this.requiredPlan,
    required this.child,
    this.lockedBuilder,
    required this.featureName,
    this.capability,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuresAsync = ref.watch(planoFeaturesProvider);

    // BUG-01: em estado de loading, mostra indicador mas não bloqueia.
    if (featuresAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // BUG-01: em estado de erro, NÃO colapsar para FREE.
    // Usuário pagante não pode ser bloqueado por falha de rede.
    // Mostra tela de retry em vez de "Acesso Restrito".
    if (featuresAsync.hasError) {
      return _ErrorRetryScreen(
        onRetry: () => ref.invalidate(planoFeaturesProvider),
      );
    }

    final features = featuresAsync.value;
    // Se value for null aqui (não deveria após hasError check), libera acesso
    // conservadoramente — melhor falhar aberto do que bloquear pagante.
    if (features == null) {
      return child;
    }

    final currentPlan = features.plano;

    final hasAccess = capability != null
        ? _resolveCapability(features, capability!)
        : currentPlan.canAccess(requiredPlan);

    if (hasAccess) {
      return child;
    }

    if (lockedBuilder != null) {
      return lockedBuilder!;
    }

    // BUG-02+11: Default Locked UI com Scaffold (back button) + CTA → /planos
    return _LockedScreen(
      featureName: featureName,
      requiredPlan: requiredPlan,
    );
  }

  bool _resolveCapability(PlanoFeatures f, String cap) {
    switch (cap) {
      case 'financeiro':   return f.financeiro;
      case 'agenda':       return f.agenda;
      case 'relatorios':   return f.relatorios;
      case 'whiteLabel':   return f.whiteLabel;
      case 'iaCopiloto':   return f.iaCopiloto;
      case 'iaIlimitada':  return f.iaIlimitada;
      default:             return false;
    }
  }
}

// ── Tela de erro de rede ────────────────────────────────────────────────────

class _ErrorRetryScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorRetryScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Falha ao verificar plano',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verifique sua conexão e tente novamente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tela de acesso restrito ─────────────────────────────────────────────────

class _LockedScreen extends StatelessWidget {
  final String featureName;
  final SubscriptionPlan requiredPlan;

  const _LockedScreen({
    required this.featureName,
    required this.requiredPlan,
  });

  @override
  Widget build(BuildContext context) {
    final planLabel = requiredPlan == SubscriptionPlan.ENTERPRISE
        ? 'Enterprise'
        : 'Premium';

    return Scaffold(
      // BUG-02: AppBar com botão de voltar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Acesso Restrito',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '"$featureName" requer o plano $planLabel.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                // BUG-11: CTA → /planos (não /paywall)
                ElevatedButton(
                  onPressed: () => context.push('/planos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B4A9E),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Ver planos',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
