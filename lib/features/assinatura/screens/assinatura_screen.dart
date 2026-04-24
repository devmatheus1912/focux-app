import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../data/assinatura_repository.dart';
import '../providers/assinatura_provider.dart';

class AssinaturaScreen extends ConsumerWidget {
  const AssinaturaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planosAsync = ref.watch(planosProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,title: const Text('Planos')),
      body: planosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (planos) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: planos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _PlanoCard(plano: planos[i]),
        ),
      ),
    );
  }
}

class _PlanoCard extends ConsumerStatefulWidget {
  final Plano plano;

  const _PlanoCard({required this.plano});

  @override
  ConsumerState<_PlanoCard> createState() => _PlanoCardState();
}

class _PlanoCardState extends ConsumerState<_PlanoCard> {
  bool _loading = false;

  // IDs dos produtos criados na App Store / Google Play (Placeholder)
  String get _productId {
    if (widget.plano.nome.toLowerCase().contains('premium')) return 'focux_premium_monthly';
    return 'focux_pro_monthly';
  }

  Future<void> _assinar() async {
    if (widget.plano.precoMensal == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você já está no plano FREE.')),
      );
      return;
    }

    setState(() { _loading = true; });
    try {
      final bool available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A loja de aplicativos não está disponível neste dispositivo.')),
          );
        }
        return;
      }

      // Busca o produto na App Store / Google Play
      final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails({_productId});
      
      if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto ainda não configurado na loja. (Aguardando lançamento oficial da conta Apple)')),
          );
        }
        return;
      }

      final ProductDetails productDetails = response.productDetails.first;
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      
      // Inicia o fluxo nativo da Apple / Google
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao iniciar In-App Purchase: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final plano = widget.plano;
    final isGratis = plano.precoMensal == 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(plano.nome, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  isGratis ? 'Grátis' : 'R\$ ${plano.precoMensal.toStringAsFixed(2)}/mês',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _Feature(
              label: plano.limiteAlunos == null
                  ? 'Alunos ilimitados'
                  : 'Até ${plano.limiteAlunos} alunos',
              ativo: true,
            ),
            _Feature(label: 'White-label', ativo: plano.temWhiteLabel),
            _Feature(label: 'Financeiro', ativo: plano.temFinanceiro),
            _Feature(label: 'Agenda', ativo: plano.temAgenda),
            _Feature(label: 'Relatórios', ativo: plano.temRelatorios),
            const SizedBox(height: 12),
            if (!isGratis)
              FilledButton(
                onPressed: _loading ? null : _assinar,
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Assinar plano ${plano.nome}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final String label;
  final bool ativo;

  const _Feature({required this.label, required this.ativo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            ativo ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: ativo ? EagleTokens.good : EagleTokens.inkMute,
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: ativo ? null : EagleTokens.inkMute)),
        ],
      ),
    );
  }
}
