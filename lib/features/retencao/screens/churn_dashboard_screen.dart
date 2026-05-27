import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/retencao_repository.dart';

final retencaoRepositoryProvider = Provider(
  (ref) => RetencaoRepository(ref.read(apiClientProvider)),
);

class ChurnDashboardScreen extends ConsumerStatefulWidget {
  const ChurnDashboardScreen({super.key});

  @override
  ConsumerState<ChurnDashboardScreen> createState() =>
      _ChurnDashboardScreenState();
}

class _ChurnDashboardScreenState extends ConsumerState<ChurnDashboardScreen> {
  List<RetencaoAlunoScore> _scores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ref.read(retencaoRepositoryProvider).listarBase();
      if (mounted) setState(() { _scores = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _riscoColor(String risco) => switch (risco) {
    'ALTO' => Colors.redAccent,
    'MEDIO' => Colors.orangeAccent,
    _ => Colors.greenAccent,
  };

  @override
  Widget build(BuildContext context) {
    return FxShellScaffold(
      appBar: FxShellAppBar(title: 'Saúde da base'),
      body: _loading
          ? const Center(child: FxLoading())
          : RefreshIndicator(
              onRefresh: _load,
              child: _scores.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Text(
                            'Scores serão calculados no domingo.\nCadastre alunos e aguarde a primeira rotina.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(TokensStrip.s4),
                      itemCount: _scores.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final s = _scores[i];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: _riscoColor(s.riscoChurn).withValues(alpha: 0.35),
                            ),
                          ),
                          title: Text(s.alunoNome),
                          subtitle: Text(
                            'Score ${s.scoreAtual} · ${s.riscoChurn}${s.delta != 0 ? ' (${s.delta > 0 ? '+' : ''}${s.delta})' : ''}',
                          ),
                          trailing: Chip(
                            label: Text(s.riscoChurn),
                            backgroundColor: _riscoColor(s.riscoChurn).withValues(alpha: 0.15),
                          ),
                          onTap: () => context.push('/alunos/${s.alunoId}'),
                        );
                      },
                    ),
            ),
    );
  }
}
