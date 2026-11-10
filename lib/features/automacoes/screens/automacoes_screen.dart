import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../alunos/utils/alunos_home_prefetch.dart';
import '../../auth/providers/auth_provider.dart';
import '../../chat/utils/aluno_picker_list.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../../core/api/pagina.dart';
import '../data/automacao_repository.dart';
import '../utils/automacao_display.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/theme/fx_icons.dart';

part 'automacoes_screen_logs.part.dart';
part 'automacoes_screen_list.part.dart';

final _repo = Provider(
  (ref) => AutomacaoRepository(ref.read(apiClientProvider)),
);

class AutomacoesScreen extends ConsumerStatefulWidget {
  const AutomacoesScreen({super.key});

  @override
  ConsumerState<AutomacoesScreen> createState() => _AutomacoesScreenState();
}

class _AutomacoesScreenState extends ConsumerState<AutomacoesScreen> {
  List<AutomacaoFluxo> _fluxos = const [];
  List<AutomacaoTemplate> _templates = const [];
  PlanoFeatures? _planoFromHome;
  var _loading = true;
  String? _error;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    prefetchAlunosHome(ref);
    _load();
  }

  void _leave() {
    FxKeyboardDismissScope.dismiss();
    safePopOrGo(context, '/perfil/ferramentas');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final home = await ref.read(_repo).getHome();
      if (!mounted) return;
      setState(() {
        _fluxos = home.fluxos;
        _templates = home.templates;
        _planoFromHome = home.planoFeatures;
        _fetchedAt = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  Future<void> _ativar(AutomacaoTemplate t) async {
    final ok = await showFxConfirmSheet(
      context,
      title: automacaoAtivarTitle(
        automacaoNome(templateId: t.id, nomeGravado: t.nome),
      ),
      message: [
        ...automacaoPassosLinhas(t.passos),
        'Começa para cada aluno que entrar na regra: ${automacaoTriggerLabel(t.triggerTipo).toLowerCase()}.',
      ].join('\n'),
      icon: FxIcons.raio,
      confirmLabel: 'Ligar',
    );
    if (!ok || !mounted) return;
    AnalyticsService.instance.track(
      ProductEvents.automacaoTemplateActivated,
      props: {'feature': 'automacoes', 'template_id': t.id},
    );
    try {
      await ref.read(_repo).ativarTemplate(t.id);
      await _load();
      if (!mounted) return;
      FeedbackHelper.showSuccess(
        context,
        '“${automacaoNome(templateId: t.id, nomeGravado: t.nome)}” ligada',
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _openLogs(AutomacaoFluxo fluxo) async {
    try {
      final pagina = await ref.read(_repo).logs(fluxo.id);
      if (!mounted) return;
      await _showAutomacaoLogsSheet(
        context: context,
        fluxo: fluxo,
        initial: pagina,
        onLoadMore: (page) => ref.read(_repo).logs(fluxo.id, page: page),
        onIniciar: () => _iniciarParaAluno(fluxo),
        onToggleAtivo: _toggleFluxoAtivo,
      );
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<AutomacaoFluxo?> _toggleFluxoAtivo(AutomacaoFluxo fluxo) async {
    final pausar = fluxo.ativo;
    final ok = await showFxConfirmSheet(
      context,
      title:
          pausar
              ? automacaoPausarConfirmTitle(fluxo.nome)
              : automacaoRetomarConfirmTitle(fluxo.nome),
      message:
          pausar
              ? automacaoPausarConfirmMessage()
              : automacaoRetomarConfirmMessage(),
      icon: pausar ? FxIcons.pausar : FxIcons.play,
      confirmLabel: pausar ? 'Pausar' : 'Retomar',
    );
    if (!ok || !mounted) return null;
    try {
      final updated =
          pausar
              ? await ref.read(_repo).pausar(fluxo.id)
              : await ref.read(_repo).retomar(fluxo.id);
      if (!mounted) return updated;
      setState(() {
        _fluxos = [
          for (final f in _fluxos)
            if (f.id == updated.id) updated else f,
        ];
      });
      FeedbackHelper.showSuccess(
        context,
        pausar ? automacaoPausarSuccess() : automacaoRetomarSuccess(),
      );
      return updated;
    } catch (e) {
      if (!mounted) return null;
      FeedbackHelper.showError(context, friendlyError(e));
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final linhas = _linhasDeAutomacao(_templates, _fluxos);
    final planoFromHome = _planoFromHome;
    if (planoFromHome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(planoFeaturesProvider.notifier).seedFromHome(planoFromHome);
      });
    }

    return fxScreenA11yScope(
      label: 'Automações',
      child: FeatureGate(
        featureName: 'Automações',
        requiredPlan: SubscriptionPlan.ENTERPRISE,
        capability: 'automacoes',
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _leave();
          },
          child: FxShellScaffold(
            useMesh: true,
            appBar: FxShellAppBar(
              title: 'Automações',
              subtitle: FxHubFreshness.joinCount(
                automacaoLigadasLabel(
                  ligadas: linhas.where((l) => l.ligada).length,
                  total: linhas.length,
                ),
                FxHubFreshness.fromFetchedAt(_fetchedAt),
              ),
              onBack: _leave,
              actions: [
                FxHelpIconButton(
                  tooltip: 'Como usar automações',
                  onTap:
                      () => showFxHelpSheet(
                        context,
                        title: 'Automações',
                        subtitle:
                            'Avisos e mensagens que saem sozinhos quando o aluno entra na regra.',
                        tips: const [
                          FxHelpTip(
                            'Ligar',
                            'A chave mostra antes o que sai, quando e em nome de quem.',
                          ),
                          FxHelpTip(
                            'Andamento',
                            'Toque numa automação ligada para ver quem está nela.',
                          ),
                          FxHelpTip(
                            'Iniciar',
                            'No andamento, escolha um aluno para começar agora.',
                          ),
                        ],
                      ),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child:
                      _loading
                          ? const Padding(
                            padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                            child: SkeletonList(count: 5),
                          )
                          : _error != null
                          ? FxErrorState(
                            chromeOnDark: chrome.isDark,
                            primary: primary,
                            message: _error!,
                            onRetry: _load,
                          )
                          : FxContentWidthLimiter(child: _buildList(linhas)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
