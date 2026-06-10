import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/ia_safety_disclaimer.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/ia_repository.dart';
import '../widgets/ia_quota_upgrade.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

class _IaMsg {
  final String texto;
  final bool isUser;
  _IaMsg({required this.texto, required this.isUser});
}

class IaChatScreen extends ConsumerStatefulWidget {
  const IaChatScreen({super.key});

  @override
  ConsumerState<IaChatScreen> createState() => _IaChatScreenState();
}

class _IaChatScreenState extends ConsumerState<IaChatScreen> {
  final List<_IaMsg> _msgs = [];
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _loading = false;

  Future<void> _enviar() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    if (!await IaQuotaUpgrade.guardBeforeRequest(context, ref)) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(_IaMsg(texto: text, isUser: true));
      _loading = true;
    });
    _scrollToBottom();
    try {
      final resposta = await IaRepository(
        ref.read(apiClientProvider),
      ).chat(text);
      if (mounted) {
        setState(() => _msgs.add(_IaMsg(texto: resposta, isUser: false)));
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _msgs.add(
            _IaMsg(
              texto: e is IaOperationalException ? e.message : friendlyError(e),
              isUser: false,
            ),
          ),
        );
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
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return fxScreenA11yScope(
      label: 'Assistente IA',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Assistente IA',
          subtitle: 'Chat inteligente para o seu negócio',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
        ),
        body: Column(
          children: [
            Expanded(
              child:
                  _msgs.isEmpty
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Pergunte ao seu assistente de fitness!',
                            style: TextStyle(color: chrome.mute),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const IaSafetyDisclaimer(),
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
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    m.isUser
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(
                                          context,
                                        ).colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(
                                  TokensStrip.rCard,
                                ),
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
            if (_msgs.isNotEmpty) const IaSafetyDisclaimer(compact: true),
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
                        hintText: 'Pergunte sobre treino, dieta...',
                        border: FxInputDeco.outlineBorder(
                          borderRadius: BorderRadius.circular(
                            TokensStrip.rCard,
                          ),
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
                    onPressed: _loading ? null : _enviar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
