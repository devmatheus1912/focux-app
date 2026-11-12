import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../core/widgets/ia_safety_disclaimer.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../moderacao/data/moderacao_repository.dart';
import '../../moderacao/widgets/denunciar_sheet.dart';
import '../data/ia_chat_store.dart';
import '../data/ia_repository.dart';
import '../utils/ia_chat_display.dart';
import '../utils/ia_texto_formatado.dart';
import '../widgets/ia_chat_composer.dart';
import '../widgets/ia_quota_upgrade.dart';

/// Perguntas para começar (tocar envia).
const iaChatSugestoes = [
  'Aluno com dor no treino',
  'Montar treino para iniciante',
  'Como progredir carga',
  'Aluno sem tempo para treinar',
];

/// Chat da IA Focux: lembra a conversa (manda as últimas mensagens), guarda
/// no aparelho para continuar depois e pode falar sobre um aluno.
class IaChatScreen extends ConsumerStatefulWidget {
  const IaChatScreen({super.key, this.conversaId});

  /// Abre uma conversa guardada (`/ia/chat?c=`).
  final String? conversaId;

  @override
  ConsumerState<IaChatScreen> createState() => _IaChatScreenState();
}

class _IaChatScreenState extends ConsumerState<IaChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  var _msgs = <IaChatMsg>[];
  late String _id = widget.conversaId ?? DateTime.now().microsecondsSinceEpoch.toString();
  int? _alunoId;
  String? _alunoNome;
  bool _loading = false;
  Object? _erro;
  String? _pendente;

  @override
  void initState() {
    super.initState();
    final id = widget.conversaId;
    if (id != null) _abrirGuardada(id);
  }

  Future<void> _abrirGuardada(String id) async {
    final todas = await ref.read(iaChatStoreProvider).listar();
    final c = todas.where((c) => c.id == id).firstOrNull;
    if (c == null || !mounted) return;
    setState(() {
      _id = c.id;
      _msgs = [...c.mensagens];
      _alunoId = c.alunoId;
      _alunoNome = c.alunoNome;
    });
    _rolarAoFim();
  }

  Future<void> _guardar() async {
    if (_msgs.isEmpty) return;
    await ref.read(iaChatStoreProvider).salvar(
      IaConversa(
        id: _id,
        atualizadaEm: DateTime.now(),
        mensagens: _msgs,
        alunoId: _alunoId,
        alunoNome: _alunoNome,
      ),
    );
    ref.invalidate(iaConversasProvider);
  }

  Future<void> _enviar({String? texto}) async {
    final pergunta = (texto ?? _ctrl.text).trim();
    if (pergunta.isEmpty || _loading) return;
    if (!await IaQuotaUpgrade.guardBeforeRequest(context, ref)) return;
    final historico = iaHistoricoParaEnvio(_msgs);
    if (texto == null) _ctrl.clear();
    setState(() {
      _erro = null;
      _pendente = null;
      _msgs = [..._msgs, IaChatMsg(autor: 'PERSONAL', texto: pergunta)];
      _loading = true;
    });
    _rolarAoFim();
    try {
      final resposta = await IaRepository(ref.read(apiClientProvider)).chat(
        pergunta,
        alunoId: _alunoId,
        historico: historico,
      );
      if (!mounted) return;
      setState(() => _msgs = [..._msgs, IaChatMsg(autor: 'IA', texto: resposta)]);
      await _guardar();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // A pergunta volta para o campo: tentar de novo é um toque.
        _msgs = _msgs.sublist(0, _msgs.length - 1);
        _erro = e;
        _pendente = pergunta;
      });
      await IaQuotaUpgrade.handleError(context, ref, e);
    } finally {
      if (mounted) setState(() => _loading = false);
      _rolarAoFim();
    }
  }

  void _rolarAoFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _escolherAluno() async {
    try {
      final home = await ref.read(alunosHomeProvider.future);
      if (!mounted) return;
      final picked = await showFxInsetPickerSheet<int>(
        context,
        title: 'Sobre qual aluno?',
        subtitle: 'A IA Focux usa o objetivo dele, sem o nome.',
        selected: _alunoId,
        items: [
          const FxInsetPickerSheetItem(value: 0, label: 'Nenhum (pergunta geral)'),
          for (final a in home.alunos)
            FxInsetPickerSheetItem(value: a.id, label: fxTitleCaseName(a.nome)),
        ],
      );
      if (picked == null || !mounted) return;
      final aluno = home.alunos.where((a) => a.id == picked).firstOrNull;
      setState(() {
        _alunoId = aluno?.id;
        _alunoNome = aluno == null ? null : fxTitleCaseName(aluno.nome).split(' ').first;
      });
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _opcoes(IaChatMsg m) async {
    final acao = await showFxGroupedActionSheet<String>(
      context,
      titulo: 'Resposta da IA Focux',
      grupos: [
        FxActionGroup<String>(null, const [
          FxActionItem(valor: 'copiar', rotulo: 'Copiar', icone: FxIcons.copiar),
          FxActionItem(
            valor: 'denunciar',
            rotulo: 'Denunciar resposta',
            icone: FxIcons.meta,
          ),
        ]),
      ],
    );
    if (!mounted) return;
    if (acao == 'copiar') _copiar(m);
    if (acao == 'denunciar') _denunciar(m);
  }

  void _copiar(IaChatMsg m) {
    Clipboard.setData(ClipboardData(text: iaTextoLimpo(m.texto)));
    FeedbackHelper.showSuccess(context, 'Resposta copiada');
  }

  void _denunciar(IaChatMsg m) => showDenunciarSheet(
    context,
    repo: ModeracaoRepository(ref.read(apiClientProvider)),
    tipo: DenunciaTipo.iaResposta,
    conteudo: m.texto,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return fxScreenA11yScope(
      label: 'IA Focux',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'IA Focux',
          subtitle: _alunoNome == null ? 'Treino e prescrição' : 'Sobre $_alunoNome',
          onBack: () => safePopOrGo(context, '/ia/copiloto'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar a IA Focux',
              onTap:
                  () => showFxHelpSheet(
                    context,
                    title: 'IA Focux',
                    subtitle: 'Pergunte. Nada chega ao aluno sem você.',
                    tips: const [
                      FxHelpTip('Como calculamos', iaChatComoCalculamos),
                      FxHelpTip(
                        'Conversa',
                        'A IA lembra o que vocês falaram nesta conversa. Ela fica guardada neste celular.',
                      ),
                      FxHelpTip(
                        'Sobre um aluno',
                        'Escolha o aluno no topo: a IA usa o objetivo dele, sem o nome.',
                      ),
                    ],
                  ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
                FxSettingsLayout.pageInset,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FxToggleChip(
                  label: _alunoNome == null ? 'Escolher aluno' : 'Sobre $_alunoNome',
                  selected: _alunoNome != null,
                  isDark: chrome.isDark,
                  filledWhenSelected: true,
                  onTap: _loading ? null : _escolherAluno,
                ),
              ),
            ),
            Expanded(
              child: FxContentWidthLimiter(
                child:
                    _msgs.isEmpty && !_loading
                        ? _vazio(chrome)
                        : ListView.builder(
                          controller: _scroll,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(
                            FxSettingsLayout.pageInset,
                            TokensStrip.s3,
                            FxSettingsLayout.pageInset,
                            TokensStrip.s3,
                          ),
                          itemCount: _msgs.length + (_loading ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _msgs.length) {
                              return const Padding(
                                padding: EdgeInsets.all(TokensStrip.s2),
                                child: FxLoading(),
                              );
                            }
                            return _balao(_msgs[i], chrome, primary);
                          },
                        ),
              ),
            ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FxSettingsLayout.pageInset,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        friendlyError(
                          _erro!,
                          fallback: 'Não consegui falar com a IA agora.',
                        ),
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tentar de novo',
                      icon: Icon(FxIcons.repetir, color: primary),
                      onPressed:
                          _pendente == null ? null : () => _enviar(texto: _pendente),
                    ),
                  ],
                ),
              ),
            const IaSafetyDisclaimer(compact: true),
            const Divider(height: 1),
            IaChatComposer(
              controller: _ctrl,
              loading: _loading,
              hint: 'Pergunte à IA Focux',
              onSend: _enviar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _vazio(ShellPalette chrome) {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s4,
        FxSettingsLayout.pageInset,
        TokensStrip.s4,
      ),
      children: [
        Text(
          'Pergunte sobre treino, prescrição ou um aluno.',
          style: FocuxHubTypography.body(color: chrome.ink),
        ),
        const SizedBox(height: TokensStrip.s3),
        Wrap(
          spacing: TokensStrip.s2,
          runSpacing: TokensStrip.s2,
          children: [
            for (final s in iaChatSugestoes)
              FxToggleChip(
                label: s,
                selected: false,
                isDark: chrome.isDark,
                onTap: () => _enviar(texto: s),
              ),
          ],
        ),
      ],
    );
  }

  Widget _balao(IaChatMsg m, ShellPalette chrome, Color primary) {
    final daIa = m.daIa;
    final largura = MediaQuery.sizeOf(context).width * 0.8;
    final estilo = FocuxHubTypography.body(
      color: daIa ? chrome.ink : Theme.of(context).colorScheme.onPrimary,
    );
    final balao = GestureDetector(
      onLongPress: daIa ? () => _opcoes(m) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: TokensStrip.s1),
        padding: const EdgeInsets.symmetric(
          horizontal: TokensStrip.s3,
          vertical: TokensStrip.s2,
        ),
        constraints: BoxConstraints(maxWidth: largura),
        decoration: BoxDecoration(
          color:
              daIa
                  ? Theme.of(context).colorScheme.surfaceContainerHigh
                  : primary,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
        ),
        child:
            daIa
                ? IaTextoFormatado(m.texto, style: estilo)
                : Text(m.texto, style: estilo),
      ),
    );
    if (!daIa) {
      return Align(alignment: Alignment.centerRight, child: balao);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        balao,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Copiar resposta',
              visualDensity: VisualDensity.compact,
              icon: Icon(FxIcons.copiar, color: chrome.mute, size: 18),
              onPressed: () => _copiar(m),
            ),
            IconButton(
              tooltip: 'Denunciar resposta',
              visualDensity: VisualDensity.compact,
              icon: Icon(FxIcons.meta, color: chrome.mute, size: 18),
              onPressed: () => _denunciar(m),
            ),
          ],
        ),
      ],
    );
  }
}
