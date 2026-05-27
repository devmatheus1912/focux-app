import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final a = await RecorrenciaRepository(ref.read(apiClientProvider)).minha();
      if (mounted) setState(() { _assinatura = a; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return FxShellScaffold(
      appBar: FxShellAppBar(title: 'Minha assinatura', onBack: () => context.pop()),
      body: _loading
          ? const Center(child: FxLoading())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: _assinatura == null
                  ? const Center(child: Text('Seu personal ainda não configurou recorrência.'))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Status: ${_assinatura!.status}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('Valor: R\$ ${_assinatura!.valor.toStringAsFixed(2)}/mês'),
                        if (_assinatura!.proximaCobranca != null)
                          Text('Próxima cobrança: ${_assinatura!.proximaCobranca}'),
                        const SizedBox(height: 24),
                        if (_assinatura!.initPoint != null && _assinatura!.status == 'PENDENTE')
                          FilledButton.icon(
                            onPressed: () async {
                              try {
                                final uri = Uri.parse(_assinatura!.initPoint!);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              } catch (e) {
                                if (mounted) {
                                  FeedbackHelper.showSnackBar(context, SnackBar(content: Text(friendlyError(e))));
                                }
                              }
                            },
                            icon: const Icon(Icons.payment),
                            label: const Text('Autorizar pagamento recorrente'),
                            style: FilledButton.styleFrom(backgroundColor: primary),
                          ),
                      ],
                    ),
            ),
    );
  }
}
