import 'package:flutter/material.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/utils/fx_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../../../core/widgets/fx_loading.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final medidasProvider = FutureProvider.family<List<MedidaCorporal>, int>((
  ref,
  alunoId,
) async {
  final repo = EvolucaoRepository(ref.read(apiClientProvider));
  return repo.listarMedidas(alunoId);
});

final recordesProvider = FutureProvider.family<List<RecordePessoal>, int>((
  ref,
  alunoId,
) async {
  final repo = EvolucaoRepository(ref.read(apiClientProvider));
  return repo.listarRecordes(alunoId);
});

// ─── Tela principal ───────────────────────────────────────────────────────────

class EvolucaoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const EvolucaoScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  ConsumerState<EvolucaoScreen> createState() => _EvolucaoScreenState();
}

class _EvolucaoScreenState extends ConsumerState<EvolucaoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _variacaoPeso(List<MedidaCorporal> medidas) {
    final comPeso = medidas.where((m) => m.peso != null).toList();
    if (comPeso.length < 2) return '';
    comPeso.sort((a, b) => a.data.compareTo(b.data));
    final primeiro = comPeso.first.peso!;
    final ultimo = comPeso.last.peso!;
    final diff = ultimo - primeiro;
    final sinal = diff >= 0 ? '+' : '';
    return '$sinal${diff.toStringAsFixed(1)}kg desde o início';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final medidasAsync = ref.watch(medidasProvider(widget.alunoId));
    final recordesAsync = ref.watch(recordesProvider(widget.alunoId));

    final variacaoText = medidasAsync.whenOrNull(
      data: (lista) => _variacaoPeso(lista),
    );

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
        elevation: 0,
        title: Text(
          'Evolução — ${widget.alunoNome}',
          style: TextStyle(
            color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primary,
          labelColor: primary,
          unselectedLabelColor:
              isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
          indicatorWeight: 2.5,
          tabs: const [
            Tab(text: 'Medidas Corporais'),
            Tab(text: 'Recordes Pessoais'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (variacaoText != null && variacaoText.isNotEmpty)
            _BannerVariacao(texto: variacaoText),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TabMedidas(
                  alunoId: widget.alunoId,
                  medidasAsync: medidasAsync,
                ),
                _TabRecordes(
                  alunoId: widget.alunoId,
                  recordesAsync: recordesAsync,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary, BrandPalette.deep(primary)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            if (_tabController.index == 0) {
              _mostrarDialogMedida(context);
            } else {
              _mostrarDialogRecorde(context);
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _mostrarDialogMedida(BuildContext context) {
    final pesoCtrl = TextEditingController();
    final gorduraCtrl = TextEditingController();
    final massaMagraCtrl = TextEditingController();
    final abdomenCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Nova Medida Corporal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CampoNumerico(controller: pesoCtrl, label: 'Peso (kg)'),
                  const SizedBox(height: 10),
                  _CampoNumerico(controller: gorduraCtrl, label: '% Gordura'),
                  const SizedBox(height: 10),
                  _CampoNumerico(
                    controller: massaMagraCtrl,
                    label: 'Massa Magra (kg)',
                  ),
                  const SizedBox(height: 10),
                  _CampoNumerico(
                    controller: abdomenCtrl,
                    label: 'Circunf. Abdômen (cm)',
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: obsCtrl,
                    decoration: InputDecoration(
                      labelText: 'Observação',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    final repo = EvolucaoRepository(
                      ref.read(apiClientProvider),
                    );
                    await repo.adicionarMedida(
                      widget.alunoId,
                      peso: double.tryParse(pesoCtrl.text),
                      cintura: double.tryParse(abdomenCtrl.text),
                    );
                    ref.invalidate(medidasProvider(widget.alunoId));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Medida adicionada!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
                    }
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
  }

  void _mostrarDialogRecorde(BuildContext context) {
    final exercicioCtrl = TextEditingController();
    final cargaCtrl = TextEditingController();
    final unidadeCtrl = TextEditingController(text: 'kg');
    final obsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Novo Recorde Pessoal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: exercicioCtrl,
                    decoration: InputDecoration(
                      labelText: 'Exercício',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _CampoNumerico(controller: cargaCtrl, label: 'Carga'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: unidadeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Unidade (kg, reps...)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: obsCtrl,
                    decoration: InputDecoration(
                      labelText: 'Observação',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    final repo = EvolucaoRepository(
                      ref.read(apiClientProvider),
                    );
                    await repo.adicionarRecorde(
                      widget.alunoId,
                      exercicioNome: exercicioCtrl.text.trim(),
                      carga: double.tryParse(cargaCtrl.text),
                      unidade: unidadeCtrl.text.trim(),
                      observacao: obsCtrl.text.trim(),
                    );
                    ref.invalidate(recordesProvider(widget.alunoId));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Recorde adicionado!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
                    }
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
  }
}

// ─── Banner variação ──────────────────────────────────────────────────────────

class _BannerVariacao extends StatelessWidget {
  final String texto;
  const _BannerVariacao({required this.texto});

  @override
  Widget build(BuildContext context) {
    final isPositivo = texto.startsWith('+');
    final cor = isPositivo ? EagleTokens.bad : EagleTokens.good;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: cor.withValues(alpha: 0.12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPositivo ? Icons.trending_up : Icons.trending_down,
            color: cor,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(color: cor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Medidas ──────────────────────────────────────────────────────────────

class _TabMedidas extends StatelessWidget {
  final int alunoId;
  final AsyncValue<List<MedidaCorporal>> medidasAsync;
  const _TabMedidas({required this.alunoId, required this.medidasAsync});

  @override
  Widget build(BuildContext context) {
    return medidasAsync.when(
      loading: () => const FxLoading(),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (lista) {
        if (lista.isEmpty) {
          return const Center(child: Text('Nenhuma medida registrada.'));
        }
        final ordenada = [...lista]..sort((a, b) => b.data.compareTo(a.data));
        final pesos = [...lista]..sort((a, b) => a.data.compareTo(b.data));
        final weightData =
            pesos.where((m) => m.peso != null).map((m) => m.peso!).toList();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: ordenada.length + (weightData.length > 1 ? 1 : 0),
          itemBuilder: (_, i) {
            if (weightData.length > 1 && i == 0) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FxSparkline(
                    data: weightData,
                    width: 320,
                    height: 72,
                    color: EagleTokens.good,
                    fill: true,
                  ),
                ),
              );
            }
            final index = weightData.length > 1 ? i - 1 : i;
            return _CardMedida(medida: ordenada[index]);
          },
        );
      },
    );
  }
}

class _CardMedida extends StatelessWidget {
  final MedidaCorporal medida;
  const _CardMedida({required this.medida});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: EagleTokens.inkMute,
                ),
                const SizedBox(width: 4),
                Text(
                  fxDateShort(DateTime.parse(medida.data)),
                  style: const TextStyle(
                    color: EagleTokens.inkMute,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (medida.peso != null)
                  _Chip(
                    label: 'Peso',
                    valor: '${medida.peso!.toStringAsFixed(1)} kg',
                  ),
                if (medida.cintura != null)
                  _Chip(
                    label: 'Abdômen',
                    valor: '${medida.cintura!.toStringAsFixed(1)} cm',
                  ),
                if (medida.quadril != null)
                  _Chip(
                    label: 'Quadril',
                    valor: '${medida.quadril!.toStringAsFixed(1)} cm',
                  ),
                if (medida.braco != null)
                  _Chip(
                    label: 'Braço',
                    valor: '${medida.braco!.toStringAsFixed(1)} cm',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Recordes ─────────────────────────────────────────────────────────────

class _TabRecordes extends StatelessWidget {
  final int alunoId;
  final AsyncValue<List<RecordePessoal>> recordesAsync;
  const _TabRecordes({required this.alunoId, required this.recordesAsync});

  @override
  Widget build(BuildContext context) {
    return recordesAsync.when(
      loading: () => const FxLoading(),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (lista) {
        if (lista.isEmpty) {
          return const Center(child: Text('Nenhum recorde registrado.'));
        }
        final ordenada = [...lista]..sort((a, b) => b.data.compareTo(a.data));
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: ordenada.length,
          itemBuilder: (_, i) => _CardRecorde(recorde: ordenada[i]),
        );
      },
    );
  }
}

class _CardRecorde extends StatelessWidget {
  final RecordePessoal recorde;
  const _CardRecorde({required this.recorde});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0x33FFD37A),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.emoji_events, color: EagleTokens.gold),
        ),
        title: Text(
          recorde.exercicioNome,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          [
            if (recorde.cargaKg != null)
              '${recorde.cargaKg!.toStringAsFixed(1)}kg',
            if (recorde.repeticoes != null) '${recorde.repeticoes} reps',
            fxDateShort(DateTime.parse(recorde.data)),
          ].join(' × '),
          style: const TextStyle(fontSize: 12, color: EagleTokens.inkMute),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            'NOVO PR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Widgets utilitários ──────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label, valor;
  const _Chip({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: EagleTokens.inkMute),
          ),
          Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _CampoNumerico extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _CampoNumerico({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
