import '../../../core/widgets/feature_gate.dart';
import '../../subscription/models/subscription_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/feedback_helper.dart';

class LandingPageConfigScreen extends StatelessWidget {
  const LandingPageConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      featureName: "Landing Page Automática",
      requiredPlan: SubscriptionPlan.PREMIUM,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    const String publicLink = 'https://focux.app/p/marcos-personal';

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,title: const Text('Seu Link na Bio 🚀')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: EagleTokens.brand.withAlpha(50), width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.public, size: 48, color: EagleTokens.brand),
                  const SizedBox(height: 16),
                  const Text(
                    'Sua Landing Page está Ativa!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Coloque este link no seu Instagram para vender consultorias no piloto automático. Os alunos pagam e caem direto no seu Kanban de Leads.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: EagleTokens.inkMute),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: EagleTokens.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(publicLink, style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                        IconButton(
                          icon: const Icon(Icons.copy, color: EagleTokens.brand),
                          onPressed: () {
                            Clipboard.setData(const ClipboardData(text: publicLink));
                            FeedbackHelper.showSuccess(context, 'Link copiado para a área de transferência!');
                          },
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Configurações de Conversão', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.attach_money, color: EagleTokens.good),
              title: const Text('Link do MercadoPago'),
              subtitle: const Text('https://mpago.la/1a2b3c'),
              trailing: const Icon(Icons.edit),
              onTap: () {
                FeedbackHelper.showSuccess(context, 'Em breve: Edição de gateway de pagamento.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.format_quote, color: EagleTokens.warn),
              title: const Text('Depoimentos em Destaque'),
              subtitle: const Text('2 depoimentos selecionados'),
              trailing: const Icon(Icons.edit),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
