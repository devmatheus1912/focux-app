import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/winback_repository.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

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
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final entries = await ref.read(winbackRepositoryProvider).log();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = friendlyError(e);
      });
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
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final mute = chrome.mute;

    return fxScreenA11yScope(
      label: 'Win-back automático',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Win-back automático',
          subtitle: 'Push de reengajamento',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
        ),
        body:
            _loading
                ? Center(child: FxLoading(color: primary))
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: _erro!,
                  onRetry: _carregar,
                )
                : RefreshIndicator(
                  color: primary,
                  onRefresh: _carregar,
                  child: ListView(
                    padding: const EdgeInsets.all(TokensStrip.s4),
                    children: [
                      FxSatellitePanel(
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
                            Text(
                              'Automação FCM ativa',
                              style: AppTypography.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: chrome.ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Push de reengajamento para alunos inativos e lembretes de trial.',
                              style: TextStyle(height: 1.45, color: mute),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => context.push('/retencao'),
                              icon: const Icon(
                                Icons.health_and_safety_outlined,
                              ),
                              label: const Text('Ver saúde da base'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Histórico de envios (${_entries.length})',
                        style: AppTypography.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: chrome.ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_entries.isEmpty)
                        const FxEmptyState(
                          icon: 'send',
                          title: 'Nenhum envio ainda',
                          subtitle:
                              'Quando a automação disparar, os registros aparecem aqui.',
                        )
                      else
                        ..._entries.map(
                          (entry) => FxSatelliteListTile(
                            isThreeLine: true,
                            leading: CircleAvatar(
                              backgroundColor: primary.withValues(alpha: 0.12),
                              foregroundColor: primary,
                              child: const Icon(Icons.send_outlined, size: 20),
                            ),
                            title: entry.alunoNome,
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
                                    fontSize: 11,
                                    color: mute.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
      ),
    );
  }
}
