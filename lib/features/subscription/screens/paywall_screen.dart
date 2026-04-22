import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/subscription_plan.dart';
import '../providers/subscription_provider.dart';
import '../../../core/theme/design_tokens.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evolua seu Plano'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Escolha o plano ideal para alavancar sua consultoria',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildPlanCard(
            context,
            title: 'Plano PRO',
            price: 'R\\\$ 79,90 / mês',
            plan: SubscriptionPlan.PRO,
            features: [
              'Até 20 alunos ativos',
              'Gestão Financeira & Cobranças',
              'CRM e Kanban de Leads',
              'Migração Mágica por IA'
            ],
            color: EagleTokens.warn,
          ),
          const SizedBox(height: 16),
          _buildPlanCard(
            context,
            title: 'Plano PREMIUM',
            price: 'R\\\$ 149,90 / mês',
            plan: SubscriptionPlan.PREMIUM,
            features: [
              'Alunos Ilimitados',
              'IA Copiloto (Treinos Aut.)',
              'Landing Page (Link na Bio)',
              'Motor Anti-Churn & Prova Social'
            ],
            color: EagleTokens.brand,
            isPopular: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, {required String title, required String price, required SubscriptionPlan plan, required List<String> features, required Color color, bool isPopular = false}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: isPopular ? color : Colors.grey.shade300, width: isPopular ? 2 : 1),
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(14), bottomLeft: Radius.circular(14)),
                ),
                child: const Text('MAIS ESCOLHIDO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 8),
                Text(price, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: color, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f)),
                    ],
                  ),
                )),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<SubscriptionProvider>().upgradePlan(plan);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upgrade para $title realizado!')));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Assinar Agora', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
