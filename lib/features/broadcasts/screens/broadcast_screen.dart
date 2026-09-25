import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/broadcast_repository.dart';
import '../utils/broadcast_display.dart';
import 'widgets/broadcast_historico.dart';

final _broadcastRepositoryProvider = Provider<BroadcastRepository>(
  (ref) => BroadcastRepository(ref.read(apiClientProvider)),
);

final _broadcastHistoricoProvider = FutureProvider<List<Broadcast>>((ref) {
  return ref.read(_broadcastRepositoryProvider).listar();
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
        title: 'Descartar rascunho?',
        message: 'O título e a mensagem não serão enviados.',
        confirmLabel: 'Descartar',
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
      title: 'Broadcasts',
      subtitle: 'Avisa a base inteira sem abrir conversa por conversa.',
      tips: const [
        FxHelpTip(
          'Público',
          'Todos, online, presencial ou híbrido — o filtro usa o tipo de consultoria do aluno.',
          icon: 'users',
        ),
        FxHelpTip(
          'Envio',
          'Confirme no sheet. A notificação vai para os apps dos alunos deste público.',
          icon: 'message-circle',
        ),
      ],
    );
  }

  Future<void> _enviar() async {
    if (_enviando) return;
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    final ok = await showFxConfirmSheet(
      context,
      title: broadcastConfirmTitle(_publicoAlvo),
      message: broadcastConfirmMessage(),
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
      _tituloCtrl.clear();
      _mensagemCtrl.clear();
      setState(() => _publicoAlvo = 'TODOS');
      ref.invalidate(_broadcastHistoricoProvider);
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final historicoAsync = ref.watch(_broadcastHistoricoProvider);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Broadcast',
      child: FxFormPopGuard(
        dirty: _isDirty,
        onCancel: _cancel,
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Broadcasts',
            subtitle: freshnessLabel ?? 'Mensagem para a base',
            onBack: () {
              _cancel();
            },
            actions: [
              FxHelpIconButton(
                tooltip: 'Como funciona o broadcast',
                onTap: _showHelp,
              ),
            ],
          ),
          bottomNavigationBar: FxFormStickyBar(
            child: Semantics(
              button: true,
              enabled: !_enviando,
              label: _enviando ? 'Enviando broadcast' : 'Enviar',
              child: FxLiquidPrimaryButton(
                label: 'Enviar',
                loading: _enviando,
                loadingLabel: 'Enviando…',
                onPressed: _enviando ? null : _enviar,
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
                    FxSettingsGroup(
                      header: 'Nova mensagem',
                      caption: 'Título e texto da notificação push.',
                      children: [
                      AlunoInsetFormField(
                        controller: _tituloCtrl,
                        label: 'Título',
                        hint: 'Ex.: Lembrete de treino',
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
                        label: 'Mensagem',
                        hint: 'O que os alunos vão ler no aviso.',
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
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  FxSettingsGroup(
                    header: 'Público',
                    caption: 'Quem recebe, pelo tipo de consultoria.',
                    children: [
                      for (var i = 0; i < broadcastPublicos.length; i++)
                        FxSettingsTile(
                          fxIcon: broadcastPublicoFxIcon(broadcastPublicos[i]),
                          label: broadcastPublicoLabel(broadcastPublicos[i]),
                          value: broadcastChoiceValue(
                            _publicoAlvo == broadcastPublicos[i],
                          ),
                          highlight: _publicoAlvo == broadcastPublicos[i],
                          showDivider: i != broadcastPublicos.length - 1,
                          onTap:
                              () => setState(
                                () => _publicoAlvo = broadcastPublicos[i],
                              ),
                        ),
                    ],
                  ),
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
                    data: (lista) => BroadcastHistorico(itens: lista),
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
