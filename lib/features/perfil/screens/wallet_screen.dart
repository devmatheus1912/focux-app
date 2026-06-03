import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
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
    for (final ctrl in [
      _chavePixCtrl,
      _bancoCtrl,
      _agenciaCtrl,
      _contaCtrl,
    ]) {
      ctrl.addListener(_onFormChanged);
    }
  }

  void _onFormChanged() {
    if (_inicializado) setState(() {});
  }

  @override
  void dispose() {
    for (final ctrl in [
      _chavePixCtrl,
      _bancoCtrl,
      _agenciaCtrl,
      _contaCtrl,
    ]) {
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

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TokensStrip.rCard),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Descartar alterações?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'Você alterou dados da carteira. Se sair agora, as mudanças não serão salvas.',
                  style: TextStyle(
                    height: 1.45,
                    color: Theme.of(ctx).brightness == Brightness.dark
                        ? EagleTokens.darkInkMute
                        : TokensStrip.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Continuar editando'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: EagleTokens.bad,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Descartar'),
                ),
              ],
            ),
          ),
        );
      },
    );
    return discard ?? false;
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
    if (WalletPixValidation.validateTipo(_tipoChavePix) != null) {
      setState(() {});
    }
    if (!_formKey.currentState!.validate()) return;

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
        FeedbackHelper.showSnackBar(
          context,
          const SnackBar(content: Text('Carteira atualizada com sucesso.')),
        );
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _copiarChavePix() async {
    final chave = _chavePixCtrl.text.trim();
    if (chave.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: chave));
    if (!mounted) return;
    FeedbackHelper.showSnackBar(
      context,
      const SnackBar(content: Text('Chave PIX copiada.')),
    );
  }

  Future<void> _selecionarTipoPix(FormFieldState<String> field) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PixTipoBottomSheet(
        tipos: _tiposChavePix,
        selected: _tipoChavePix,
      ),
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
    field.didChange(selected);
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Carteira e PIX',
        onBack: _handleBack,
      ),
      body: perfilAsync.when(
        loading: () => const FxLoading(),
        error: (e, _) => Center(child: Text(friendlyError(e))),
        data: (perfil) {
          _preencherDadosAtuais(perfil);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(TokensStrip.s4),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FxStaggerItem(
                    index: 0,
                    child: Semantics(
                    container: true,
                    label:
                        'Configure PIX e dados bancários para receber dos alunos.',
                    child: Container(
                      padding: const EdgeInsets.all(TokensStrip.s3),
                      decoration: fxListCardDecoration(context),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: primary,
                          ),
                          const SizedBox(width: TokensStrip.s2),
                          Expanded(
                            child: Text(
                              'Configure PIX e dados bancários para receber pagamentos dos alunos.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  const FxStaggerItem(
                    index: 1,
                    child: _ResumoMensalCard(),
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  FxStaggerItem(
                    index: 2,
                    child: _WalletSectionCard(
                    title: 'Dados PIX',
                    child: Column(
                      children: [
                        FormField<String>(
                          initialValue: _tipoChavePix,
                          validator: WalletPixValidation.validateTipo,
                          builder: (field) {
                            final tipoLabel =
                                _tipoChavePix == null
                                    ? 'Selecione o tipo'
                                    : WalletPixValidation.labelForTipo(
                                      _tipoChavePix!,
                                    );
                            return Semantics(
                              button: true,
                              label: 'Tipo de chave PIX, $tipoLabel',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  TokensStrip.rSm,
                                ),
                                onTap: () => _selecionarTipoPix(field),
                                child: InputDecorator(
                                  decoration: FxInputDeco.build(
                                    context,
                                    'Tipo de chave PIX',
                                    icon: Icons.key_rounded,
                                  ).copyWith(errorText: field.errorText),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tipoLabel,
                                          style: TextStyle(
                                            color:
                                                _tipoChavePix == null
                                                    ? TokensStrip.textSecondary
                                                    : Theme.of(
                                                      context,
                                                    ).colorScheme.onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.expand_more_rounded,
                                        color: TokensStrip.textSecondary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        Semantics(
                          label: 'Chave PIX',
                          child: TextFormField(
                            controller: _chavePixCtrl,
                            decoration: FxInputDeco.build(
                              context,
                              'Chave PIX',
                              icon: Icons.pix_rounded,
                              hint: WalletPixValidation.hintForTipo(
                                _tipoChavePix,
                              ),
                              suffix:
                                  _chavePixCtrl.text.trim().isNotEmpty
                                      ? IconButton(
                                        tooltip: 'Copiar chave PIX',
                                        icon: const Icon(
                                          Icons.copy_rounded,
                                          size: 20,
                                        ),
                                        onPressed: _copiarChavePix,
                                      )
                                      : null,
                            ),
                            keyboardType: WalletPixValidation.keyboardForTipo(
                              _tipoChavePix,
                            ),
                            inputFormatters:
                                WalletPixValidation.formattersForTipo(
                                  _tipoChavePix,
                                ),
                            validator:
                                (v) => WalletPixValidation.validateChave(
                                  _tipoChavePix,
                                  v ?? '',
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  FxStaggerItem(
                    index: 3,
                    child: _WalletSectionCard(
                    title: 'Dados bancários',
                    subtitle: 'Opcional — complementa o PIX para transferências.',
                    child: Column(
                      children: [
                        Semantics(
                          label: 'Banco',
                          child: TextFormField(
                            controller: _bancoCtrl,
                            decoration: FxInputDeco.build(
                              context,
                              'Banco',
                              icon: Icons.account_balance_outlined,
                              hint: 'Ex.: Nubank, Itaú, Bradesco',
                            ),
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final stacked = constraints.maxWidth < 360;
                            final agencia = Semantics(
                              label: 'Agência',
                              child: TextFormField(
                                controller: _agenciaCtrl,
                                decoration: FxInputDeco.build(
                                  context,
                                  'Agência',
                                  icon: Icons.tag_outlined,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                              ),
                            );
                            final conta = Semantics(
                              label: 'Conta',
                              child: TextFormField(
                                controller: _contaCtrl,
                                decoration: FxInputDeco.build(
                                  context,
                                  'Conta',
                                  icon: Icons.numbers_rounded,
                                ),
                                keyboardType: TextInputType.text,
                                inputFormatters:
                                    WalletPixValidation.formattersForConta(),
                              ),
                            );

                            if (stacked) {
                              return Column(
                                children: [
                                  agencia,
                                  const SizedBox(height: TokensStrip.s3),
                                  conta,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(flex: 2, child: agencia),
                                const SizedBox(width: TokensStrip.s3),
                                Expanded(flex: 3, child: conta),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  ),
                  const SizedBox(height: TokensStrip.s5),
                  FxStaggerItem(
                    index: 4,
                    child: FxLiquidPrimaryButton(
                    label: 'Salvar dados',
                    icon: Icons.save_rounded,
                    loading: _carregando,
                    onPressed: _carregando ? null : _salvar,
                  ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
    );
  }
}

