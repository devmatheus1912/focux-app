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
      if (mounted) {
        setState(() {
          _resumo = resumo;
          _recentes = recentes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _contatarDetrator(NpsItem item) {
    final alunoId = item.alunoId;
    if (alunoId == null) return;
    final nome = item.alunoNome;
    if (nome != null && nome.isNotEmpty) {
      context.push('/alunos/$alunoId/chat', extra: nome);
    } else {
      context.push('/alunos/$alunoId');
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
                  if (_resumo != null) ...[
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _segmento('Promotores', _resumo!.promotores, _resumo!.total,
                              const Color(0xFF2E7D32), Icons.sentiment_very_satisfied),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _segmento('Neutros', _resumo!.neutros, _resumo!.total,
                              const Color(0xFFF9A825), Icons.sentiment_neutral),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _segmento('Detratores', _resumo!.detratores, _resumo!.total,
                              const Color(0xFFC62828), Icons.sentiment_very_dissatisfied),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text('Feedback recente', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ..._recentes.map((n) {
                    if (n.score <= 6) {
                      return _detratorCard(n);
                    }
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _scoreColor(n.score),
                        foregroundColor: Colors.white,
                        child: Text('${n.score}'),
                      ),
                      title: Text(n.comentario?.isNotEmpty == true ? n.comentario! : 'Sem comentário'),
                      subtitle: Text('${_classify(n.score)} · ${n.criadoEm}'),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _detratorCard(NpsItem n) {
    final detractorColor = const Color(0xFFC62828);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: detractorColor.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: detractorColor,
                  foregroundColor: Colors.white,
                  radius: 18,
                  child: Text('${n.score}', style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.alunoNome?.isNotEmpty == true ? n.alunoNome! : 'Detrator',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Detrator · ${n.criadoEm}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (n.comentario?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(
                n.comentario!,
                style: const TextStyle(height: 1.4),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              'Playbook: entre em contato para entender o problema e recuperar a confiança.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: n.alunoId != null ? () => _contatarDetrator(n) : null,
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Entrar em contato'),
            ),
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

  Widget _segmento(String label, int valor, int total, Color color, IconData icon) {
    final pct = total > 0 ? (valor * 100 / total).round() : 0;
    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text('$valor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text('$pct% · $label',
                style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  String _classify(int score) {
    if (score >= 9) return 'Promotor';
    if (score >= 7) return 'Neutro';
    return 'Detrator';
  }

  Color _scoreColor(int score) {
    if (score >= 9) return const Color(0xFF2E7D32);
    if (score >= 7) return const Color(0xFFF9A825);
    return const Color(0xFFC62828);
  }
}
