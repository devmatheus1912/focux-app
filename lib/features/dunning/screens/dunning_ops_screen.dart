import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/dunning_repository.dart';

final dunningRepositoryProvider = Provider(
  (ref) => DunningRepository(ref.read(apiClientProvider)),
);

class DunningOpsScreen extends ConsumerStatefulWidget {
  const DunningOpsScreen({super.key});

  @override
  ConsumerState<DunningOpsScreen> createState() => _DunningOpsScreenState();
}

class _DunningOpsScreenState extends ConsumerState<DunningOpsScreen> {
  DunningSnapshot? _snapshot;
  List<DunningFalha> _falhas = [];
  bool _loading = true;
  int? _marcandoId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(dunningRepositoryProvider);
      final results = await Future.wait([repo.me(), repo.falhas()]);
      if (!mounted) return;
      setState(() {
        _snapshot = results[0] as DunningSnapshot;
        _falhas = results[1] as List<DunningFalha>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(content: Text(friendlyError(e))),
      );
    }
  }

  Future<void> _marcarRecuperado(DunningFalha falha) async {
    setState(() => _marcandoId = falha.id);
    try {
      await ref.read(dunningRepositoryProvider).marcarRecuperado(falha.id);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Falha marcada como recuperada.');
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(content: Text(friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _marcandoId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snap = _snapshot;
    return FxShellScaffold(
      appBar: FxShellAppBar(
        title: 'Recuperação de pagamentos',
        onBack: () => context.pop(),
      ),
      body: _loading
          ? const Center(child: FxLoading())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: ListView(
                padding: const EdgeInsets.all(TokensStrip.s4),
                children: [
                  if (snap != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Taxa de recuperação: ${snap.recoveryRate.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${snap.abertas} falhas em aberto · ${snap.recuperadas} recuperadas de ${snap.total}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Falhas em aberto (${_falhas.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (_falhas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('Nenhuma falha de pagamento em aberto.'),
                      ),
                    )
                  else
                    ..._falhas.map((f) {
                      final recuperando = _marcandoId == f.id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(f.contexto),
                          subtitle: Text(
                            [
                              if (f.motivo != null && f.motivo!.isNotEmpty)
                                f.motivo!,
                              if (f.valor != null)
                                'R\$ ${f.valor!.toStringAsFixed(2)}',
                              if (f.alunoId != null) 'Aluno #${f.alunoId}',
                              'Tentativa ${f.tentativa}',
                            ].join(' · '),
                          ),
                          trailing: FilledButton.tonal(
                            onPressed:
                                recuperando
                                    ? null
                                    : () => _marcarRecuperado(f),
                            child:
                                recuperando
                                    ? const FxLoading(size: 18, strokeWidth: 2)
                                    : const Text('Recuperado'),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
