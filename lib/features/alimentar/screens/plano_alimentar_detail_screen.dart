import 'package:flutter/material.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../ia/data/ia_repository.dart';
import '../../ia/widgets/ia_quota_upgrade.dart';
import '../data/alimentar_repository.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

class PlanoAlimentarDetailScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final PlanoAlimentar plano;

  const PlanoAlimentarDetailScreen({
    super.key,
    required this.alunoId,
    required this.plano,
  });

  @override
  ConsumerState<PlanoAlimentarDetailScreen> createState() =>
      _PlanoAlimentarDetailScreenState();
}

class _PlanoAlimentarDetailScreenState
    extends ConsumerState<PlanoAlimentarDetailScreen> {
  List<Refeicao> _refeicoes = [];
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
      final repo = AlimentarRepository(ref.read(apiClientProvider));
      final lista = await repo.listarRefeicoes(widget.alunoId, widget.plano.id);
      if (!mounted) return;
      setState(() {
        _refeicoes = lista;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _excluir(Refeicao r) async {
    try {
      final repo = AlimentarRepository(ref.read(apiClientProvider));
      await repo.excluirRefeicao(widget.alunoId, widget.plano.id, r.id);
      if (mounted) {
        setState(() => _refeicoes.removeWhere((x) => x.id == r.id));
        FeedbackHelper.showSuccess(context, 'Refeição removida.');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  void _abrirNovaRefeicao() {
    showFxHomeSheet(
      context,
      builder:
          (_) => _NovaRefeicaoSheet(
            alunoId: widget.alunoId,
            planoId: widget.plano.id,
            onSalvo: _load,
          ),
    );
  }

  Future<void> _abrirGerarIa() async {
    final objetivoCtrl = TextEditingController(text: 'Hipertrofia');
    final calCtrl = TextEditingController(text: '2500');
    final refCtrl = TextEditingController(text: '4');

    final confirm = await showFxFormSheet(
      context,
      title: 'Gerar Dieta com IA',
      subtitle:
          'A IA vai criar refeições estruturadas e adicionar diretamente neste plano.',
      icon: Icons.auto_awesome,
      confirmLabel: 'Gerar',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: objetivoCtrl,
            decoration: const InputDecoration(
              labelText: 'Objetivo (ex: Hipertrofia)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: calCtrl,
            decoration: const InputDecoration(labelText: 'Calorias Alvo'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: refCtrl,
            decoration: const InputDecoration(labelText: 'Nº de Refeições'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;
    if (!await IaQuotaUpgrade.guardBeforeRequest(context, ref)) return;

    setState(() => _loading = true);
    try {
      await AlimentarRepository(ref.read(apiClientProvider)).gerarDietaIa(
        widget.alunoId,
        widget.plano.id,
        objetivo: objetivoCtrl.text,
        caloriasAlvo: int.tryParse(calCtrl.text),
        numeroRefeicoes: int.tryParse(refCtrl.text),
      );
      if (!mounted) return;
      await _load();
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Dieta gerada com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        FeedbackHelper.showError(context, friendlyError(e));
        final mapped =
            e is DioException ? IaOperationalException.fromDio(e) : e;
        await IaQuotaUpgrade.handleError(context, ref, mapped);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plano;
    return fxScreenA11yScope(
      label: 'Plano Alimentar Detail',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: p.nome,
          subtitle: 'Plano alimentar do aluno',
          onBack:
              () => safePopOrGo(context, '/alunos/${widget.alunoId}/alimentar'),
          actions: [
            IconButton(
              icon: Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Gerar Dieta IA',
              onPressed: _abrirGerarIa,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _abrirNovaRefeicao,
          icon: const Icon(Icons.add),
          label: const Text('Refeição'),
        ),
        body: Column(
          children: [
            // Resumo de macros do plano
            if (p.caloriasDia != null ||
                p.proteinaG != null ||
                p.carboidratoG != null ||
                p.gorduraG != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (p.caloriasDia != null)
                          _MacroChip('${p.caloriasDia} kcal', EagleTokens.warn),
                        if (p.proteinaG != null)
                          _MacroChip('${p.proteinaG}g prot', EagleTokens.bad),
                        if (p.carboidratoG != null)
                          _MacroChip(
                            '${p.carboidratoG}g carbo',
                            EagleTokens.warn,
                          ),
                        if (p.gorduraG != null)
                          _MacroChip(
                            '${p.gorduraG}g gord',
                            EagleTokens.macroFat,
                          ),
                      ],
                    ),
                    _MacroBar(
                      proteinaG: p.proteinaG,
                      carboidratoG: p.carboidratoG,
                      gorduraG: p.gorduraG,
                    ),
                  ],
                ),
              ),
            Expanded(
              child:
                  _loading
                      ? const SkeletonList(count: 4)
                      : _erro != null
                      ? FxErrorState(
                        chromeOnDark:
                            Theme.of(context).brightness == Brightness.dark,
                        primary: Theme.of(context).colorScheme.primary,
                        message: _erro!,
                        onRetry: _load,
                        title: 'Não conseguimos carregar as refeições',
                      )
                      : _refeicoes.isEmpty
                      ? const FxEmptyState(
                        icon: 'article',
                        title: 'Nenhuma refeição cadastrada',
                        subtitle:
                            'Toque em + para adicionar a primeira refeição do plano.',
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                        itemCount: _refeicoes.length,
                        itemBuilder:
                            (_, i) => _RefeicaoCard(
                              refeicao: _refeicoes[i],
                              onDelete: () => _excluir(_refeicoes[i]),
                            ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MacroChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Chip(
    label: Text(
      label,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
    ),
    backgroundColor: color.withValues(alpha: 0.12),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

    return SizedBox(
      width: double.infinity,
      child: Container(
        height: 8,
        margin: const EdgeInsets.only(top: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            if (proteinKcal > 0)
              Flexible(
                flex: proteinKcal,
                child: Container(color: EagleTokens.macroProtein),
              ),
            if (carbKcal > 0)
              Flexible(
                flex: carbKcal,
                child: Container(color: EagleTokens.warn),
              ),
            if (fatKcal > 0)
              Flexible(
                flex: fatKcal,
                child: Container(color: EagleTokens.macroCarb),
              ),
          ],
        ),
      ),
    );
  }
}

class _RefeicaoCard extends StatelessWidget {
  final Refeicao refeicao;
  final VoidCallback onDelete;
  const _RefeicaoCard({required this.refeicao, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final r = refeicao;
    return Dismissible(
      key: ValueKey(r.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: EagleTokens.macroProteinLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: fxListCardDecoration(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.nomeRefeicao,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (r.horario != null)
                    SizedBox(
                      width: 52,
                      child: Text(
                        r.horario!,
                        textAlign: TextAlign.right,
                        style: AppTypography.mono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              if (r.calorias != null) ...[
                const SizedBox(height: 6),
                Text(
                  '${r.calorias} kcal',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (r.proteinaG != null ||
                  r.carboG != null ||
                  r.gorduraG != null) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    if (r.proteinaG != null)
                      _MacroChip('${r.proteinaG}g prot', EagleTokens.bad),
                    if (r.carboG != null)
                      _MacroChip('${r.carboG}g carbo', EagleTokens.warn),
                    if (r.gorduraG != null)
                      _MacroChip('${r.gorduraG}g gord', EagleTokens.macroFat),
                  ],
                ),
              ],
              if (r.alimentos != null && r.alimentos!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Text(
                  r.alimentos!,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Bottom Sheet ----

class _NovaRefeicaoSheet extends ConsumerStatefulWidget {
  final int alunoId;
  final int planoId;
  final VoidCallback onSalvo;

  const _NovaRefeicaoSheet({
    required this.alunoId,
    required this.planoId,
    required this.onSalvo,
  });

  @override
  ConsumerState<_NovaRefeicaoSheet> createState() => _NovaRefeicaoSheetState();
}

class _NovaRefeicaoSheetState extends ConsumerState<_NovaRefeicaoSheet> {
  final _nome = TextEditingController();
  final _horario = TextEditingController();
  final _cal = TextEditingController();
  final _prot = TextEditingController();
  final _carbo = TextEditingController();
  final _gord = TextEditingController();
  final _alimentos = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nome.dispose();
    _horario.dispose();
    _cal.dispose();
    _prot.dispose();
    _carbo.dispose();
    _gord.dispose();
    _alimentos.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nome.text.trim().isEmpty) {
      FeedbackHelper.showError(context, 'Nome da refeição é obrigatório.');
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = AlimentarRepository(ref.read(apiClientProvider));
      await repo.criarRefeicao(widget.alunoId, widget.planoId, {
        'nomeRefeicao': _nome.text.trim(),
        if (_horario.text.isNotEmpty) 'horario': _horario.text.trim(),
        if (_cal.text.isNotEmpty) 'calorias': int.tryParse(_cal.text),
        if (_prot.text.isNotEmpty) 'proteinaG': int.tryParse(_prot.text),
        if (_carbo.text.isNotEmpty) 'carboG': int.tryParse(_carbo.text),
        if (_gord.text.isNotEmpty) 'gorduraG': int.tryParse(_gord.text),
        if (_alimentos.text.isNotEmpty) 'alimentos': _alimentos.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSalvo();
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FxHomeSheetHandle(isDark: isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: isDark,
              title: 'Nova Refeição',
              subtitle: 'Adicione horário, macros e alimentos.',
              leading: Icon(
                Icons.restaurant_outlined,
                color: primary,
                size: 18,
              ),
            ),
            SizedBox(height: TokensStrip.s3),
            _field(_nome, 'Nome da refeição *'),
            _field(_horario, 'Horário (ex: 07:30)'),
            _num(_cal, 'Calorias (kcal)'),
            _num(_prot, 'Proteína (g)'),
            _num(_carbo, 'Carboidrato (g)'),
            _num(_gord, 'Gordura (g)'),
            _field(_alimentos, 'Alimentos', maxLines: 4),
            const SizedBox(height: TokensStrip.s4),
            FxLiquidPrimaryButton(
              label: 'Adicionar Refeição',
              loading: _saving,
              onPressed: _saving ? null : _salvar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          decoration: InputDecoration(labelText: label),
          maxLines: maxLines,
        ),
      );

  Widget _num(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
    ),
  );
}
