import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/landing_tracking.dart';
import '../models/public_personal_data.dart';
import 'landing_design_helpers.dart';

class CtaFinalSection extends StatelessWidget {
  final PublicPersonalData data;
  final String slug;
  final Color primaryColor;

  const CtaFinalSection({
    super.key,
    required this.data,
    required this.slug,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final packages = LandingDesign.packages(data);
    final featuredPackage =
        packages.isNotEmpty
            ? packages[LandingDesign.featuredIndex(
              data.featuredPackageIndex,
              packages.length,
            )]
            : null;
    final accent =
        data.isEnterprise
            ? primaryColor
            : Theme.of(context).colorScheme.primary;
    final firstName = LandingDesign.firstName(data);
    final price =
        featuredPackage == null
            ? 'uma avaliacao'
            : LandingDesign.formatPrice(featuredPackage.preco);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, const Color(0xFF050814), 0.36)!],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            featuredPackage != null
                ? 'Comece com $price em um plano com direcao.'
                : 'Converse com $firstName e entenda o melhor caminho.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Cadastro simples. Acompanhamento organizado. Proximo passo claro.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final path = landingRegisterPath(
                  slug,
                  data.trackingId,
                  source: 'landing_cta',
                );
                trackLandingEvent(
                  slug: slug,
                  eventType: 'landing_cta_click',
                  source: 'landing_cta',
                  trackingId: data.trackingId,
                  path: path,
                );
                context.go(path);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                LandingDesign.finalCta(data),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
