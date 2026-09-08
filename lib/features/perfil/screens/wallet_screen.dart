import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import '../utils/wallet_pix_validation.dart';

part 'wallet_screen_widgets.part.dart';

/// Configuração de PIX e dados bancários para recebimentos.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _formKey = GlobalKey<FormState>();

  final _chavePixCtrl = TextEditingController();
  final _bancoCtrl = TextEditingController();
  final _agenciaCtrl = TextEditingController();
  final _contaCtrl = TextEditingController();

  String? _tipoChavePix;
  bool _carregando = false;
  bool _inicializado = false;
  var _secao = walletDetalheSecaoPix;
  DateTime? _fetchedAt;

  String? _snapshotTipo;
  String _snapshotChave = '';
  String _snapshotBanco = '';
  String _snapshotAgencia = '';
  String _snapshotConta = '';

  static const List<String> _tiposChavePix = [
    'CPF',
    'CNPJ',
    'EMAIL',
    'TELEFONE',
    'ALEATORIA',
  ];

  @override
  void initState() {
    super.initState();
    for (final ctrl in [_chavePixCtrl, _bancoCtrl, _agenciaCtrl, _contaCtrl]) {
      ctrl.addListener(_onFormChanged);
    }
  }

  void _onFormChanged() {
    if (_inicializado) setState(() {});
  }

  @override
  void dispose() {
    for (final ctrl in [_chavePixCtrl, _bancoCtrl, _agenciaCtrl, _contaCtrl]) {
      ctrl
        ..removeListener(_onFormChanged)
        ..dispose();
    }
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    if (!_inicializado) return false;
    return _tipoChavePix != _snapshotTipo ||
        _chavePixCtrl.text != _snapshotChave ||
        _bancoCtrl.text != _snapshotBanco ||
        _agenciaCtrl.text != _snapshotAgencia ||
        _contaCtrl.text != _snapshotConta;
  }

  void _captureSnapshot() {
    _snapshotTipo = _tipoChavePix;
    _snapshotChave = _chavePixCtrl.text;
    _snapshotBanco = _bancoCtrl.text;
    _snapshotAgencia = _agenciaCtrl.text;
    _snapshotConta = _contaCtrl.text;
  }

  void _preencherDadosAtuais(PerfilPersonal perfil) {
    if (_inicializado) return;
    _inicializado = true;
    _tipoChavePix = perfil.tipoChavePix;
    _chavePixCtrl.text = WalletPixValidation.formatDisplay(
      _tipoChavePix,
      perfil.chavePix ?? '',
    );
    _bancoCtrl.text = perfil.banco ?? '';
    _agenciaCtrl.text = perfil.agencia ?? '';
    _contaCtrl.text = perfil.conta ?? '';
    _captureSnapshot();
    _fetchedAt = DateTime.now();
  }

  Future<bool> _confirmDiscard() {
    return showFxConfirmSheet(
      context,
      title: walletDiscardTitle(),
      message: walletDiscardMessage(),
      confirmLabel: 'Descartar',
      cancelLabel: 'Continuar editando',
      destructive: true,
    );
  }

  Future<void> _handleBack() async {
    if (_hasUnsavedChanges) {
      final discard = await _confirmDiscard();
      if (!discard || !mounted) return;
    }
    if (!mounted) return;
    safePopOrGo(context, '/perfil');
  }

  void _showHelp() {
    showFxHelpSheet(
      context,
      title: 'Carteira e PIX',
      subtitle: walletHubSubtitle(),
      tips: const [
        FxHelpTip(
          'Receber',
          'A chave PIX é o que o aluno usa para te pagar. Banco e agência são opcionais.',
          icon: 'pix',
        ),
        FxHelpTip(
          'Salvar',
          'Confirme no botão de baixo. Só então a chave vale nos recebimentos.',
          icon: 'circle-check',
        ),
      ],
    );
  }

  Future<void> _salvar() async {
    final tipoErro = WalletPixValidation.validateTipo(_tipoChavePix);
    if (tipoErro != null) {
      FeedbackHelper.showError(context, tipoErro);
      return;
    }
    final chaveErro = WalletPixValidation.validateChave(
      _tipoChavePix,
      _chavePixCtrl.text,
    );
    if (chaveErro != null) {
      FeedbackHelper.showError(context, chaveErro);
      setState(() => _secao = walletDetalheSecaoPix);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final ok = await showFxConfirmSheet(
      context,
      title: walletSalvarConfirmTitle(),
      message: walletSalvarConfirmMessage(),
      confirmLabel: walletSalvarTileLabel(),
    );
    if (!ok || !mounted) return;

    setState(() => _carregando = true);
    try {
      final repo = ref.read(perfilRepositoryProvider);
      await repo.atualizarWallet({
        if (_chavePixCtrl.text.isNotEmpty)
          'chavePix': WalletPixValidation.normalizeForApi(
            _tipoChavePix,
            _chavePixCtrl.text,
          ),
        if (_tipoChavePix != null) 'tipoChavePix': _tipoChavePix,
        if (_bancoCtrl.text.isNotEmpty) 'banco': _bancoCtrl.text.trim(),
        if (_agenciaCtrl.text.isNotEmpty) 'agencia': _agenciaCtrl.text.trim(),
        if (_contaCtrl.text.isNotEmpty) 'conta': _contaCtrl.text.trim(),
      });
      ref.invalidate(perfilProvider);
      if (mounted) {
        _captureSnapshot();
        _fetchedAt = DateTime.now();
        FeedbackHelper.showSuccess(context, 'Carteira atualizada com sucesso.');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _copiarChavePix() async {
    final chave = _chavePixCtrl.text.trim();
    if (chave.isEmpty) return;
    await copySensitiveToClipboard(chave);
    if (!mounted) return;
    FeedbackHelper.showSuccess(context, 'Chave PIX copiada.');
  }

  Future<void> _selecionarTipoPix() async {
    final selected = await showFxInsetPickerSheet<String>(
      context,
      title: 'Tipo de chave PIX',
      subtitle: 'Escolha o formato da chave que você vai receber.',
      selected: _tipoChavePix,
      items: [
        for (final tipo in _tiposChavePix)
          FxInsetPickerSheetItem(
            value: tipo,
            label: WalletPixValidation.labelForTipo(tipo),
          ),
      ],
    );
    if (selected == null || !mounted) return;
    final normalized = WalletPixValidation.normalizeForApi(
      _tipoChavePix,
      _chavePixCtrl.text,
    );
    setState(() {
      _tipoChavePix = selected;
      if (normalized.isNotEmpty) {
        _chavePixCtrl.text = WalletPixValidation.formatDisplay(
          selected,
          normalized,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final showSticky = !perfilAsync.isLoading && !perfilAsync.hasError;

    return fxScreenA11yScope(
      label: 'Carteira e PIX',
      child: FxKeyboardPopScope(
        child: PopScope(
          canPop: !_hasUnsavedChanges,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (MediaQuery.viewInsetsOf(context).bottom > 0) return;
            await _handleBack();
          },
          child: FxShellScaffold(
            useMesh: true,
            appBar: FxShellAppBar(
              title: 'Carteira e PIX',
              subtitle: FxHubFreshness.fromFetchedAt(_fetchedAt),
              onBack: _handleBack,
              actions: [
                FxHelpIconButton(
                  tooltip: 'Como usar a carteira',
                  onTap: _showHelp,
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: perfilAsync.when(
                    loading: () => const SkeletonList(count: 5),
                    error:
                        (e, _) => FxErrorState(
                          chromeOnDark: chrome.isDark,
                          primary: primary,
                          message: friendlyError(e),
                          onRetry: () => ref.invalidate(perfilProvider),
                          title: 'Não conseguimos carregar a carteira',
                        ),
                    data: (perfil) {
                      _preencherDadosAtuais(perfil);
                      return Form(
                        key: _formKey,
                        child: RefreshIndicator(
                          color: primary,
                          onRefresh: () async {
                            _inicializado = false;
                            ref.invalidate(perfilProvider);
                          },
                          child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            FxSettingsLayout.pageInset,
                            TokensStrip.s4,
                            FxSettingsLayout.pageInset,
                            TokensStrip.s4,
                          ),
                          children: [
                            FxContentWidthLimiter(
                              child: _WalletFormFields(
                                tipoChavePix: _tipoChavePix,
                                chavePixCtrl: _chavePixCtrl,
                                bancoCtrl: _bancoCtrl,
                                agenciaCtrl: _agenciaCtrl,
                                contaCtrl: _contaCtrl,
                                carregando: _carregando,
                                secao: _secao,
                                onSecao: (value) => setState(() => _secao = value),
                                onSelecionarTipo: _selecionarTipoPix,
                                onCopiarChave: _copiarChavePix,
                              ),
                            ),
                          ],
                        ),
                        ),
                      );
                    },
                  ),
                ),
                if (showSticky)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        TokensStrip.s2,
                        FxSettingsLayout.pageInset,
                        TokensStrip.s3 +
                            MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: FxLiquidPrimaryButton(
                        label: walletSalvarTileLabel(),
                        loading: _carregando,
                        loadingLabel: 'Salvando…',
                        onPressed: _carregando ? null : _salvar,
                      ),
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
