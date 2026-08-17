import 'package:flutter/material.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

part 'evolucao_screen_widgets.part.dart';

// ─── Providers ───────────────────────────────────────────────────────────────
final evolucaoHomeProvider = FutureProvider.family<EvolucaoHomeBundle, int>((
  ref,
  alunoId,
) async {
  final repo = EvolucaoRepository(ref.read(apiClientProvider));
  return repo.getHome(alunoId);
});

final medidasProvider = FutureProvider.family<List<MedidaCorporal>, int>((
  ref,
  alunoId,
) async {
  return (await ref.watch(evolucaoHomeProvider(alunoId).future)).medidas;
});

final recordesProvider = FutureProvider.family<List<RecordePessoal>, int>((
  ref,
  alunoId,
) async {
  return (await ref.watch(evolucaoHomeProvider(alunoId).future)).recordes;
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
    final chrome = ShellChrome.forDark(isDark);
    final homeAsync = ref.watch(evolucaoHomeProvider(widget.alunoId));
    final medidasAsync = homeAsync.whenData((h) => h.medidas);
    final recordesAsync = homeAsync.whenData((h) => h.recordes);

    final variacaoText = medidasAsync.whenOrNull(
      data: (lista) => _variacaoPeso(lista),
    );

    return fxScreenA11yScope(
      label: 'Evolução — ${widget.alunoNome}',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Evolução — ${widget.alunoNome}',
          onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              controller: _tabController,
              indicatorColor: primary,
              labelColor: primary,
              unselectedLabelColor: chrome.mute,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: 'Medidas Corporais'),
                Tab(text: 'Recordes Pessoais'),
              ],
            ),
            if (variacaoText != null && variacaoText.isNotEmpty)
              _BannerVariacao(texto: variacaoText),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TabMedidas(
                    alunoId: widget.alunoId,
                    alunoNome: widget.alunoNome,
                    medidasAsync: medidasAsync,
                    onRegister: () => _mostrarDialogMedida(context),
                    onRetry:
                        () =>
                            ref.invalidate(
                              evolucaoHomeProvider(widget.alunoId),
                            ),
                  ),
                  _TabRecordes(
                    alunoId: widget.alunoId,
                    alunoNome: widget.alunoNome,
                    recordesAsync: recordesAsync,
                    onRegister: () => _mostrarDialogRecorde(context),
                    onRetry:
                        () =>
                            ref.invalidate(
                              evolucaoHomeProvider(widget.alunoId),
                            ),
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
                      border: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
              FxLiquidPrimaryButton(
                label: 'Salvar',
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
                    ref.invalidate(evolucaoHomeProvider(widget.alunoId));
                    if (context.mounted) {
                      FeedbackHelper.showSuccess(context, 'Medida adicionada!');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      FeedbackHelper.showError(context, friendlyError(e));
                    }
                  }
                },
                expand: false,
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
                      border: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _CampoNumerico(controller: cargaCtrl, label: 'Carga'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: unidadeCtrl,
                    decoration: InputDecoration(
                      labelText: 'Unidade (kg, reps...)',
                      border: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: obsCtrl,
                    decoration: InputDecoration(
                      labelText: 'Observação',
                      border: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
              FxLiquidPrimaryButton(
                label: 'Salvar',
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
                    ref.invalidate(evolucaoHomeProvider(widget.alunoId));
                    if (context.mounted) {
                      FeedbackHelper.showSuccess(
                        context,
                        'Recorde adicionado!',
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      FeedbackHelper.showError(context, friendlyError(e));
                    }
                  }
                },
                expand: false,
              ),
            ],
          ),
    );
  }
}
