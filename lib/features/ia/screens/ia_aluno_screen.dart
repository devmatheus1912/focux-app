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
import '../widgets/ia_quota_upgrade.dart';
import '../../../core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

class IaAlunoScreen extends ConsumerStatefulWidget {
  const IaAlunoScreen({super.key});

  @override
  ConsumerState<IaAlunoScreen> createState() => _IaAlunoScreenState();
}

class _IaAlunoScreenState extends ConsumerState<IaAlunoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int? _alunoId;
  bool _resolving = true;
  Object? _resolveError;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _resolverAlunoId();
  }

  @override
  void dispose() {
    _tabs.dispose();
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
        });
      }
      return;
    } catch (_) {}

    try {
      final msgs =
          await ChatRepository(ref.read(apiClientProvider)).historicoAluno();
      final id = msgs.isNotEmpty ? msgs.first.alunoId : null;
      if (!mounted) return;
      if (id != null) {
        setState(() {
          _alunoId = id;
          _resolving = false;
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
    return fxScreenA11yScope(
      label: 'Assistente IA',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Assistente IA',
          subtitle: 'Chat e progressão personalizados',
          onBack: () => safePopOrGo(context, '/dashboard/aluno'),
        ),
        body:
            _resolving
                ? const Center(child: FxLoading())
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
                : Column(
                  children: [
                    Semantics(
                      container: true,
                      label: 'Abas do assistente: Chat e Progressão',
                      child: TabBar(
                        controller: _tabs,
                        labelColor: primary,
                        unselectedLabelColor: chrome.mute,
                        indicatorColor: primary,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.chat_bubble_outline_rounded),
                            text: 'Chat',
                          ),
                          Tab(
                            icon: Icon(Icons.trending_up_rounded),
                            text: 'Progressão',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabs,
                        children: [
                          _ChatTab(alunoId: _alunoId),
                          _ProgressaoTab(alunoId: _alunoId),
                        ],
                      ),
                    ),
                  ],
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
  const _ChatTab({this.alunoId});

  @override
  ConsumerState<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<_ChatTab> {
  final List<_IaMsg> _msgs = [];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = false;
  Object? _threadError;
  String? _pendingRetry;

  @override
  void dispose() {
    _ctrl.dispose();
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
                  ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FxEmptyState(
                        icon: 'spark',
                        title: 'Comece uma conversa',
                        subtitle:
                            'Pergunte sobre treino, dieta ou saúde ao assistente.',
                      ),
                      SizedBox(height: 8),
                      IaSafetyDisclaimer(),
                    ],
                  )
                  : ListView.builder(
                    controller: _scroll,
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
        Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: 'Pergunte ao assistente...',
                    border: FxInputDeco.outlineBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviar(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.send),
                onPressed: _loading ? null : () => _enviar(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Progressão Tab ───────────────────────────────────────────────────────────

class _ProgressaoTab extends ConsumerStatefulWidget {
  final int? alunoId;
  const _ProgressaoTab({this.alunoId});

  @override
  ConsumerState<_ProgressaoTab> createState() => _ProgressaoTabState();
}

class _ProgressaoTabState extends ConsumerState<_ProgressaoTab> {
  bool _loading = false;
  IaProgressaoCargaResult? _resultado;
  Object? _erro;

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
      padding: const EdgeInsets.all(TokensStrip.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Progressão de Carga',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
