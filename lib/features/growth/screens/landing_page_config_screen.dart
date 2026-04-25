import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LandingPageConfigScreen extends ConsumerWidget {
  const LandingPageConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? EagleTokens.darkBg : EagleTokens.paper;
    final cardBg = dark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = dark ? EagleTokens.brandAccent : EagleTokens.brand;

    final configs = [
      {'icon': Icons.monetization_on_outlined, 'label': 'Link de pagamento', 'value': 'MercadoPago conectado', 'badge': null},
      {'icon': Icons.people_outline, 'label': 'Depoimentos', 'value': '3 em destaque', 'badge': null},
      {'icon': Icons.trending_up, 'label': 'Prova social', 'value': 'Ativada', 'badge': '● LIVE'},
      {'icon': Icons.auto_awesome, 'label': 'Cor da marca', 'value': '#3B5FE2 · Azul royal', 'badge': null},
      {'icon': Icons.calendar_today_outlined, 'label': 'Formulário de contato', 'value': 'WhatsApp direto', 'badge': null},
    ];

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 54),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ENTERPRISE', style: TextStyle(color: brand, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
              const SizedBox(height: 6),
              Text('Seu link na bio 🚀', style: TextStyle(color: ink, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text('Sua landing page personalizada. Coloque no Instagram e converta visitantes em alunos.', style: TextStyle(color: mute, fontSize: 14, height: 1.55)),
            ]),
          ),

          // Live link card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: dark ? const Color(0x148DA4E2) : EagleTokens.brandSofter,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: dark ? const Color(0x338DA4E2) : const Color(0x333B5FE2), width: 1.5),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: dark ? const Color(0x268DA4E2) : EagleTokens.brandSoft, borderRadius: BorderRadius.circular(11)),
                    child: Icon(Icons.trending_up, color: brand, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('● ATIVA', style: TextStyle(color: const Color(0xFF2BB673), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    Text('Sua Landing Page está no ar!', style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w700)),
                  ]),
                ]),
                const SizedBox(height: 14),

                // link row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: line)),
                  child: Row(children: [
                    Expanded(child: Text('focux.app/p/matheus-personal', style: TextStyle(color: brand, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w600))),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(const ClipboardData(text: 'https://focux.app/p/matheus-personal'));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copiado!')));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: dark ? const Color(0x268DA4E2) : EagleTokens.brandSoft, borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          Icon(Icons.copy, color: brand, size: 11),
                          const SizedBox(width: 4),
                          Text('Copiar', style: TextStyle(color: brand, fontSize: 11, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),

                // stats
                Row(children: [
                  Expanded(child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: line)),
                    child: Column(children: [
                      Text('284', style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Visitas', style: TextStyle(color: mute, fontSize: 10.5)),
                    ]),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: line)),
                    child: Column(children: [
                      Text('47', style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Cliques', style: TextStyle(color: mute, fontSize: 10.5)),
                    ]),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: line)),
                    child: Column(children: [
                      Text('16,5%', style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Conversão', style: TextStyle(color: mute, fontSize: 10.5)),
                    ]),
                  )),
                ]),
              ]),
            ),
          ),

          // Configurações
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text('Configurações', style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.5)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: configs.map((c) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: line)),
                child: Row(children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(color: dark ? const Color(0x1E8DA4E2) : EagleTokens.brandSoft, borderRadius: BorderRadius.circular(10)),
                    child: Icon(c['icon'] as IconData, color: brand, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c['label'] as String, style: TextStyle(color: ink, fontSize: 13.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 1),
                    Text(c['value'] as String, style: TextStyle(color: mute, fontSize: 11.5)),
                  ])),
                  if (c['badge'] != null) ...[
                    Text(c['badge'] as String, style: const TextStyle(color: Color(0xFF2BB673), fontSize: 10, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                  ],
                  Icon(Icons.chevron_right, color: mute, size: 18),
                ]),
              );
            }).toList()),
          ),

          // Compartilhar button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: brand,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: brand.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.share, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Text('Compartilhar landing page', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
