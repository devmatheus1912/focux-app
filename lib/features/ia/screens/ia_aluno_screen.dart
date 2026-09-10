import 'package:flutter/material.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/ia_safety_disclaimer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/alunos/providers/alunos_provider.dart';
import '../../../features/chat/data/chat_repository.dart';
import '../data/ia_repository.dart';
import '../models/ia_progressao_carga_result.dart';
import '../widgets/ia_progressao_loading_skeleton.dart';
import '../widgets/ia_progressao_result_view.dart';
import '../widgets/ia_chat_composer.dart';
import '../widgets/ia_quota_upgrade.dart';
import '../../../core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../utils/ia_aluno_display.dart';

class IaAlunoScreen extends ConsumerStatefulWidget {
  const IaAlunoScreen({super.key});

  @override
  ConsumerState<IaAlunoScreen> createState() => _IaAlunoScreenState();
}

class _IaAlunoScreenState extends ConsumerState<IaAlunoScreen> {
  IaAlunoHubView _view = IaAlunoHubView.chat;
  int? _alunoId;
  bool _resolving = true;
  Object? _resolveError;
  DateTime? _fetchedAt;
  final _generateTick = ValueNotifier<int>(0);
  final _focusChatTick = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _resolverAlunoId();
  }

  @override
  void dispose() {
    _generateTick.dispose();
    _focusChatTick.dispose();
    super.dispose();
  }

  Future<void> _abrirVista() async {
    final picked = await showFxInsetPickerSheet<IaAlunoHubView>(
      context,
      title: 'Ver',
      selected: _view,
      items: [
        for (final v in IaAlunoHubView.values)
          FxInsetPickerSheetItem(value: v, label: iaAlunoHubViewLabel(v)),
      ],
    );
    if (!mounted || picked == null || picked == _view) return;
    setState(() => _view = picked);
  }

  Future<void> _resolverAlunoId() async {
    setState(() {
      _resolving = true;
      _resolveError = null;
    });
    try {
      final aluno = await ref.read(alunoMeProvider.future);
      if (mounted) {
        setState(() {
          _alunoId = aluno.id;
          _resolving = false;
          _fetchedAt = DateTime.now();
        });
      }
      return;
    } catch (_) {}

    try {
      // Fallback: qualquer mensagem serve para descobrir o próprio id, então
      // pede uma só em vez do histórico inteiro.
      final page = await ChatRepository(
        ref.read(apiClientProvider),
      ).historicoAlunoPage(limit: 1);
      final id = page.items.isNotEmpty ? page.items.first.alunoId : null;
      if (!mounted) return;
      if (id != null) {
        setState(() {
          _alunoId = id;
          _resolving = false;
          _fetchedAt = DateTime.now();
        });
      } else {
        setState(() {
          _resolving = false;
          _resolveError =
              'Não foi possível identificar seu perfil de aluno.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resolving = false;
          _resolveError = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final subtitle = iaAlunoHubSubtitle(_view);
    Future<void> voltar() async {
      FxKeyboardDismissScope.dismiss();
      safePopOrGo(context, '/dashboard/aluno');
    }

    return fxScreenA11yScope(
      label: 'Assistente IA',
      child: FxFormPopGuard(
        dirty: false,
        onCancel: voltar,
        child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Assistente IA',
          subtitle: freshness == null ? subtitle : '$subtitle · $freshness',
          onBack: voltar,
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar o assistente',
              onTap: () => showFxHelpSheet(
                context,
                title: 'Assistente IA',
                subtitle: 'Pergunte. Nada entra no aluno sem você.',
                tips: const [
                  FxHelpTip('Como calculamos', iaAlunoComoCalculamos),
                  FxHelpTip(
                    'Visão',
                    'Chat responde perguntas. Progressão só gera se você pedir.',
                  ),
                ],
              ),
            ),
            ShellHeaderIconButton(
              icon: 'spark',
              tooltip: 'Trocar visão',
              onTap: _abrirVista,
            ),
          ],
        ),
        body:
            _resolving
                ? const SkeletonList(count: 5)
                : _resolveError != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: friendlyError(
                    _resolveError!,
                    fallback:
                        'Não foi possível identificar seu perfil de aluno.',
                  ),
                  onRetry: _resolverAlunoId,
                )
                : FxContentWidthLimiter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          TokensStrip.s4,
                          TokensStrip.s4,
                          TokensStrip.s2,
                        ),
                        child: FxStripCard(
                          emphasize: true,
                          semanticsLabel:
                              '${iaAlunoHubViewLabel(_view)}. ${iaAlunoHubSubtitle(_view)}',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                iaAlunoHubViewLabel(_view),
                                style: FocuxHubTypography.sectionTitle(
                                  context,
                                  color: chrome.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                iaAlunoHubSubtitle(_view),
                                style: FocuxHubTypography.bodyMuted(
                                  color: chrome.mute,
                                ),
                              ),
                              const SizedBox(height: TokensStrip.s3),
                              DashboardHomeActionChip(
                                label:
                                    _view == IaAlunoHubView.chat
                                        ? 'Fazer pergunta'
                                        : 'Gerar progressão',
                                accent: primary,
                                isDark: chrome.isDark,
                                onPressed: () {
                                  if (_view == IaAlunoHubView.chat) {
                                    setState(() => _view = IaAlunoHubView.chat);
                                    _focusChatTick.value++;
                                  } else {
                                    _generateTick.value++;
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: IndexedStack(
                          index: _view.index,
                          children: [
                            _ChatTab(
                              alunoId: _alunoId,
                              focusChatTick: _focusChatTick,
                            ),
                            _ProgressaoTab(
                              alunoId: _alunoId,
                              generateTick: _generateTick,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Chat Tab ─────────────────────────────────────────────────────────────────

class _IaMsg {
  final String texto;
  final bool isUser;
  _IaMsg({required this.texto, required this.isUser});
}

class _ChatTab extends ConsumerStatefulWidget {
  final int? alunoId;
  final ValueNotifier<int> focusChatTick;
  const _ChatTab({this.alunoId, required this.focusChatTick});

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final List<_IaMsg> _msgs = [];
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  bool _loading = false;
  Object? _threadError;
  String? _pendingRetry;

  @override
  void initState() {
    super.initState();
    widget.focusChatTick.addListener(_onFocusChatTick);
  }

  @override
  void didUpdateWidget(covariant _ChatTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusChatTick != widget.focusChatTick) {
      oldWidget.focusChatTick.removeListener(_onFocusChatTick);
      widget.focusChatTick.addListener(_onFocusChatTick);
    }
  }

  void _onFocusChatTick() {
    if (!mounted) return;
    _focus.requestFocus();
  }

  @override
  void dispose() {
    widget.focusChatTick.removeListener(_onFocusChatTick);
    _ctrl.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar({String? overrideText}) async {
    final text = (overrideText ?? _ctrl.text).trim();
    if (text.isEmpty || _loading) return;
    if (overrideText == null) _ctrl.clear();
    final hadPriorMessages = _msgs.isNotEmpty;
    setState(() {
      _threadError = null;
      _pendingRetry = null;
      if (overrideText == null) {
        _msgs.add(_IaMsg(texto: text, isUser: true));
      } else if (_msgs.isEmpty || !_msgs.last.isUser) {
        _msgs.add(_IaMsg(texto: text, isUser: true));
      }
      _loading = true;
    });
    _scrollToBottom();
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      final resposta = await repo.chat(text, alunoId: widget.alunoId);
      if (mounted) {
        setState(() => _msgs.add(_IaMsg(texto: resposta, isUser: false)));
      }
    } catch (e) {
      if (mounted) {
        if (hadPriorMessages) {
          setState(
            () => _msgs.add(_IaMsg(texto: friendlyError(e), isUser: false)),
          );
        } else {
          setState(() {
            if (_msgs.isNotEmpty && _msgs.last.isUser) {
              _msgs.removeLast();
            }
            _threadError = e;
            _pendingRetry = text;
          });
        }
        await IaQuotaUpgrade.handleError(context, ref, e);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Expanded(
          child:
              _threadError != null
                  ? FxErrorState(
                    chromeOnDark: chrome.isDark,
                    primary: primary,
                    message: friendlyError(_threadError!),
                    onRetry: () {
                      final retry = _pendingRetry;
                      setState(() {
                        _threadError = null;
                        _pendingRetry = null;
                      });
                      if (retry != null) {
                        _enviar(overrideText: retry);
                      }
                    },
                  )
                  : _msgs.isEmpty
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FxEmptyState(
                        icon: 'spark',
                        title: 'Comece uma conversa',
                        subtitle:
                            'Pergunte sobre treino ou saúde ao assistente.',
                        action: FxEmptyAction(
                          label: 'Escrever pergunta',
                          onTap: () => _focus.requestFocus(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const IaSafetyDisclaimer(),
                    ],
                  )
                  : ListView.builder(
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(12),
                    itemCount: _msgs.length + (_loading ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _msgs.length) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: FxLoading(),
                        );
                      }
                      final m = _msgs[i];
                      return Align(
                        alignment:
                            m.isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color:
                                m.isUser
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            m.texto,
                            style: TextStyle(
                              color: m.isUser ? Colors.white : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
        ),
        const Divider(height: 1),
        IaChatComposer(
          controller: _ctrl,
          focusNode: _focus,
          loading: _loading,
          onSend: _enviar,
        ),
      ],
    );
  }
}

// ─── Progressão Tab ───────────────────────────────────────────────────────────

class _ProgressaoTab extends ConsumerStatefulWidget {
  final int? alunoId;
  final ValueNotifier<int> generateTick;
  const _ProgressaoTab({this.alunoId, required this.generateTick});

  @override
  ConsumerState<_ProgressaoTab> createState() => _ProgressaoTabState();
}

class _ProgressaoTabState extends ConsumerState<_ProgressaoTab> {
  bool _loading = false;
  IaProgressaoCargaResult? _resultado;
  Object? _erro;

  @override
  void initState() {
    super.initState();
    widget.generateTick.addListener(_onGenerateTick);
  }

  @override
  void didUpdateWidget(covariant _ProgressaoTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generateTick != widget.generateTick) {
      oldWidget.generateTick.removeListener(_onGenerateTick);
      widget.generateTick.addListener(_onGenerateTick);
    }
  }

  void _onGenerateTick() {
    if (!mounted || _loading) return;
    _gerarProgressao();
  }

  @override
  void dispose() {
    widget.generateTick.removeListener(_onGenerateTick);
    super.dispose();
  }

  Future<void> _gerarProgressao() async {
    final id = widget.alunoId;
    if (id == null || id <= 0) {
      FeedbackHelper.showError(
        context,
        'Não foi possível identificar seu perfil de aluno.',
      );
      return;
    }
    setState(() {
      _loading = true;
      _resultado = null;
      _erro = null;
    });
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      final r = await repo.progressaoCarga(id);
      if (mounted) setState(() => _resultado = r);
    } catch (e) {
      if (mounted) {
        setState(() => _erro = e);
        await IaQuotaUpgrade.handleError(context, ref, e);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(TokensStrip.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_resultado == null && !_loading && _erro == null)
            FxEmptyState(
              icon: 'spark',
              title: 'Progressão de carga',
              subtitle:
                  'Gere recomendações com base no seu histórico de treinos.',
              action: FxEmptyAction(
                label: 'Gerar recomendações',
                onTap: _gerarProgressao,
              ),
            )
          else ...[
            Text(
              'Progressão de Carga',
              style: FocuxHubTypography.sectionTitle(
                context,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gere recomendações personalizadas de progressão de carga com base no seu histórico de treinos.',
              style: TextStyle(color: TokensStrip.textSecondary),
            ),
            const SizedBox(height: 8),
            const IaSafetyDisclaimer(compact: true),
            const SizedBox(height: 20),
            FxLiquidPrimaryButton(
              label: _loading ? 'Analisando...' : 'Gerar Recomendações',
              icon: Icons.auto_awesome,
              loading: _loading,
              onPressed: _loading ? null : _gerarProgressao,
            ),
          ],
          if (_loading) const IaProgressaoLoadingSkeleton(),
          if (_erro != null) ...[
            const SizedBox(height: TokensStrip.s4),
            FxErrorState(
              chromeOnDark: chrome.isDark,
              primary: primary,
              message: friendlyError(_erro!),
              onRetry: _gerarProgressao,
            ),
          ],
          if (_resultado != null) ...[
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            IaProgressaoResultView(
              result: _resultado!,
              showSectionTitle: false,
              showApplyTreino: false,
            ),
          ],
        ],
      ),
    );
  }
}
