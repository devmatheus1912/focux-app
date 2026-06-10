import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/recorrencia_repository.dart';

class RecorrenciaAlunoScreen extends ConsumerStatefulWidget {
  const RecorrenciaAlunoScreen({super.key});

  @override
  ConsumerState<RecorrenciaAlunoScreen> createState() => _RecorrenciaAlunoScreenState();
}

class _RecorrenciaAlunoScreenState extends ConsumerState<RecorrenciaAlunoScreen> {
  RecorrenciaAssinatura? _assinatura;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final a = await RecorrenciaRepository(ref.read(apiClientProvider)).minha();
      if (mounted) setState(() { _assinatura = a; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _erro = friendlyError(e); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return FxShellScaffold(
      appBar: FxShellAppBar(title: 'Minha assinatura', onBack: () => context.pop()),
      body: _loading
          ? const Center(child: FxLoading())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (_erro != null)
                    _empty(
                      icon: Icons.cloud_off_outlined,
                      title: 'Não conseguimos carregar sua assinatura.',
                      subtitle: _erro!,
                      cta: 'Tentar novamente',
                      onCta: _load,
                      color: EagleTokens.bad,
                    )
                  else if (_assinatura == null)
                    _empty(
                      icon: Icons.subscriptions_outlined,
                      title: 'Sem assinatura recorrente ainda',
                      subtitle: 'Seu personal ainda não configurou cobrança automática mensal. '
                          'Você pode pedir a ele(a) para criar uma para automatizar pagamentos via Mercado Pago.',
                      color: primary,
                    )
                  else
                    FxSatellitePanel(
                      accent: primary,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.subscriptions, color: primary, size: 22),
                                const SizedBox(width: 8),
                                Text('Status: ${_assinatura!.status}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Valor: R\$ ${_assinatura!.valor.toStringAsFixed(2)}/mês'),
                            if (_assinatura!.proximaCobranca != null)
                              Text('Próxima cobrança: ${_assinatura!.proximaCobranca}'),
                            const SizedBox(height: 20),
                            if (_assinatura!.initPoint != null && _assinatura!.status == 'PENDENTE')
                              FilledButton.icon(
                                onPressed: () async {
                                  try {
                                    final uri = Uri.parse(_assinatura!.initPoint!);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    FeedbackHelper.showError(context, friendlyError(e));
                                  }
                                },
                                icon: const Icon(Icons.payment),
                                label: const Text('Autorizar pagamento recorrente'),
                                style: FilledButton.styleFrom(backgroundColor: primary),
                              ),
                          ],
                        ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _empty({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? cta,
    VoidCallback? onCta,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(icon, size: 56, color: color.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).hintColor)),
          if (cta != null && onCta != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onCta,
              icon: const Icon(Icons.refresh),
              label: Text(cta),
            ),
          ],
        ],
      ),
    );
  }
}
