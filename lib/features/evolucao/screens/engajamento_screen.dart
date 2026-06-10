import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

class EngajamentoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const EngajamentoScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  ConsumerState<EngajamentoScreen> createState() => _EngajamentoScreenState();
}

class _EngajamentoScreenState extends ConsumerState<EngajamentoScreen> {
  int _dias = 30;
  List<EventoEngajamento> _eventos = [];
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
      final repo = EvolucaoRepository(ref.read(apiClientProvider));
      final eventos = await repo.engajamento(widget.alunoId, dias: _dias);
      if (mounted) {
        setState(() {
          _eventos = eventos;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  IconData _iconForTipo(String tipo) {
    switch (tipo) {
      case 'CHECKIN_CONCLUIDO':
        return Icons.fitness_center;
      case 'TREINO_INICIADO':
        return Icons.play_arrow;
      default:
        return Icons.circle;
    }
  }

  String _formatarDataHora(String dataHora) {
    try {
      final dt = DateTime.parse(dataHora).toLocal();
      final dd = dt.day.toString().padLeft(2, '0');
      final mm = dt.month.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$dd/$mm $hh:$min';
    } catch (_) {
      return dataHora.length >= 16 ? dataHora.substring(0, 16) : dataHora;
    }
  }

  @override
  Widget build(BuildContext context) {
    return fxScreenA11yScope(
      label: 'Engajamento — ${widget.alunoNome}',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Engajamento — ${widget.alunoNome}',
          onBack: () => safePopOrGo(context, '/evolucao'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<int>(
                value: _dias,
                underline: const SizedBox(),
                items:
                    [30, 60, 90]
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text('$d dias'),
                          ),
                        )
                        .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _dias = v);
                    _load();
                  }
                },
              ),
            ),
          ],
        ),
        body:
            _loading
                ? const Center(child: FxLoading())
                : _erro != null
                ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    FxEmptyState(
                      icon: 'cloud',
                      title: 'Não conseguimos carregar o engajamento',
                      subtitle: _erro!,
                      action: FxEmptyAction(
                        label: 'Tentar novamente',
                        onTap: _load,
                      ),
                    ),
                  ],
                )
                : _eventos.isEmpty
                ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    FxEmptyState(
                      icon: 'chart',
                      title: 'Nenhum evento registrado',
                      subtitle:
                          'Check-ins e treinos do aluno aparecerão aqui nos últimos dias.',
                    ),
                  ],
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(TokensStrip.s4),
                  itemCount: _eventos.length,
                  itemBuilder: (_, i) {
                    final e = _eventos[i];
                    final primary = Theme.of(context).colorScheme.primary;
                    return FxSatelliteListTile(
                      accent: primary,
                      title: e.descricao,
                      titleCase: false,
                      subtitle: Text(e.tipo),
                      trailing: Text(
                        _formatarDataHora(e.dataHora),
                        style: const TextStyle(
                          fontSize: 12,
                          color: TokensStrip.textSecondary,
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          _iconForTipo(e.tipo),
                          color: primary,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
