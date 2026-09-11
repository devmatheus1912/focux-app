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
import '../widgets/ia_chat_composer.dart';
import '../widgets/ia_quota_upgrade.dart';
import '../../../core/widgets/fx_loading.dart';
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
  static const _view = IaAlunoHubView.chat;
  int? _alunoId;
  bool _resolving = true;
  Object? _resolveError;
  DateTime? _fetchedAt;
  final _focusChatTick = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _resolverAlunoId();
  }

  @override
  void dispose() {
    _focusChatTick.dispose();
    super.dispose();
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
                    'Chat',
                    'Pergunte sobre treino ou saúde. Progressão de carga fica com o personal.',
                  ),
                ],
              ),
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
                                label: 'Fazer pergunta',
                                accent: primary,
                                isDark: chrome.isDark,
                                onPressed: () => _focusChatTick.value++,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: _ChatTab(
                          alunoId: _alunoId,
                          focusChatTick: _focusChatTick,
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
                              color: m.isUser
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
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

