import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class MarcoModel {
  final int id;
  final String titulo;
  final int ordem;
  final bool concluido;

  MarcoModel({
    required this.id,
    required this.titulo,
    required this.ordem,
    required this.concluido,
  });

  factory MarcoModel.fromJson(Map<String, dynamic> j) => MarcoModel(
    id: j['id'],
    titulo: j['titulo'],
    ordem: j['ordem'],
    concluido: j['concluido'] ?? false,
  );
}

class TrilhaModel {
  final int id;
  final int alunoId;
  final String titulo;
  final String? descricao;
  final String metaTipo;
  final double? metaValor;
  final double valorAtual;
  final double percentualConclusao;
  final bool concluida;
  final String? dataFim;
  final List<MarcoModel> marcos;

  TrilhaModel({
    required this.id,
    required this.alunoId,
    required this.titulo,
    this.descricao,
    required this.metaTipo,
    this.metaValor,
    required this.valorAtual,
    required this.percentualConclusao,
    required this.concluida,
    this.dataFim,
    required this.marcos,
  });

  factory TrilhaModel.fromJson(Map<String, dynamic> j) => TrilhaModel(
    id: j['id'],
    alunoId: j['alunoId'],
    titulo: j['titulo'],
    descricao: j['descricao'],
    metaTipo: j['metaTipo'] ?? 'TREINOS',
    metaValor:
        j['metaValor'] != null ? (j['metaValor'] as num).toDouble() : null,
    valorAtual: (j['valorAtual'] ?? 0).toDouble(),
    percentualConclusao: (j['percentualConclusao'] ?? 0).toDouble(),
    concluida: j['concluida'] ?? false,
    dataFim: j['dataFim'],
    marcos:
        (j['marcos'] as List? ?? [])
            .map((e) => MarcoModel.fromJson(e as Map<String, dynamic>))
            .toList(),
  );
}

// ─── Providers ────────────────────────────────────────────────────────────────

final trilhasAlunoProvider = FutureProvider.family<List<TrilhaModel>, int>((
  ref,
  alunoId,
) async {
  final api = ref.read(apiClientProvider);
  final res = await api.dio.get('/api/trilhas/aluno/$alunoId');
  return (res.data as List)
      .map((e) => TrilhaModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class TrilhasScreen extends ConsumerWidget {
  final int alunoId;
  final String alunoNome;

  const TrilhasScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trilhasAsync = ref.watch(trilhasAlunoProvider(alunoId));

    return FxShellScaffold(
      useMesh: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Trilhas de Progresso', style: TextStyle(fontSize: 16)),
            Text(
              alunoNome,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCriarTrilha(context, ref),
          ),
        ],
      ),
      body: trilhasAsync.when(
        loading: () => const FxLoading(),
        error:
            (e, _) => Center(
              child: Text(
                'Erro: $e',
                style: const TextStyle(color: EagleTokens.bad),
              ),
            ),
        data: (trilhas) {
          if (trilhas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route, size: 64, color: const Color(0xFFD1D5DB)),
                  const SizedBox(height: TokensStrip.s4),
                  const Text(
                    'Nenhuma trilha criada ainda',
                    style: TextStyle(color: TokensStrip.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  FxLiquidPrimaryButton(
                    label: 'Criar primeira trilha',
                    icon: Icons.add,
                    expand: false,
                    onPressed: () => _showCriarTrilha(context, ref),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(TokensStrip.s4),
            itemCount: trilhas.length,
            itemBuilder:
                (ctx, i) =>
                    _TrilhaCard(trilha: trilhas[i], alunoId: alunoId, ref: ref),
          );
        },
      ),
    );
  }

  void _showCriarTrilha(BuildContext context, WidgetRef ref) {
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String metaTipo = 'TREINOS';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setState) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  20,
                  16,
                  MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nova Trilha',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    TextField(
                      controller: tituloCtrl,
                      decoration: FxInputDeco.build(
                        context,
                        'Título da trilha',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: FxInputDeco.build(
                        context,
                        'Descrição (opcional)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: metaTipo,
                      decoration: FxInputDeco.build(context, 'Tipo de meta'),
                      items: const [
                        DropdownMenuItem(
                          value: 'TREINOS',
                          child: Text('Número de treinos'),
                        ),
                        DropdownMenuItem(
                          value: 'PESO',
                          child: Text('Meta de peso'),
                        ),
                        DropdownMenuItem(
                          value: 'MEDIDA',
                          child: Text('Meta de medida'),
                        ),
                        DropdownMenuItem(
                          value: 'CUSTOMIZADO',
                          child: Text('Customizado'),
                        ),
                      ],
                      onChanged: (v) => setState(() => metaTipo = v!),
                    ),
                    const SizedBox(height: 20),
                    FxLiquidPrimaryButton(
                      label: 'Criar Trilha',
                      onPressed: () async {
                        if (tituloCtrl.text.trim().isEmpty) return;
                        final api = ref.read(apiClientProvider);
                        await api.dio.post(
                          '/api/trilhas',
                          data: {
                            'alunoId': alunoId,
                            'titulo': tituloCtrl.text.trim(),
                            'descricao':
                                descCtrl.text.trim().isEmpty
                                    ? null
                                    : descCtrl.text.trim(),
                            'metaTipo': metaTipo,
                          },
                        );
                        ref.invalidate(trilhasAlunoProvider(alunoId));
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}

// ─── TrilhaCard ───────────────────────────────────────────────────────────────

class _TrilhaCard extends StatelessWidget {
  final TrilhaModel trilha;
  final int alunoId;
  final WidgetRef ref;

  const _TrilhaCard({
    required this.trilha,
    required this.alunoId,
    required this.ref,
  });

  Color get _progressColor {
    if (trilha.concluida) return const Color(0xFF22C55E);
    if (trilha.percentualConclusao >= 70) return const Color(0xFF1EC8C8);
    if (trilha.percentualConclusao >= 30) return const Color(0xFFF59E0B);
    return const Color(0xFF717171);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    trilha.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (trilha.concluida)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '✓ CONCLUÍDA',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF22C55E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            if (trilha.descricao != null) ...[
              const SizedBox(height: 4),
              Text(
                trilha.descricao!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF717171)),
              ),
            ],
            const SizedBox(height: 14),

            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progresso',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF4B5563),
                  ),
                ),
                Text(
                  '${trilha.percentualConclusao.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _progressColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: (trilha.percentualConclusao / 100).clamp(0.0, 1.0),
              backgroundColor: _progressColor.withValues(alpha: 0.1),
              color: _progressColor,
              minHeight: 6,
              borderRadius: BorderRadius.circular(4),
            ),

            // Marcos
            if (trilha.marcos.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Marcos',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ...trilha.marcos.map(
                (m) => _MarcoTile(
                  marco: m,
                  trilhaId: trilha.id,
                  alunoId: alunoId,
                  ref: ref,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MarcoTile extends StatelessWidget {
  final MarcoModel marco;
  final int trilhaId;
  final int alunoId;
  final WidgetRef ref;

  const _MarcoTile({
    required this.marco,
    required this.trilhaId,
    required this.alunoId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: IconButton(
        icon: Icon(
          marco.concluido ? Icons.check_circle : Icons.radio_button_unchecked,
          color:
              marco.concluido ? const Color(0xFF22C55E) : TokensStrip.textSecondary,
        ),
        onPressed:
            marco.concluido
                ? null
                : () async {
                  final api = ref.read(apiClientProvider);
                  await api.dio.post(
                    '/api/trilhas/$trilhaId/marcos/${marco.id}/concluir',
                  );
                  ref.invalidate(trilhasAlunoProvider(alunoId));
                },
      ),
      title: Text(
        marco.titulo,
        style: TextStyle(
          fontSize: 13,
          decoration: marco.concluido ? TextDecoration.lineThrough : null,
          color: marco.concluido ? TokensStrip.textSecondary : null,
        ),
      ),
    );
  }
}
