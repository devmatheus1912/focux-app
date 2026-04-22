import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final medidasProvider = FutureProvider.family<List<MedidaCorporal>, int>((ref, alunoId) async {
  final repo = EvolucaoRepository(ref.read(apiClientProvider));
  return repo.listarMedidas(alunoId);
});

final recordesProvider = FutureProvider.family<List<RecordePessoal>, int>((ref, alunoId) async {
  final repo = EvolucaoRepository(ref.read(apiClientProvider));
  return repo.listarRecordes(alunoId);
});

// ─── Tela principal ───────────────────────────────────────────────────────────

class EvolucaoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const EvolucaoScreen({super.key, required this.alunoId, required this.alunoNome});

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
        title: Text('Evolução — ${widget.alunoNome}', style: TextStyle(color: isDark ? EagleTokens.darkInk : EagleTokens.ink, fontWeight: FontWeight.w700, fontSize: 18)),
        iconTheme: IconThemeData(color: isDark ? EagleTokens.darkInk : EagleTokens.ink),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: EagleTokens.brand,
          labelColor: EagleTokens.brand,
          unselectedLabelColor: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
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
                _TabMedidas(alunoId: widget.alunoId, medidasAsync: medidasAsync),
                _TabRecordes(alunoId: widget.alunoId, recordesAsync: recordesAsync),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [EagleTokens.brand, EagleTokens.brandInk]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: EagleTokens.brand.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
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
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Medida Corporal'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _CampoNumerico(controller: pesoCtrl, label: 'Peso (kg)'),
            const SizedBox(height: 10),
            _CampoNumerico(controller: gorduraCtrl, label: '% Gordura'),
            const SizedBox(height: 10),
            _CampoNumerico(controller: massaMagraCtrl, label: 'Massa Magra (kg)'),
            const SizedBox(height: 10),
            _CampoNumerico(controller: abdomenCtrl, label: 'Circunf. Abdômen (cm)'),
            const SizedBox(height: 10),
            TextField(
              controller: obsCtrl,
              decoration: const InputDecoration(
                labelText: 'Observação',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = EvolucaoRepository(ref.read(apiClientProvider));
                await repo.adicionarMedida(
                  widget.alunoId,
                  peso: double.tryParse(pesoCtrl.text),
                  cintura: double.tryParse(abdomenCtrl.text),
                );
                ref.invalidate(medidasProvider(widget.alunoId));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medida adicionada!')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')));
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
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Recorde Pessoal'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: exercicioCtrl,
              decoration: const InputDecoration(
                labelText: 'Exercício',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            _CampoNumerico(controller: cargaCtrl, label: 'Carga'),
            const SizedBox(height: 10),
            TextField(
              controller: unidadeCtrl,
              decoration: const InputDecoration(
                labelText: 'Unidade (kg, reps...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: obsCtrl,
              decoration: const InputDecoration(
                labelText: 'Observação',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final repo = EvolucaoRepository(ref.read(apiClientProvider));
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
                    const SnackBar(content: Text('Recorde adicionado!')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')));
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
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(isPositivo ? Icons.trending_up : Icons.trending_down, color: cor, size: 18),
        const SizedBox(width: 6),
        Text(texto, style: TextStyle(color: cor, fontWeight: FontWeight.w600)),
      ]),
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro: $e')),
      data: (lista) {
        if (lista.isEmpty) {
          return const Center(child: Text('Nenhuma medida registrada.'));
        }
        final ordenada = [...lista]..sort((a, b) => b.data.compareTo(a.data));
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: ordenada.length,
          itemBuilder: (_, i) => _CardMedida(medida: ordenada[i]),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.calendar_today, size: 14, color: EagleTokens.inkMute),
            const SizedBox(width: 4),
            Text(
              medida.data.length >= 10 ? medida.data.substring(0, 10) : medida.data,
              style: const TextStyle(color: EagleTokens.inkMute, fontSize: 12),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 12, runSpacing: 8, children: [
            if (medida.peso != null)
              _Chip(label: 'Peso', valor: '${medida.peso!.toStringAsFixed(1)} kg'),
            if (medida.cintura != null)
              _Chip(label: 'Abdômen', valor: '${medida.cintura!.toStringAsFixed(1)} cm'),
            if (medida.quadril != null)
              _Chip(label: 'Quadril', valor: '${medida.quadril!.toStringAsFixed(1)} cm'),
            if (medida.braco != null)
              _Chip(label: 'Braço', valor: '${medida.braco!.toStringAsFixed(1)} cm'),
          ]),
        ]),
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
      loading: () => const Center(child: CircularProgressIndicator()),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: EagleTokens.warn,
          child: Icon(Icons.emoji_events, color: Colors.white),
        ),
        title: Text(recorde.exercicioNome,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          recorde.data.length >= 10 ? recorde.data.substring(0, 10) : recorde.data,
          style: const TextStyle(fontSize: 12, color: EagleTokens.inkMute),
        ),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (recorde.cargaKg != null)
            Text('${recorde.cargaKg!.toStringAsFixed(1)} kg',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          if (recorde.repeticoes != null)
            Text('${recorde.repeticoes} reps',
                style: const TextStyle(fontSize: 12, color: EagleTokens.inkMute)),
        ]),
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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: EagleTokens.inkMute)),
        Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
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
        border: const OutlineInputBorder(),
      ),
    );
  }
}
