import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_quick_chips.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/broadcast_repository.dart';
import '../utils/broadcast_display.dart';
import 'widgets/broadcast_historico.dart';
import '../../../l10n/pt.dart';

final _broadcastRepositoryProvider = Provider<BroadcastRepository>(
  (ref) => BroadcastRepository(ref.read(apiClientProvider)),
);

final _broadcastHistoricoProvider = FutureProvider<List<Broadcast>>((ref) {
  return ref.read(_broadcastRepositoryProvider).listar();
});

/// Sem alcance a tela segue: só perde a contagem.
final _broadcastAlcanceProvider = FutureProvider.autoDispose<
  Map<String, BroadcastAlcance>
>((ref) async {
  try {
    return await ref.read(_broadcastRepositoryProvider).alcance();
  } catch (_) {
    return const {};
  }
});

class BroadcastScreen extends ConsumerStatefulWidget {
  const BroadcastScreen({super.key});

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _mensagemCtrl = TextEditingController();
  String _publicoAlvo = 'TODOS';
  bool _enviando = false;
  DateTime? _fetchedAt;
  ProviderSubscription<AsyncValue<List<Broadcast>>>? _freshnessSub;

  @override
  void initState() {
    super.initState();
    _tituloCtrl.addListener(_onDraftChanged);
    _mensagemCtrl.addListener(_onDraftChanged);
    _freshnessSub = ref.listenManual(_broadcastHistoricoProvider, (_, next) {
      if (!next.hasValue || next.isLoading || next.hasError) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _fetchedAt = DateTime.now());
      });
    }, fireImmediately: true);
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  bool get _isDirty =>
      _tituloCtrl.text.trim().isNotEmpty ||
      _mensagemCtrl.text.trim().isNotEmpty ||
      _publicoAlvo != 'TODOS';

  Future<void> _cancel() async {
    FxKeyboardDismissScope.dismiss();
    if (_isDirty) {
      final ok = await showFxConfirmSheet(
        context,
        title: ptS.broadcastDescartarRascunho,
        message: ptS.broadcastOTituloEAMensagem,
        confirmLabel: ptS.chatDescartarNaoEnviada,
        discard: true,
      );
      if (!ok || !mounted) return;
    }
    safePopOrGo(context, '/dashboard/personal');
  }

  @override
  void dispose() {
    _freshnessSub?.close();
    _tituloCtrl.removeListener(_onDraftChanged);
    _mensagemCtrl.removeListener(_onDraftChanged);
    _tituloCtrl.dispose();
    _mensagemCtrl.dispose();
    super.dispose();
  }

  void _showHelp() {
    showFxHelpSheet(
      context,
      title: ptS.broadcastAvisos,
      subtitle: ptS.broadcastFalaComTodosOsAlunos,
      tips: [
        FxHelpTip(
          ptS.broadcastPublico,
          ptS.broadcastTodosOnlinePresencialOuHibrido,
          icon: 'users',
        ),
        FxHelpTip(
          ptS.broadcastEnvio,
          ptS.broadcastVoceVeQuantosRecebemAntes,
          icon: 'message-circle',
        ),
      ],
    );
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final alcance = ref.read(_broadcastAlcanceProvider).value?[_publicoAlvo];
    final ok = await showFxConfirmSheet(
      context,
      title: broadcastConfirmTitle(_publicoAlvo, total: alcance?.total),
      message: broadcastConfirmMessage(
        total: alcance?.total,
        comPush: alcance?.comPush,
      ),
      icon: Icons.send_rounded,
      confirmLabel: broadcastConfirmLabel(),
    );
    if (!ok || !mounted) return;
    setState(() => _enviando = true);
    try {
      final resultado = await ref
          .read(_broadcastRepositoryProvider)
          .enviar(
            titulo: _tituloCtrl.text.trim(),
            mensagem: _mensagemCtrl.text.trim(),
            tipoConsultoriaAlvo: broadcastTipoApi(_publicoAlvo),
          );
      if (!mounted) return;
      _tituloCtrl.clear();
      _mensagemCtrl.clear();
      setState(() => _publicoAlvo = 'TODOS');
      ref.invalidate(_broadcastHistoricoProvider);
      ref.invalidate(_broadcastAlcanceProvider);
      FeedbackHelper.showSuccess(
        context,
        broadcastSendSuccess(
          resultado.totalEnviados,
          comPush: resultado.totalComPush,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _preencher(String titulo, String mensagem) {
    HapticFeedback.selectionClick();
    _tituloCtrl.text = titulo;
    _mensagemCtrl.text = mensagem;
  }

  @override
  Widget build(BuildContext context) {
    final alcance = ref.watch(_broadcastAlcanceProvider).value ?? const {};
    final semAlunos = alcance['TODOS']?.total == 0;
    final prontoParaEnviar =
        _tituloCtrl.text.trim().isNotEmpty &&
        _mensagemCtrl.text.trim().isNotEmpty;
    final historicoAsync = ref.watch(_broadcastHistoricoProvider);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: ptS.broadcastAvisos,
      child: FxFormPopGuard(
        dirty: _isDirty,
        onCancel: _cancel,
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: ptS.broadcastAvisos,
            subtitle: freshnessLabel ?? ptS.broadcastParaTodosOsAlunos,
            onBack: () {
              _cancel();
            },
            actions: [
              FxHelpIconButton(
                tooltip: ptS.broadcastComoFuncionamOsAvisos,
                onTap: _showHelp,
              ),
            ],
          ),
          bottomNavigationBar: semAlunos
              ? null
              : FxFormStickyBar(
            child: Semantics(
              button: true,
              enabled: !_enviando,
              label: _enviando ? ptS.broadcastEnviandoAviso : ptS.npsPromptEnviar,
              child: FxLiquidPrimaryButton(
                label: ptS.npsPromptEnviar,
                loading: _enviando,
                loadingLabel: ptS.anamneseAlunoEnviando,
                onPressed: _enviando || !prontoParaEnviar ? null : _enviar,
              ),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(_broadcastHistoricoProvider);
                await ref.read(_broadcastHistoricoProvider.future);
              },
              child: FxContentWidthLimiter(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s3,
                      FxSettingsLayout.pageInset,
                      24,
                    ),
                    children: [
                    if (semAlunos)
                      FxEmptyState(
                        icon: 'users',
                        title: ptS.broadcastSemAlunosParaAvisar,
                        subtitle: ptS.broadcastCadastreUmAlunoParaEnviar,
                        action: FxEmptyAction(
                          label: ptS.broadcastVerAlunos,
                          onTap: () => goPersonalShellTab(context, '/alunos'),
                        ),
                      )
                    else ...[
                    FxQuickChips<({String nome, String titulo, String mensagem})>(
                      itens: broadcastAtalhos,
                      selecionado: null,
                      rotuloDe: (atalho) => atalho.nome,
                      onSelecionar:
                          (atalho) =>
                              _preencher(atalho.titulo, atalho.mensagem),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    FxSettingsGroup(
                      header: ptS.broadcastNovoAviso,
                      caption: ptS.broadcastChegaComoNotificacaoNoCelular,
                      children: [
                      AlunoInsetFormField(
                        controller: _tituloCtrl,
                        label: ptS.agendaTituloGrupo,
                        hint: ptS.broadcastExLembreteDeTreino,
                        icon: Icons.title_outlined,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(100),
                        ],
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? broadcastRequiredTitulo()
                                    : null,
                      ),
                      AlunoInsetFormField(
                        controller: _mensagemCtrl,
                        label: ptS.copilotoMensagemCampo,
                        hint: ptS.broadcastOQueOsAlunosVao,
                        icon: Icons.notes_outlined,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(2000),
                        ],
                        showDivider: false,
                        validator:
                            (v) =>
                                v == null || v.trim().isEmpty
                                    ? broadcastRequiredMensagem()
                                    : null,
                      ),
                    ],
                  ),
                  if (prontoParaEnviar) ...[
                    const SizedBox(height: TokensStrip.s3),
                    _PreviaNotificacao(
                      titulo: _tituloCtrl.text.trim(),
                      mensagem: _mensagemCtrl.text.trim(),
                    ),
                  ],
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  Text(
                    ptS.broadcastQuemRecebe,
                    style: FocuxHubTypography.sectionTitle(
                      context,
                      color: chrome.ink,
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  FxChoiceStrip<String>(
                    itens: [
                      for (final publico in broadcastPublicos)
                        FxChoiceItem(
                          value: publico,
                          label: broadcastPublicoChip(
                            publico,
                            alcance[publico]?.total,
                          ),
                        ),
                    ],
                    selecionado: _publicoAlvo,
                    onSelecionar:
                        (publico) => setState(() => _publicoAlvo = publico),
                  ),
                  if (broadcastSemTipoAviso({
                    for (final e in alcance.entries) e.key: e.value.total,
                  }) case final aviso?) ...[
                    const SizedBox(height: TokensStrip.s2),
                    Text(
                      aviso,
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                  ],
                  ],
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  historicoAsync.when(
                    loading: () => const SkeletonList(count: 4),
                    error:
                        (e, _) => FxErrorState(
                          chromeOnDark: chrome.isDark,
                          primary: primary,
                          message: friendlyError(e),
                          onRetry:
                              () =>
                                  ref.invalidate(_broadcastHistoricoProvider),
                        ),
                    data:
                        (lista) => BroadcastHistorico(
                          itens: lista,
                          onUsarDeNovo:
                              (item) => _preencher(item.titulo, item.mensagem),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
        ),
      ),
    );
  }
}

/// Como o aviso aparece no celular do aluno.
class _PreviaNotificacao extends StatelessWidget {
  const _PreviaNotificacao({required this.titulo, required this.mensagem});

  final String titulo;
  final String mensagem;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: fxListCardDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_none_rounded, size: 20, color: chrome.brand),
          const SizedBox(width: TokensStrip.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.cardTitle(color: chrome.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  mensagem,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
