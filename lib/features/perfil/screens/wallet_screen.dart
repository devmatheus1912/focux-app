import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/confirmar_no_aparelho.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import '../utils/wallet_pix_validation.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/theme/fx_icons.dart';

part 'wallet_screen_widgets.part.dart';

/// Chave PIX que recebe os pagamentos dos alunos.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chavePixCtrl = TextEditingController();

  String? _tipoChavePix;
  bool _carregando = false;
  bool _inicializado = false;
  var _editandoChave = false;

  String? _snapshotTipo;
  String _snapshotChave = '';

  @override
  void initState() {
    super.initState();
    _chavePixCtrl.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (_inicializado) setState(() {});
  }

  @override
  void dispose() {
    _chavePixCtrl
      ..removeListener(_onFormChanged)
      ..dispose();
    super.dispose();
  }

  bool get _temChaveSalva =>
      _snapshotChave.trim().isNotEmpty &&
      (_snapshotTipo ?? '').trim().isNotEmpty;

  bool get _hasUnsavedChanges {
    if (!_inicializado) return false;
    return _tipoChavePix != _snapshotTipo ||
        _chavePixCtrl.text != _snapshotChave;
  }

  void _captureSnapshot() {
    _snapshotTipo = _tipoChavePix;
    _snapshotChave = _chavePixCtrl.text;
  }

  void _preencherDadosAtuais(PerfilPersonal perfil) {
    if (_inicializado) return;
    _inicializado = true;
    _tipoChavePix = perfil.tipoChavePix;
    _chavePixCtrl.text = WalletPixValidation.formatDisplay(
      _tipoChavePix,
      perfil.chavePix ?? '',
    );
    _captureSnapshot();
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
    FxKeyboardDismissScope.dismiss();
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
      subtitle: walletParaQueServe(),
      tips: const [
        FxHelpTip(
          'Receber',
          'A chave PIX é o que o aluno usa para te pagar nas cobranças do app.',
          icon: FxIcons.pix,
        ),
        FxHelpTip(
          'Trocar',
          'Trocar a chave pede o Face ID ou o código do aparelho, e você recebe um e-mail avisando.',
          icon: FxIcons.concluido,
        ),
      ],
    );
  }

  /// Troca de chave existente: mostra o valor novo e pede o aparelho.
  Future<bool> _confirmarTroca(String novoTipo, String novaChave) async {
    final ok = await showFxConfirmSheet(
      context,
      title: walletTrocarConfirmTitle(),
      message: walletTrocarConfirmMessage(
        walletRotuloMascarado(novoTipo, novaChave),
      ),
      confirmLabel: walletTrocarConfirmLabel(),
      cancelLabel: 'Voltar',
    );
    if (!ok || !mounted) return false;
    return ref
        .read(confirmarNoAparelhoProvider)
        .confirmar(walletTrocarMotivoAparelho());
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
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final tipo = _tipoChavePix!;
    final chave = WalletPixValidation.normalizeForApi(tipo, _chavePixCtrl.text);
    final trocando =
        _temChaveSalva &&
        chave !=
            WalletPixValidation.normalizeForApi(_snapshotTipo, _snapshotChave);
    if (trocando && !await _confirmarTroca(tipo, chave)) return;
    if (!mounted) return;

    setState(() => _carregando = true);
    try {
      await ref.read(perfilRepositoryProvider).atualizarWallet({
        'chavePix': chave,
        'tipoChavePix': tipo,
      });
      ref.invalidate(perfilProvider);
      ref.invalidate(perfilWalletProvider);
      if (mounted) {
        _editandoChave = false;
        _captureSnapshot();
        FeedbackHelper.showSuccess(context, 'Chave PIX salva.');
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
    FeedbackHelper.showSuccess(context, walletChaveCopiada());
  }

  void _definirTipo(String selected) {
    if (selected == _tipoChavePix) return;
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

  void _cancelarEdicao() {
    setState(() {
      _editandoChave = false;
      _tipoChavePix = _snapshotTipo;
      _chavePixCtrl.text = _snapshotChave;
    });
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilWalletProvider);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final features = ref.watch(planoFeaturesProvider).value;
    final hasFinanceiro = features?.financeiro == true;

    if (features == null || !hasFinanceiro) {
      return const FeatureGate(
        featureName: 'Financeiro',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'financeiro',
        child: SizedBox.shrink(),
      );
    }

    final showSticky =
        !perfilAsync.isLoading && !perfilAsync.hasError && _hasUnsavedChanges;

    return fxScreenA11yScope(
      label: 'Carteira e PIX',
      child: FxFormPopGuard(
        dirty: _hasUnsavedChanges,
        onCancel: _handleBack,
        child: FxShellScaffold(
          comFundo: true,
          appBar: FxShellAppBar(
            title: 'Carteira e PIX',
            onBack: _handleBack,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar a carteira',
                onTap: _showHelp,
              ),
            ],
          ),
          bottomNavigationBar:
              showSticky
                  ? FxFormStickyBar(
                    child: FxLiquidPrimaryButton(
                      label: walletSalvarTileLabel(),
                      loading: _carregando,
                      loadingLabel: 'Salvando…',
                      onPressed: _carregando ? null : _salvar,
                    ),
                  )
                  : null,
          body: perfilAsync.when(
            loading: () => const SkeletonList(count: 3),
            error:
                (e, _) => FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: friendlyError(e),
                  onRetry: () => ref.invalidate(perfilWalletProvider),
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
                    ref.invalidate(perfilWalletProvider);
                  },
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s4,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s4,
                    ),
                    children: [
                      FxContentWidthLimiter(
                        child: _WalletChave(
                          tipoChavePix: _tipoChavePix,
                          chavePixCtrl: _chavePixCtrl,
                          carregando: _carregando,
                          tipoSalvo: _snapshotTipo,
                          chaveSalva: _snapshotChave,
                          editando: _editandoChave || !_temChaveSalva,
                          podeCancelar: _editandoChave && _temChaveSalva,
                          onEditarChave:
                              () => setState(() => _editandoChave = true),
                          onCancelar: _cancelarEdicao,
                          onSelecionarTipo: _definirTipo,
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
      ),
    );
  }
}
