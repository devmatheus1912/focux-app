import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/winback_repository.dart';

final winbackRepositoryProvider = Provider(
  (ref) => WinbackRepository(ref.read(apiClientProvider)),
);

class WinbackScreen extends ConsumerStatefulWidget {
  const WinbackScreen({super.key});

  @override
  ConsumerState<WinbackScreen> createState() => _WinbackScreenState();
}

class _WinbackScreenState extends ConsumerState<WinbackScreen> {
  List<WinbackLogEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final entries = await ref.read(winbackRepositoryProvider).log();
      if (!mounted) return;
      setState(() {
        _entries = entries;
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

  String _formatTipo(String tipo) {
    return switch (tipo) {
      'ALUNO_INATIVO_7D' => 'Inativo 7 dias',
      'ALUNO_INATIVO_30D' => 'Inativo 30 dias',
      'ALUNO_INATIVO_60D' => 'Inativo 60 dias',
      _ => tipo.replaceAll('_', ' '),
    };
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return FxShellScaffold(
      appBar: FxShellAppBar(
        title: 'Win-back automático',
        onBack: () => context.pop(),
      ),
      body: _loading
          ? const Center(child: FxLoading())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: ListView(
                padding: const EdgeInsets.all(TokensStrip.s4),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            color: primary,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Automação FCM ativa',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Push de reengajamento para alunos inativos e lembretes de trial.',
                            style: TextStyle(
                              height: 1.45,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => context.push('/retencao'),
                            icon: const Icon(Icons.health_and_safety_outlined),
                            label: const Text('Ver saúde da base'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Histórico de envios (${_entries.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (_entries.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Nenhum envio registrado ainda.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._entries.map(
                      (entry) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          isThreeLine: true,
                          leading: CircleAvatar(
                            backgroundColor: primary.withValues(alpha: 0.12),
                            foregroundColor: primary,
                            child: const Icon(Icons.send_outlined, size: 20),
                          ),
                          title: Text(entry.alunoNome),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(_formatTipo(entry.tipo)),
                              if (entry.mensagem.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  entry.mensagem,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                entry.enviadoEm,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
