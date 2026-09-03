import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/clipboard_sensitive.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
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
    if (!_hasUnsavedChanges) {
      if (mounted) context.pop();
      return;
    }
    final discard = await _confirmDiscard();
    if (discard && mounted) context.pop();
  }

  Future<void> _salvar() async {
    final tipoErro = WalletPixValidation.validateTipo(_tipoChavePix);
    if (tipoErro != null) {
      FeedbackHelper.showError(context, tipoErro);
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

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: fxScreenA11yScope(
        label: 'Carteira e PIX',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Carteira e PIX',
            subtitle: 'RECEBIMENTOS',
            onBack: _handleBack,
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                TokensStrip.s2,
                FxSettingsLayout.pageInset,
                TokensStrip.s3,
              ),
              child: FxLiquidPrimaryButton(
                label: walletSalvarTileLabel(),
                loading: _carregando,
                loadingLabel: 'Salvando…',
                onPressed: _carregando ? null : _salvar,
              ),
            ),
          ),
          body: perfilAsync.when(
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
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    8,
                    FxSettingsLayout.pageInset,
                    32,
                  ),
                  children: [
                    const _ResumoMensalCard(),
                    const SizedBox(height: TokensStrip.s3),
                    FxSettingsGroup(
                      header: 'Dados PIX',
                      caption:
                          'Configure PIX e dados bancários para receber dos alunos.',
                      children: [
                        FxSettingsTile(
                          fxIcon: 'coin',
                          label: 'Tipo de chave',
                          value:
                              _tipoChavePix == null
                                  ? 'Selecionar'
                                  : WalletPixValidation.labelForTipo(
                                    _tipoChavePix!,
                                  ),
                          picker: true,
                          onTap: _carregando ? null : _selecionarTipoPix,
                        ),
                        AlunoInsetFormField(
                          controller: _chavePixCtrl,
                          label: 'Chave PIX',
                          icon: Icons.pix_rounded,
                          hint: WalletPixValidation.hintForTipo(_tipoChavePix),
                          keyboardType: WalletPixValidation.keyboardForTipo(
                            _tipoChavePix,
                          ),
                          inputFormatters: [
                            ...WalletPixValidation.formattersForTipo(
                              _tipoChavePix,
                            ),
                            LengthLimitingTextInputFormatter(walletChavePixMax),
                          ],
                          validator:
                              (v) => WalletPixValidation.validateChave(
                                _tipoChavePix,
                                v ?? '',
                              ),
                          showDivider: false,
                        ),
                        if (_chavePixCtrl.text.trim().isNotEmpty)
                          TextButton(
                            onPressed: _carregando ? null : _copiarChavePix,
                            child: Text(walletCopiarTileLabel()),
                          ),
                      ],
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    FxSettingsGroup(
                      header: 'Dados bancários',
                      caption:
                          'Opcional — complementa o PIX para transferências.',
                      children: [
                        AlunoInsetFormField(
                          controller: _bancoCtrl,
                          label: 'Banco',
                          icon: Icons.account_balance_outlined,
                          hint: 'Ex.: Nubank, Itaú, Bradesco',
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(walletBancoMax),
                          ],
                        ),
                        AlunoInsetFormField(
                          controller: _agenciaCtrl,
                          label: 'Agência',
                          icon: Icons.tag_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(walletAgenciaMax),
                          ],
                        ),
                        AlunoInsetFormField(
                          controller: _contaCtrl,
                          label: 'Conta',
                          icon: Icons.numbers_rounded,
                          keyboardType: TextInputType.text,
                          inputFormatters:
                              WalletPixValidation.formattersForConta(),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
