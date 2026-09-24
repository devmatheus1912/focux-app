import 'dart:async';
import 'dart:convert';
import '../../../core/utils/friendly_error.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/utils/safe_external_launch.dart';
import '../../../core/config/env.dart';
import '../../../core/providers/personal_brand_provider.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/providers/aluno_detail_providers.dart';
import '../../alunos/providers/aluno_followup_provider.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../alunos/widgets/aluno_avatar.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/utils/aluno_dashboard_home_client_cache.dart';
import '../data/chat_repository.dart';
import '../data/chat_text_formatter.dart';
import '../utils/chat_bubble_grouping.dart';
import '../utils/chat_remetente.dart';
import '../utils/chat_system_event.dart';
import 'chat_inbox_screen.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import '../widgets/conversation_message_widgets.dart';
import '../widgets/conversation_composer_widgets.dart';
import '../widgets/conversation_media_widgets.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
part 'conversation_screen_messaging.part.dart';
part 'conversation_screen_sheets_actions.part.dart';
part 'conversation_screen_sheets_search.part.dart';
part 'conversation_screen_sheets_menu_media.part.dart';
part 'conversation_screen_sheets_helpers.part.dart';

enum ConversationMode { personal, aluno }

class ConversationScreen extends ConsumerStatefulWidget {
  final ConversationMode mode;
  final int? alunoId;
  final String? alunoNome;
  final String? initialDraft;

  const ConversationScreen.personal({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.initialDraft,
  }) : mode = ConversationMode.personal,
       assert(alunoId != null),
       assert(alunoNome != null);

  const ConversationScreen.aluno({super.key})
    : mode = ConversationMode.aluno,
      alunoId = null,
      alunoNome = null,
      initialDraft = null;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  static const _quickReactions = [
    '\u{1F525}',
    '\u{1F44F}',
    '\u{1F4AA}',
    '\u{2705}',
    '\u{1F64C}',
    '\u{1F680}',
    '\u{1F642}',
    '\u{1F605}',
    '\u{2764}\u{FE0F}',
    '\u{1F44A}',
  ];

  final List<ChatMsg> _msgs = [];
  final Map<String, GlobalKey> _messageKeys = {};
  final _ctrl = TextEditingController();
  final _composerFocus = FocusNode();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  final _audioRecorder = AudioRecorder();

  StompClient? _stomp;
  Timer? _wsReconnectTimer;
  Timer? _markReadDebounce;
  int _wsReconnectAttempt = 0;
  int? _wsAlunoId;
  bool _wsLifecycleEnded = false;
  bool _tabVisible = true;
  bool _markReadPending = false;
  static const _maxWsReconnectAttempts = 8;
  static const _markReadDebounceMs = 600;
  bool _loading = true;
  bool _uploading = false;
  bool _recordingAudio = false;
  bool _composerHasText = false;
  bool _loadingOlder = false;
  Object? _loadError;
  bool _hasMoreMessages = false;
  bool _initialDraftChecked = false;
  int? _alunoId;
  int? _nextBeforeId;
  ChatMsg? _replyingTo;
  int? _highlightedMessageId;
  Timer? _recordTimer;
  Duration _recordDuration = Duration.zero;
  DateTime? _recordStartedAt;

  bool get _isAlunoMode => widget.mode == ConversationMode.aluno;
  bool get _isPersonalMode => widget.mode == ConversationMode.personal;

  @override
  void initState() {
    super.initState();
    _alunoId = widget.alunoId;
    final draft = widget.initialDraft?.trim();
    if (draft != null && draft.isNotEmpty) {
      _ctrl.text = draft;
      _ctrl.selection = TextSelection.collapsed(offset: draft.length);
      _composerHasText = true;
    }
    _ctrl.addListener(_handleComposerChange);
    _scroll.addListener(_handleScroll);
    _loadHistorico();
    if (_alunoId != null) {
      _connectWs(_alunoId!);
    }
  }

  @override
  void dispose() {
    _wsLifecycleEnded = true;
    _wsReconnectTimer?.cancel();
    _markReadDebounce?.cancel();
    _stomp?.deactivate();
    _recordTimer?.cancel();
    unawaited(_audioRecorder.dispose());
    _scroll.removeListener(_handleScroll);
    _ctrl.removeListener(_handleComposerChange);
    _ctrl.dispose();
    _composerFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _handleComposerChange() {
    final next = _ctrl.text.trim().isNotEmpty;
    if (next != _composerHasText && mounted) {
      setState(() => _composerHasText = next);
    }
  }

  void _handleScroll() {
    if (!_scroll.hasClients || _loading || _loadingOlder || !_hasMoreMessages) {
      return;
    }
    if (_scroll.position.pixels <= 120) {
      unawaited(_loadOlderMessages());
    }
  }

  Future<void> _loadHistorico() async {
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      final page =
          _isAlunoMode
              ? await repo.historicoAlunoPage()
              : await repo.historicoPage(_alunoId!);
      final msgs = page.items;
      if (_isAlunoMode && msgs.isNotEmpty && _alunoId == null) {
        _alunoId = msgs.first.alunoId;
        if (_alunoId != null) {
          _connectWs(_alunoId!);
        }
      }
      if (!mounted) return;
      setState(() {
        _msgs
          ..clear()
          ..addAll(msgs);
        _nextBeforeId = page.nextBeforeId;
        _hasMoreMessages = page.hasMore;
        _loadError = null;
        _loading = false;
      });
      _dedupeInitialDraft();
      _scrollToBottom(animated: false);
      // Mark-read debounced — não atrasar o primeiro paint nem storm de HTTP.
      _scheduleMarkRead();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e;
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_loadingOlder || !_hasMoreMessages || _nextBeforeId == null) return;
    final previousMax =
        _scroll.hasClients ? _scroll.position.maxScrollExtent : 0.0;
    final previousOffset = _scroll.hasClients ? _scroll.offset : 0.0;
    setState(() => _loadingOlder = true);
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      final page =
          _isAlunoMode
              ? await repo.historicoAlunoPage(beforeId: _nextBeforeId)
              : await repo.historicoPage(_alunoId!, beforeId: _nextBeforeId);
      if (!mounted) return;
      setState(() {
        for (final msg in page.items) {
          _upsertMessage(msg);
        }
        _nextBeforeId = page.nextBeforeId;
        _hasMoreMessages = page.hasMore;
        _loadingOlder = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        final delta = _scroll.position.maxScrollExtent - previousMax;
        _scroll.jumpTo(previousOffset + delta);
      });
    } catch (_) {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  void _scheduleMarkRead() {
    _markReadDebounce?.cancel();
    if (!_tabVisible) {
      _markReadPending = true;
      return;
    }
    _markReadPending = false;
    _markReadDebounce = Timer(
      const Duration(milliseconds: _markReadDebounceMs),
      () {
        if (_wsLifecycleEnded || !mounted) return;
        unawaited(_markRead());
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _tabVisible) return;
    _tabVisible = visible;
    if (!visible) return;
    if (_wsAlunoId != null && _wsReconnectAttempt >= _maxWsReconnectAttempts) {
      _wsReconnectAttempt = 0;
      _stomp?.deactivate();
      _stomp = null;
      unawaited(_connectWs(_wsAlunoId!));
      unawaited(_loadHistorico());
      return;
    }
    if (_markReadPending) _scheduleMarkRead();
  }

  Future<void> _markRead() async {
    final repo = ChatRepository(ref.read(apiClientProvider));
    if (_isAlunoMode) {
      await repo.marcarLidoAluno();
      if (!mounted) return;
      AlunoDashboardHomeClientCache.clear();
      ref.invalidate(alunoDashboardHomeProvider);
      return;
    } else if (_alunoId != null) {
      await repo.marcarLido(_alunoId!);
    } else {
      return;
    }
    if (mounted) invalidateChatInboxCaches(ref);
  }

  Future<void> _connectWs(int alunoId) async {
    if (_wsLifecycleEnded) {
      return;
    }
    _wsAlunoId = alunoId;
    if (_stomp != null) {
      return;
    }
    // Token fresco a cada connect/reconnect (evita JWT stale).
    final token = await SecureStorage.getToken();
    final url = '${Env.wsUrl}/ws/websocket';
    _stomp = StompClient(
      config: StompConfig(
        url: url,
        onConnect: (frame) => _onConnect(frame, alunoId),
        beforeConnect: () async {},
        onStompError: (_) => _scheduleWsReconnect(),
        onDisconnect: (_) => _scheduleWsReconnect(),
        onWebSocketError: (_) => _scheduleWsReconnect(),
        stompConnectHeaders:
            token != null ? {'Authorization': 'Bearer $token'} : {},
        webSocketConnectHeaders:
            token != null ? {'Authorization': 'Bearer $token'} : {},
      ),
    );
    _stomp!.activate();
  }

  void _scheduleWsReconnect() {
    _wsReconnectTimer?.cancel();
    if (_wsLifecycleEnded || _wsAlunoId == null) {
      return;
    }
    if (_wsReconnectAttempt >= _maxWsReconnectAttempts) {
      return;
    }
    final exp = _wsReconnectAttempt.clamp(0, 6);
    final delayMs = (600 * (1 << exp)).clamp(600, 30000);
    _wsReconnectAttempt++;
    _wsReconnectTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (_wsLifecycleEnded || !mounted || _wsAlunoId == null) {
        return;
      }
      try {
        _stomp?.deactivate();
      } catch (_) {}
      _stomp = null;
      await _connectWs(_wsAlunoId!);
    });
  }

  void _onConnect(StompFrame frame, int alunoId) {
    _wsReconnectAttempt = 0;
    final destination =
        _isAlunoMode
            ? '/topic/chat.aluno.$alunoId'
            : '/topic/chat.personal.$alunoId';
    _stomp?.subscribe(
      destination: destination,
      callback: (f) async {
        if (f.body == null) return;
        try {
          final data = jsonDecode(f.body!) as Map<String, dynamic>;
          final msg = ChatMsg.fromJson(data);
          if (!mounted) return;
          setState(() => _upsertMessage(msg));
          if (_isIncoming(msg)) {
            _scheduleMarkRead();
          }
          _scrollToBottom();
        } catch (_) {
          await _loadHistorico();
        }
      },
    );
  }

  bool _isIncoming(ChatMsg msg) {
    if (chatIsSistema(msg.remetente, msg.tipoMidia)) return true;
    return _isAlunoMode
        ? msg.remetente == 'PERSONAL'
        : msg.remetente == 'ALUNO';
  }

  bool _isMine(ChatMsg msg) {
    if (chatIsSistema(msg.remetente, msg.tipoMidia)) return false;
    return _isAlunoMode
        ? msg.remetente == 'ALUNO'
        : msg.remetente == 'PERSONAL';
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: isDark);
    final brand =
        _isAlunoMode ? ref.watch(personalBrandProvider).valueOrNull : null;
    final alunoFotoUrl =
        _isPersonalMode && widget.alunoId != null
            ? ref.watch(alunoProvider(widget.alunoId!)).valueOrNull?.fotoUrl
            : null;
    final title = _displayName(brand);
    final subtitle = _subtitle(brand);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final avatarUrl = _avatarImage(brand, alunoFotoUrl: alunoFotoUrl);

    final backFallback =
        _isAlunoMode ? '/dashboard/aluno' : '/dashboard/personal';

    final scaffold = FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        safeAreaBottom: true,
        appBar: FxShellAppBar(
          title: title,
          subtitle: subtitle,
          onBack: () {
            FxKeyboardDismissScope.dismiss();
            safePopOrGo(context, backFallback);
          },
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: AlunoAvatar(
                name: title,
                photoUrl: avatarUrl,
                variant: AlunoAvatarVariant.strip,
              ),
            ),
            IconButton(
              onPressed: _showSearchSheet,
              icon: const Icon(Icons.search_rounded),
            ),
            IconButton(
              onPressed: _showChatMenu,
              icon: const Icon(Icons.more_horiz),
            ),
          ],
        ),
        body: FxKeyboardDismissScope(
          child: Stack(
          children: [
            Positioned.fill(
              child: const ConversationChatBackdrop(),
            ),
            Column(
              children: [
                if (_uploading)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: primarySoft,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: FxLoading(strokeWidth: 2, color: primary),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Enviando anexo...',
                          style: TextStyle(
                            color:
                                isDark
                                    ? EagleTokens.darkInk
                                    : TokensStrip.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child:
                      _loading
                          ? const Padding(
                            padding: EdgeInsets.all(TokensStrip.s4),
                            child: SkeletonList(count: 6),
                          )
                          : _loadError != null
                          ? FxErrorState(
                            chromeOnDark: isDark,
                            primary: primary,
                            message: friendlyError(
                              _loadError!,
                              fallback:
                                  'Não foi possível carregar a conversa. Verifique a conexão e tente novamente.',
                            ),
                            onRetry: () {
                              setState(() {
                                _loading = true;
                                _loadError = null;
                              });
                              unawaited(_loadHistorico());
                            },
                          )
                          : _msgs.isEmpty
                          ? _ConversationQuietEmpty(
                            isAluno: _isAlunoMode,
                          )
                          : ListView.builder(
                            controller: _scroll,
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding: EdgeInsets.fromLTRB(
                              TokensStrip.s3,
                              TokensStrip.s3,
                              TokensStrip.s3,
                              TokensStrip.s2,
                            ),
                            itemCount:
                                _msgs.length +
                                (_hasMoreMessages || _loadingOlder ? 1 : 0),
                            itemBuilder: (_, index) {
                              final hasLoader =
                                  _hasMoreMessages || _loadingOlder;
                              if (hasLoader && index == 0) {
                                return ConversationOlderMessagesLoader(
                                  loading: _loadingOlder,
                                  onTap: _loadOlderMessages,
                                );
                              }
                              final msgIndex = hasLoader ? index - 1 : index;
                              final msg = _msgs[msgIndex];
                              final previous =
                                  msgIndex > 0 ? _msgs[msgIndex - 1] : null;
                              final next =
                                  msgIndex + 1 < _msgs.length
                                      ? _msgs[msgIndex + 1]
                                      : null;
                              final showDate =
                                  previous == null ||
                                  !_sameDay(previous.enviadoEm, msg.enviadoEm);
                              final system = chatIsSistema(
                                msg.remetente,
                                msg.tipoMidia,
                              );
                              final groupSlot =
                                  system
                                      ? ChatBubbleGroupSlot.single
                                      : resolveChatBubbleGroupSlot(
                                        msg: msg,
                                        older: previous,
                                        newer: next,
                                        isMine: _isMine,
                                        isSystem:
                                            (m) => chatIsSistema(
                                              m.remetente,
                                              m.tipoMidia,
                                            ),
                                      );
                              return Column(
                                children: [
                                  if (showDate)
                                    ConversationDateDivider(
                                      date: msg.enviadoEm,
                                    ),
                                  KeyedSubtree(
                                    key: _messageKey(msg),
                                    child:
                                        system
                                            ? ConversationSystemEvent(msg: msg)
                                            : ConversationSwipeReplyWrapper(
                                              alignRight: _isMine(msg),
                                              accentColor: primary,
                                              onReply: () => _setReply(msg),
                                              child: ConversationBubble(
                                                msg: msg,
                                                mine: _isMine(msg),
                                                isDark: isDark,
                                                accentColor: primary,
                                                groupSlot: groupSlot,
                                                highlighted:
                                                    _highlightedMessageId ==
                                                    msg.id,
                                                replyLabelBuilder:
                                                    _replySenderLabel,
                                                onLongPress:
                                                    () =>
                                                        _showMessageActions(msg),
                                                onReplyTap:
                                                    msg.replyToMessageId == null
                                                        ? null
                                                        : () =>
                                                            _jumpToReplySource(
                                                              msg,
                                                            ),
                                                onOpenMedia:
                                                    () => _openMedia(msg),
                                              ),
                                            ),
                                  ),
                                ],
                              );
                            },
                          ),
                ),
                ConversationMessageComposer(
                  isDark: isDark,
                  uploading: _uploading,
                  composerHasText: _composerHasText,
                  recordingAudio: _recordingAudio,
                  textController: _ctrl,
                  composerFocus: _composerFocus,
                  showReplyBar: _replyingTo != null,
                  replySender:
                      _replyingTo == null
                          ? null
                          : _replySenderLabel(_replyingTo!.remetente),
                  replyPreview:
                      _replyingTo == null ? null : _previewText(_replyingTo!),
                  recordDurationLabel: _formatDuration(_recordDuration),
                  onCloseReply: () => setState(() => _replyingTo = null),
                  onCancelRecording: () => _stopAudioRecording(send: false),
                  onSendRecording: () => _stopAudioRecording(send: true),
                  onAttach: _showAttachmentSheet,
                  onEmoji: _showEmojiSheet,
                  onSendText: _sendText,
                  onStartRecording: _startAudioRecording,
                  onStopRecordingSend: () => _stopAudioRecording(send: true),
                ),
              ],
            ),
          ],
        ),
        ),
    );

    return fxScreenA11yScope(
      label: 'Conversa',
      child: PopScope(
        canPop: !keyboardOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (keyboardOpen) {
            FxKeyboardDismissScope.dismiss();
            return;
          }
          safePopOrGo(context, backFallback);
        },
        child: scaffold,
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }
}

/// Empty quieto no topo — sem parede de whitespace (§11 chat).
class _ConversationQuietEmpty extends StatelessWidget {
  const _ConversationQuietEmpty({required this.isAluno});

  final bool isAluno;

  @override
  Widget build(BuildContext context) {
    return FxEmptyState(
      icon: 'chat',
      title: 'Envie a primeira mensagem',
      subtitle:
          isAluno
              ? 'Fotos e ajustes do treino ficam aqui.'
              : 'Fotos, áudios e ajustes ficam aqui.',
      quiet: true,
    );
  }
}
