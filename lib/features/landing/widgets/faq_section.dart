import 'package:flutter/material.dart';
import '../models/public_personal_data.dart';
import 'landing_design_helpers.dart';

class FaqSection extends StatelessWidget {
  final PublicPersonalData data;
  final Color primaryColor;

  const FaqSection({super.key, required this.data, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final items = LandingDesign.faq(data);

    return Container(
      color: const Color(0xFF0A1014),
      padding: const EdgeInsets.fromLTRB(16, 34, 16, 34),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PERGUNTAS FREQUENTES',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Duvidas principais antes de comecar.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 16),
              for (final item in items)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1419),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      splashColor: primaryColor.withValues(alpha: 0.08),
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      iconColor: primaryColor,
                      collapsedIconColor: Colors.white54,
                      title: Text(
                        item.pergunta,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item.resposta,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
