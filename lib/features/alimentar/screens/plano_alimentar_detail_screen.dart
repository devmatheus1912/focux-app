import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/alunos/widgets/aluno_inset_form_field.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../ia/data/ia_repository.dart';
import '../../ia/widgets/ia_quota_upgrade.dart';
import '../data/alimentar_repository.dart';
import '../utils/alimentar_display.dart';

part 'plano_alimentar_detail_widgets.part.dart';

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
  DateTime? _fetchedAt;

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
        _fetchedAt = DateTime.now();
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
    final ok = await showFxConfirmSheet(
      context,
      title: 'Remover refeição?',
      subtitle: r.nomeRefeicao,
      message: 'Ela some do plano. Dá para cadastrar de novo depois.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok || !mounted) return;
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

  Future<void> _abrirNovaRefeicao() async {
    HapticFeedback.selectionClick();
    final nome = TextEditingController();
    final horario = TextEditingController();
    final cal = TextEditingController();
    final prot = TextEditingController();
    final carbo = TextEditingController();
    final gord = TextEditingController();
    final alimentos = TextEditingController();
    var created = false;

    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Nova refeição',
        subtitle: 'Adicione horário, macros e alimentos.',
        icon: Icons.restaurant_outlined,
        confirmLabel: 'Adicionar refeição',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlunoInsetFormField(
              controller: nome,
              label: 'Nome da refeição',
              icon: Icons.title_outlined,
            ),
            AlunoInsetFormField(
              controller: horario,
              label: 'Horário (ex: 07:30)',
              icon: Icons.schedule_outlined,
            ),
            AlunoInsetFormField(
              controller: cal,
              label: 'Calorias (kcal)',
              icon: Icons.local_fire_department_outlined,
              keyboardType: TextInputType.number,
            ),
            AlunoInsetFormField(
              controller: prot,
              label: 'Proteína (g)',
              icon: Icons.egg_outlined,
              keyboardType: TextInputType.number,
            ),
            AlunoInsetFormField(
              controller: carbo,
              label: 'Carboidrato (g)',
              icon: Icons.breakfast_dining_outlined,
              keyboardType: TextInputType.number,
            ),
            AlunoInsetFormField(
              controller: gord,
              label: 'Gordura (g)',
              icon: Icons.water_drop_outlined,
              keyboardType: TextInputType.number,
            ),
            AlunoInsetFormField(
              controller: alimentos,
              label: 'Alimentos',
              icon: Icons.notes_outlined,
              maxLines: 4,
              showDivider: false,
            ),
          ],
        ),
      );
      if (ok != true) return;
      if (nome.text.trim().isEmpty) {
        if (mounted) {
          FeedbackHelper.showWarn(context, 'Nome da refeição é obrigatório.');
        }
        return;
      }
      await AlimentarRepository(ref.read(apiClientProvider)).criarRefeicao(
        widget.alunoId,
        widget.plano.id,
        {
          'nomeRefeicao': nome.text.trim(),
          if (horario.text.isNotEmpty) 'horario': horario.text.trim(),
          if (cal.text.isNotEmpty) 'calorias': int.tryParse(cal.text),
          if (prot.text.isNotEmpty) 'proteinaG': int.tryParse(prot.text),
          if (carbo.text.isNotEmpty) 'carboG': int.tryParse(carbo.text),
          if (gord.text.isNotEmpty) 'gorduraG': int.tryParse(gord.text),
          if (alimentos.text.isNotEmpty) 'alimentos': alimentos.text.trim(),
        },
      );
      created = true;
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      nome.dispose();
      horario.dispose();
      cal.dispose();
      prot.dispose();
      carbo.dispose();
      gord.dispose();
      alimentos.dispose();
    }
    if (created) await _load();
  }

  Future<void> _abrirGerarIa() async {
    final objetivoCtrl = TextEditingController(text: 'Hipertrofia');
    final calCtrl = TextEditingController(text: '2500');
    final refCtrl = TextEditingController(text: '4');

    try {
      final confirm = await showFxFormSheet(
        context,
        title: 'Gerar dieta com IA',
        subtitle:
            'A IA cria refeições estruturadas e adiciona neste plano. Você confirma antes.',
        icon: Icons.auto_awesome,
        confirmLabel: 'Gerar',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlunoInsetFormField(
              controller: objetivoCtrl,
              label: 'Objetivo',
              icon: Icons.flag_outlined,
              hint: 'Ex: Hipertrofia',
            ),
            AlunoInsetFormField(
              controller: calCtrl,
              label: 'Calorias alvo',
              icon: Icons.local_fire_department_outlined,
              keyboardType: TextInputType.number,
            ),
            AlunoInsetFormField(
              controller: refCtrl,
              label: 'Nº de refeições',
              icon: Icons.restaurant_outlined,
              keyboardType: TextInputType.number,
              showDivider: false,
            ),
          ],
        ),
      );

      if (confirm != true) return;
      if (!mounted) return;
      if (!await IaQuotaUpgrade.guardBeforeRequest(context, ref)) return;

      setState(() => _loading = true);
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
    } finally {
      objetivoCtrl.dispose();
      calCtrl.dispose();
      refCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plano;
    final chrome = ShellChrome.of(context);
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    return fxScreenA11yScope(
      label: 'Plano alimentar',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: p.nome,
          subtitle: alimentarDetailSubtitle(freshnessLabel),
          onBack:
              () => safePopOrGo(context, '/alunos/${widget.alunoId}/alimentar'),
          actions: [
            ShellHeaderIconButton(
              icon: 'spark',
              tooltip: 'Gerar dieta IA',
              onTap: _abrirGerarIa,
            ),
            ShellHeaderIconButton(
              icon: 'plus',
              tooltip: 'Nova refeição',
              onTap: _abrirNovaRefeicao,
            ),
          ],
        ),
        body: FxContentWidthLimiter(child: _buildBody(chrome)),
      ),
    );
  }

  Widget _buildBody(ShellPalette chrome) {
    final p = widget.plano;
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        if (p.caloriasDia != null ||
            p.proteinaG != null ||
            p.carboidratoG != null ||
            p.gorduraG != null)
          PlanoAlimentarMacroHeader(plano: p),
        Expanded(
          child:
              _loading
                  ? const Padding(
                    padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                    child: SkeletonList(count: 4),
                  )
                  : _erro != null
                  ? FxErrorState(
                    chromeOnDark: chrome.isDark,
                    primary: primary,
                    message: _erro!,
                    onRetry: _load,
                    title: 'Não conseguimos carregar as refeições',
                  )
                  : RefreshIndicator(
                    onRefresh: _load,
                    child:
                        _refeicoes.isEmpty
                            ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                FxEmptyState(
                                  icon: 'article',
                                  title: 'Nenhuma refeição cadastrada',
                                  subtitle:
                                      'Toque em + para adicionar a primeira refeição do plano.',
                                  action: FxEmptyAction(
                                    label: 'Nova refeição',
                                    onTap: _abrirNovaRefeicao,
                                  ),
                                ),
                              ],
                            )
                            : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                FxSettingsLayout.pageInset,
                                12,
                                FxSettingsLayout.pageInset,
                                32,
                              ),
                              itemCount: _refeicoes.length,
                              itemBuilder:
                                  (_, i) => PlanoAlimentarRefeicaoCard(
                                    refeicao: _refeicoes[i],
                                    onDelete: () => _excluir(_refeicoes[i]),
                                  ),
                            ),
                  ),
        ),
      ],
    );
  }
}
