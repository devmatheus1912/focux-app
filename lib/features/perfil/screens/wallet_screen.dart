import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

/// Tela de configuração de dados de pagamento (Wallet / PIX).
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

  static const List<String> _tiposChavePix = [
    'CPF',
    'CNPJ',
    'EMAIL',
    'TELEFONE',
    'ALEATORIA',
  ];

  @override
  void dispose() {
    _chavePixCtrl.dispose();
    _bancoCtrl.dispose();
    _agenciaCtrl.dispose();
    _contaCtrl.dispose();
    super.dispose();
  }

  void _preencherDadosAtuais(PerfilPersonal perfil) {
    if (_inicializado) return;
    _inicializado = true;
    _chavePixCtrl.text = perfil.chavePix ?? '';
    _tipoChavePix = perfil.tipoChavePix;
    _bancoCtrl.text = perfil.banco ?? '';
    _agenciaCtrl.text = perfil.agencia ?? '';
    _contaCtrl.text = perfil.conta ?? '';
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _carregando = true);
    try {
      final repo = ref.read(perfilRepositoryProvider);
      await repo.atualizarWallet({
        if (_chavePixCtrl.text.isNotEmpty)
          'chavePix': _chavePixCtrl.text.trim(),
        if (_tipoChavePix != null) 'tipoChavePix': _tipoChavePix,
        if (_bancoCtrl.text.isNotEmpty) 'banco': _bancoCtrl.text.trim(),
        if (_agenciaCtrl.text.isNotEmpty) 'agencia': _agenciaCtrl.text.trim(),
        if (_contaCtrl.text.isNotEmpty) 'conta': _contaCtrl.text.trim(),
      });
      // Invalida o cache do perfil para refletir os novos dados
      ref.invalidate(perfilProvider);
      if (mounted) {
        FeedbackHelper.showSnackBar(
          context,
          const SnackBar(
            content: Text('Dados de pagamento salvos com sucesso!'),
          ),
        );
        context.pop(true);
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

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: FxShellAppBar(
        title: 'Wallet / Pagamentos',
        onBack: () => context.pop(),
      ),
      body: perfilAsync.when(
        loading: () => const FxLoading(),
        error: (e, _) => Center(child: Text(friendlyError(e))),
        data: (perfil) {
          _preencherDadosAtuais(perfil);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabeçalho informativo
                  Container(
                    padding: const EdgeInsets.all(TokensStrip.s3),
                    decoration: fxListCardDecoration(context),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: TokensStrip.s2),
                        Expanded(
                          child: Text(
                            'Configure suas chaves PIX e dados bancários para receber pagamentos dos alunos.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Resumo financeiro (FN1)
                  const _ResumoMensalCard(),
                  const SizedBox(height: 20),

                  // Seção PIX
                  Text(
                    'Dados PIX',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _tipoChavePix,
                    decoration: InputDecoration(
                      labelText: 'Tipo de chave PIX',
                      border: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(TokensStrip.rInput),
                      ),
                    ),
                    items:
                        _tiposChavePix
                            .map(
                              (tipo) => DropdownMenuItem(
                                value: tipo,
                                child: Text(_labelTipoChave(tipo)),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _tipoChavePix = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _chavePixCtrl,
                    decoration: InputDecoration(
                      labelText: 'Chave PIX',
                      hintText: 'CPF, e-mail, telefone ou chave aleatória',
                      border: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(TokensStrip.rInput),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Seção bancária
                  Text(
                    'Dados Bancários',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bancoCtrl,
                    decoration: InputDecoration(
                      labelText: 'Banco',
                      hintText: 'Ex.: Nubank, Itaú, Bradesco',
                      border: FxInputDeco.outlineBorder(
                        borderRadius: BorderRadius.circular(TokensStrip.rInput),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _agenciaCtrl,
                          decoration: InputDecoration(
                            labelText: 'Agência',
                            border: FxInputDeco.outlineBorder(
                              borderRadius: BorderRadius.circular(TokensStrip.rInput),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _contaCtrl,
                          decoration: InputDecoration(
                            labelText: 'Conta',
                            border: FxInputDeco.outlineBorder(
                              borderRadius: BorderRadius.circular(TokensStrip.rInput),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Botão salvar
                  FxLiquidPrimaryButton(
                    label: 'Salvar dados',
                    icon: Icons.save_rounded,
                    loading: _carregando,
                    onPressed: _carregando ? null : _salvar,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _labelTipoChave(String tipo) {
    return switch (tipo) {
      'CPF' => 'CPF',
      'CNPJ' => 'CNPJ',
      'EMAIL' => 'E-mail',
      'TELEFONE' => 'Telefone',
      'ALEATORIA' => 'Chave aleatória',
      _ => tipo,
    };
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final now = DateTime.now();
      final repo = FinanceiroRepository(ref.read(apiClientProvider));
      final res = await repo.resumoMensal(now.year, now.month);
      if (mounted) {
        setState(() {
          _resumo = res;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const FxLoading();
    if (_resumo == null) return const SizedBox.shrink();
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: TokensStrip.s2),
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo do Mês',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Stat(
                  label: 'Recebido',
                  valor: 'R\$ ${_resumo!.totalRecebido.toStringAsFixed(2)}',
                  color: EagleTokens.good,
                ),
                _Stat(
                  label: 'Previsto',
                  valor: 'R\$ ${_resumo!.totalPrevisto.toStringAsFixed(2)}',
                  color: primary,
                ),
                _Stat(
                  label: 'Inadimplentes',
                  valor: '${_resumo!.inadimplentes}',
                  color: EagleTokens.bad,
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, valor;
  final Color color;
  const _Stat({required this.label, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: EagleTokens.inkMute),
        ),
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
