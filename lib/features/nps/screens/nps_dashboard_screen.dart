import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/nps_repository.dart';

class NpsDashboardScreen extends ConsumerStatefulWidget {
  const NpsDashboardScreen({super.key});

  @override
  ConsumerState<NpsDashboardScreen> createState() => _NpsDashboardScreenState();
}

class _NpsDashboardScreenState extends ConsumerState<NpsDashboardScreen> {
  NpsResumo? _resumo;
  List<NpsItem> _recentes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = NpsRepository(ref.read(apiClientProvider));
      final resumo = await repo.resumo();
      final recentes = await repo.recentes();
      if (mounted) setState(() { _resumo = resumo; _recentes = recentes; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return FxShellScaffold(
      appBar: FxShellAppBar(title: 'NPS & Satisfação', onBack: () => context.pop()),
      body: _loading
          ? const Center(child: FxLoading())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(TokensStrip.s4),
                children: [
                  if (_resumo != null)
                    Card(
                      color: primary.withValues(alpha: 0.08),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _kpi('NPS', _resumo!.npsScore.toStringAsFixed(1)),
                            _kpi('Média', _resumo!.media.toStringAsFixed(1)),
                            _kpi('Respostas', '${_resumo!.total}'),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text('Feedback recente', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ..._recentes.map((n) => ListTile(
                    leading: CircleAvatar(child: Text('${n.score}')),
                    title: Text(n.comentario?.isNotEmpty == true ? n.comentario! : 'Sem comentário'),
                    subtitle: Text(n.criadoEm),
                  )),
                ],
              ),
            ),
    );
  }

  Widget _kpi(String label, String value) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );
}
