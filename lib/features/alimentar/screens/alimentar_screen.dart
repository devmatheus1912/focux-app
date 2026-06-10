import 'package:flutter/material.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/alimentar_repository.dart';
import 'plano_alimentar_detail_screen.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../alunos/widgets/aluno360_action_empty_panel.dart';

class AlimentarScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String? alunoNome;
  const AlimentarScreen({
    super.key,
    required this.alunoId,
    this.alunoNome,
  });
  @override
  ConsumerState<AlimentarScreen> createState() => _AlimentarScreenState();
}

class _AlimentarScreenState extends ConsumerState<AlimentarScreen> {
  List<PlanoAlimentar> _planos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await AlimentarRepository(
        ref.read(apiClientProvider),
      ).listar(widget.alunoId);
      if (!mounted) return;
      setState(() {
        _planos = r;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Planos Alimentares',
        subtitle: 'Nutrição prescrita para o aluno',
        onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _NovoPlanoScreen(alunoId: widget.alunoId),
            ),
          );
          if (!context.mounted) return;
          _load();
        },
        child: const Icon(Icons.add),
      ),
      body:
          _loading
              ? const FxLoading()
              : _planos.isEmpty
              ? satelliteEmptyBody(
                child: Aluno360ActionEmptyPanel(
                  key: const ValueKey('alimentar_empty'),
                  icon: Icons.restaurant_menu_rounded,
                  title: 'Nenhum plano alimentar',
                  subtitle:
                      widget.alunoNome != null
                          ? 'Monte o primeiro plano de ${satelliteFirstName(widget.alunoNome)} com metas de calorias e macros.'
                          : 'Crie o primeiro plano com metas de calorias e macros.',
                  primaryLabel: 'Criar plano',
                  primaryIcon: Icons.add_rounded,
                  onPrimary: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => _NovoPlanoScreen(alunoId: widget.alunoId),
                      ),
                    );
                    if (!context.mounted) return;
                    _load();
                  },
                  secondaryActions: [
                    Aluno360SecondaryAction(
                      label: 'Voltar ao Aluno 360',
                      icon: Icons.arrow_back_rounded,
                      onTap:
                          () => safePopOrGo(
                            context,
                            '/alunos/${widget.alunoId}',
                          ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(TokensStrip.s4),
                itemCount: _planos.length,
                itemBuilder: (_, i) {
                  final p = _planos[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DecoratedBox(
                      decoration: fxListCardDecoration(context),
                      child: InkWell(
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => PlanoAlimentarDetailScreen(
                                      alunoId: widget.alunoId,
                                      plano: p,
                                    ),
                              ),
                            ),
                        child: Padding(
                          padding: const EdgeInsets.all(TokensStrip.s4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.nome,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: TokensStrip.textSecondary,
                                  ),
                                ],
                              ),
                              if (p.caloriasDia != null)
                                Text(
                                  '${p.caloriasDia} kcal/dia',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              if (p.proteinaG != null ||
                                  p.carboidratoG != null ||
                                  p.gorduraG != null) ...[
                                const SizedBox(height: 10),
                                _MacroBar(
                                  proteinaG: p.proteinaG,
                                  carboidratoG: p.carboidratoG,
                                  gorduraG: p.gorduraG,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                children: [
                                  if (p.proteinaG != null)
                                    _macro(
                                      'Proteína',
                                      '${p.proteinaG}g',
                                      EagleTokens.bad,
                                    ),
                                  if (p.carboidratoG != null)
                                    _macro(
                                      'Carbo',
                                      '${p.carboidratoG}g',
                                      EagleTokens.warn,
                                    ),
                                  if (p.gorduraG != null)
                                    _macro(
                                      'Gordura',
                                      '${p.gorduraG}g',
                                      Colors.yellow.shade700,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _macro(String label, String value, Color color) => Chip(
    label: Text('$label: $value'),
    backgroundColor: color.withValues(alpha: 0.15),
  );
}

class _MacroBar extends StatelessWidget {
  final int? proteinaG;
  final int? carboidratoG;
  final int? gorduraG;

  const _MacroBar({
    required this.proteinaG,
    required this.carboidratoG,
    required this.gorduraG,
  });

  @override
  Widget build(BuildContext context) {
    final proteinKcal = (proteinaG ?? 0) * 4;
    final carbKcal = (carboidratoG ?? 0) * 4;
    final fatKcal = (gorduraG ?? 0) * 9;
    final totalKcal = proteinKcal + carbKcal + fatKcal;

    if (totalKcal <= 0) return const SizedBox.shrink();

    return Container(
      height: 8,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          if (proteinKcal > 0)
            Flexible(
              flex: proteinKcal,
              child: Container(color: const Color(0xFFEF4444)),
            ),
          if (carbKcal > 0)
            Flexible(flex: carbKcal, child: Container(color: EagleTokens.warn)),
          if (fatKcal > 0)
            Flexible(
              flex: fatKcal,
              child: Container(color: const Color(0xFFEAB308)),
            ),
        ],
      ),
    );
  }
}

class _NovoPlanoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  const _NovoPlanoScreen({required this.alunoId});
  @override
  ConsumerState<_NovoPlanoScreen> createState() => _NovoPlanoScreenState();
}

class _NovoPlanoScreenState extends ConsumerState<_NovoPlanoScreen> {
  final _nome = TextEditingController(),
      _cal = TextEditingController(),
      _prot = TextEditingController(),
      _carb = TextEditingController(),
      _gord = TextEditingController(),
      _obs = TextEditingController();
  bool _saving = false;

  Future<void> _salvar() async {
    if (_nome.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await AlimentarRepository(
        ref.read(apiClientProvider),
      ).criar(widget.alunoId, {
        'nome': _nome.text,
        if (_cal.text.isNotEmpty) 'caloriasDia': int.tryParse(_cal.text),
        if (_prot.text.isNotEmpty) 'proteinaG': int.tryParse(_prot.text),
        if (_carb.text.isNotEmpty) 'carboidratoG': int.tryParse(_carb.text),
        if (_gord.text.isNotEmpty) 'gorduraG': int.tryParse(_gord.text),
        if (_obs.text.isNotEmpty) 'observacoes': _obs.text,
      });
      if (mounted) {
        safePopOrGo(context, '/alunos/${widget.alunoId}/alimentar');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
    if (mounted) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Novo Plano Alimentar',
        subtitle: 'Defina metas e refeições do plano',
        onBack:
            () => safePopOrGo(context, '/alunos/${widget.alunoId}/alimentar'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(TokensStrip.s4),
        child: Column(
          children: [
            _field(_nome, 'Nome do plano *'),
            _num(_cal, 'Calorias/dia (kcal)'),
            _num(_prot, 'Proteína (g)'),
            _num(_carb, 'Carboidrato (g)'),
            _num(_gord, 'Gordura (g)'),
            _field(_obs, 'Observações', maxLines: 3),
            const SizedBox(height: TokensStrip.s4),
            FxLiquidPrimaryButton(
              label: 'Criar Plano',
              loading: _saving,
              onPressed: _saving ? null : _salvar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _num(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
    ),
  );

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          decoration: InputDecoration(labelText: label),
          maxLines: maxLines,
        ),
      );
}
