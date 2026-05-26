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

class _WalletSectionCard extends StatelessWidget {
  const _WalletSectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Semantics(
      container: true,
      label: subtitle == null ? title : '$title. $subtitle',
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s4),
        decoration: fxListCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.inter(
                color: ink,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(color: mute, fontSize: 11.5, height: 1.35),
              ),
            ],
            const SizedBox(height: TokensStrip.s3),
            child,
          ],
        ),
      ),
    );
  }
}

class _PixTipoBottomSheet extends StatelessWidget {
  const _PixTipoBottomSheet({
    required this.tipos,
    required this.selected,
  });

  final List<String> tipos;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final surface = isDark ? EagleTokens.darkCard : TokensStrip.cardBg;

    return Padding(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 0, TokensStrip.s4, 16),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Material(
          color: surface,
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                  child: Row(
                    children: [
                      Icon(Icons.key_rounded, color: primary, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Tipo de chave PIX',
                        style: AppTypography.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                    ],
                  ),
                ),
                ...tipos.map(
                  (tipo) => ListTile(
                    title: Text(
                      WalletPixValidation.labelForTipo(tipo),
                      style: TextStyle(
                        color: ink,
                        fontWeight:
                            selected == tipo
                                ? FontWeight.w700
                                : FontWeight.w500,
                      ),
                    ),
                    trailing:
                        selected == tipo
                            ? Icon(Icons.check_circle_rounded, color: primary)
                            : null,
                    onTap: () => Navigator.pop(context, tipo),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumoMensalCard extends ConsumerStatefulWidget {
  const _ResumoMensalCard();

  @override
  ConsumerState<_ResumoMensalCard> createState() => _ResumoMensalCardState();
}

class _ResumoMensalCardState extends ConsumerState<_ResumoMensalCard> {
  ResumoMensal? _resumo;
  bool _loading = true;
  String? _error;
  late final DateTime _periodo = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = FinanceiroRepository(ref.read(apiClientProvider));
      final res = await repo.resumoMensal(_periodo.year, _periodo.month);
      if (mounted) {
        setState(() {
          _resumo = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _ResumoMensalSkeleton();
    if (_error != null) return _ResumoMensalError(message: _error!, onRetry: _load);
    if (_resumo == null) return const SizedBox.shrink();

    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final resumo = _resumo!;
    final inadimplentes = resumo.inadimplentes;
    final percentRecebido =
        resumo.totalPrevisto <= 0
            ? 0.0
            : (resumo.totalRecebido / resumo.totalPrevisto).clamp(0.0, 1.0);
    final periodoLabel = monthYearLabelPtBr(_periodo);

    return Semantics(
      button: true,
      label:
          'Resumo financeiro de $periodoLabel. '
          'Recebido ${formatBrlCurrency(resumo.totalRecebido)}. '
          'Previsto ${formatBrlCurrency(resumo.totalPrevisto)}. '
          '$inadimplentes inadimplentes.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          onTap: () => context.push('/financeiro'),
          child: Container(
            padding: const EdgeInsets.all(TokensStrip.s4),
            decoration: fxListCardDecoration(context, accent: primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Resumo · $periodoLabel',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: mute, size: 22),
                  ],
                ),
                const SizedBox(height: TokensStrip.s3),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Recebido',
                        valor: formatBrlCurrency(resumo.totalRecebido),
                        color: EagleTokens.good,
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Previsto',
                        valor: formatBrlCurrency(resumo.totalPrevisto),
                        color: primary,
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Inadimplentes',
                        valor: '$inadimplentes',
                        color:
                            inadimplentes > 0
                                ? EagleTokens.bad
                                : mute,
                      ),
                    ),
                  ],
                ),
                if (resumo.totalPrevisto > 0) ...[
                  const SizedBox(height: TokensStrip.s3),
                  Semantics(
                    label:
                        '${(percentRecebido * 100).round()} por cento do previsto recebido',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: percentRecebido,
                        minHeight: 6,
                        backgroundColor: line,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(percentRecebido * 100).round()}% do previsto recebido',
                    style: TextStyle(fontSize: 12, color: mute),
                  ),
                ],
                const SizedBox(height: TokensStrip.s2),
                Text(
                  'Ver financeiro completo',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: primary,
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

class _ResumoMensalSkeleton extends StatelessWidget {
  const _ResumoMensalSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(height: 16, width: 160, borderRadius: 8),
          SizedBox(height: TokensStrip.s3),
          Row(
            children: [
              Expanded(
                child: SkeletonLoader(height: 42, borderRadius: 10),
              ),
              SizedBox(width: TokensStrip.s3),
              Expanded(
                child: SkeletonLoader(height: 42, borderRadius: 10),
              ),
              SizedBox(width: TokensStrip.s3),
              Expanded(
                child: SkeletonLoader(height: 42, borderRadius: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResumoMensalError extends StatelessWidget {
  const _ResumoMensalError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final mute = Theme.of(context).brightness == Brightness.dark
        ? EagleTokens.darkInkMute
        : TokensStrip.textSecondary;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo do mês',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: mute, height: 1.4)),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;

  const _Stat({
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: TokensStrip.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            valor,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
