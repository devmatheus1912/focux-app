import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

import '../../../core/legal/focux_legal.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../planos/paywall/paywall_catalog.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/store_subscription_policy.dart';
import '../../subscription/subscription_products.dart';

/// Revisão honesta antes da compra na loja (App Store / Play compliant).
class AssinaturaReviewScreen extends StatefulWidget {
  final SubscriptionPlan plan;
  final SubscriptionBillingPeriod billingPeriod;
  final String priceDisplay;
  final String? trialNote;

  const AssinaturaReviewScreen({
    super.key,
    required this.plan,
    required this.billingPeriod,
    required this.priceDisplay,
    this.trialNote,
  });

  @override
  State<AssinaturaReviewScreen> createState() => _AssinaturaReviewScreenState();
}

class _AssinaturaReviewScreenState extends State<AssinaturaReviewScreen> {
  @override
  void initState() {
    super.initState();
    _enableSecureScreen();
  }

  @override
  void dispose() {
    _disableSecureScreen();
    super.dispose();
  }

  Future<void> _enableSecureScreen() async {
    if (kIsWeb) return;
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }

  Future<void> _disableSecureScreen() async {
    if (kIsWeb) return;
    try {
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final accent = PaywallCatalog.accentForPlan(widget.plan);
    final freq =
        widget.billingPeriod == SubscriptionBillingPeriod.yearly ? 'Anual' : 'Mensal';
    final nextBill = DateTime.now().add(
      Duration(
        days: widget.billingPeriod == SubscriptionBillingPeriod.yearly ? 365 : 30,
      ),
    );
    final nextLabel =
        '${nextBill.day.toString().padLeft(2, '0')}/'
        '${nextBill.month.toString().padLeft(2, '0')}/'
        '${nextBill.year}';

    return FxShellScaffold(
      appBar: FxShellAppBar(
        title: 'Confirmar assinatura',
        onBack: () => Navigator.of(context).pop(false),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
              color: accent.withValues(alpha: 0.08),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.plan.apiName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(widget.priceDisplay, style: TokensStrip.h1(color: ink).copyWith(fontSize: 28)),
                const SizedBox(height: 6),
                Text('Cobrança $freq · renovação automática', style: TokensStrip.bodyMuted(color: mute)),
                const SizedBox(height: 4),
                Text('Próxima cobrança estimada: $nextLabel', style: TokensStrip.bodyMuted(color: mute)),
                if (widget.trialNote != null) ...[
                  const SizedBox(height: 10),
                  Text(widget.trialNote!, style: TokensStrip.body(color: ink)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Incluído no plano', style: TokensStrip.h2(color: ink).copyWith(fontSize: 17)),
          const SizedBox(height: 10),
          ..._topFeatures(widget.plan).map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: accent),
                  const SizedBox(width: 10),
                  Expanded(child: Text(f, style: TokensStrip.body(color: ink))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _legalBody(widget.priceDisplay, freq),
            style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              TextButton(onPressed: () => FocuxLegal.openPrivacy(), child: const Text('Privacidade')),
              TextButton(onPressed: () => FocuxLegal.openTerms(), child: const Text('Termos')),
            ],
          ),
          const SizedBox(height: 24),
          Semantics(
            button: true,
            label: 'Confirmar e assinar plano ${widget.plan.apiName}',
            child: FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: const Color(0xFF081012),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Confirmar e assinar', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Voltar', style: TextStyle(color: mute, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static List<String> _topFeatures(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.ENTERPRISE_PRO => [
      'Landing page completa com depoimentos e FAQ',
      'White-label e domínio customizado',
      'Alunos ilimitados + IA ampliada',
    ],
    SubscriptionPlan.ENTERPRISE => [
      'Alunos ilimitados',
      'White-label e identidade visual',
      'IA Copiloto com cota ampliada',
      'Financeiro, CRM e relatórios',
    ],
    SubscriptionPlan.PREMIUM => [
      'Até 20 alunos ativos',
      'PIX e financeiro no app',
      'IA Copiloto e Command Center',
      'Agenda e relatórios avançados',
    ],
    _ => ['Recursos do plano selecionado'],
  };

  static String _legalBody(String price, String freq) {
    final channel = subscriptionChannelLabel();
    return 'Ao confirmar, você autoriza a cobrança de $price na forma de pagamento '
        'da $channel. A assinatura renova automaticamente ($freq) até ser cancelada. '
        'Cancele quando quiser em Ajustes > Assinaturas.\n\n'
        'Base legal (LGPD): execução de contrato para processar pagamento e entregar o serviço. '
        'Dados de pagamento são processados pela $channel — a Focux não armazena número de cartão.';
  }
}
