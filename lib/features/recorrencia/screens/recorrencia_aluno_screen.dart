import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/recorrencia_repository.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

class RecorrenciaAlunoScreen extends ConsumerStatefulWidget {
  const RecorrenciaAlunoScreen({super.key});

  @override
  ConsumerState<RecorrenciaAlunoScreen> createState() =>
      _RecorrenciaAlunoScreenState();
}

class _RecorrenciaAlunoScreenState
    extends ConsumerState<RecorrenciaAlunoScreen> {
  RecorrenciaAssinatura? _assinatura;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final a =
          await RecorrenciaRepository(ref.read(apiClientProvider)).minha();
      if (mounted) {
        setState(() {
          _assinatura = a;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return fxScreenA11yScope(
      label: 'Minha assinatura',
      child: FxShellScaffold(
        appBar: FxShellAppBar(
          title: 'Minha assinatura',
          onBack: () => context.pop(),
        ),
        body:
            _loading
                ? const SkeletonList(count: 4)
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: isDark,
                  primary: primary,
                  title: 'Não conseguimos carregar sua assinatura',
                  message: _erro!,
                  onRetry: _load,
                )
                : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      if (_assinatura == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 48),
                          child: FxEmptyState(
                            icon: 'coin',
                            title: 'Sem assinatura recorrente ainda',
                            subtitle:
                                'Seu personal ainda não configurou cobrança automática mensal. '
                                'Você pode pedir a ele(a) para criar uma para automatizar pagamentos via Mercado Pago.',
                          ),
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
                                  Icon(
                                    Icons.subscriptions,
                                    color: primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Status: ${_assinatura!.status}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Valor: R\$ ${_assinatura!.valor.toStringAsFixed(2)}/mês',
                              ),
                              if (_assinatura!.proximaCobranca != null)
                                Text(
                                  'Próxima cobrança: ${_assinatura!.proximaCobranca}',
                                ),
                              const SizedBox(height: 20),
                              if (_assinatura!.initPoint != null &&
                                  _assinatura!.status == 'PENDENTE')
                                FilledButton.icon(
                                  onPressed: () async {
                                    try {
                                      final uri = Uri.parse(
                                        _assinatura!.initPoint!,
                                      );
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      }
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      FeedbackHelper.showError(
                                        context,
                                        friendlyError(e),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.payment),
                                  label: const Text(
                                    'Autorizar pagamento recorrente',
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }
}
