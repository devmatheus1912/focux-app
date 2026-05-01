import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/landing_tracking.dart';
import '../models/public_personal_data.dart';
import 'landing_design_helpers.dart';

class OfertasSection extends StatelessWidget {
  final PublicPersonalData data;
  final String slug;
  final Color primaryColor;

  const OfertasSection({
    super.key,
    required this.data,
    required this.slug,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final services = LandingDesign.services(data);
    final packages = LandingDesign.packages(data);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 760;
        final horizontalPadding = wide ? 112.0 : 32.0;
        final contentWidth =
            (constraints.maxWidth - horizontalPadding)
                .clamp(0.0, 1100.0)
                .toDouble();
        final serviceWidth = wide ? (contentWidth - 24) / 3 : contentWidth;

        return Container(
          padding: EdgeInsets.fromLTRB(wide ? 56 : 16, 30, wide ? 56 : 16, 32),
          color: const Color(0xFF0A0F1E),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (services.isNotEmpty) ...[
                    _SectionEyebrow('SERVICOS', color: primaryColor),
                    const SizedBox(height: 8),
                    const Text(
                      'O aluno precisa entender exatamente o que esta comprando.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final servico in services)
                          SizedBox(
                            width: serviceWidth,
                            child: _ServiceTile(
                              title: servico.titulo,
                              description: servico.descricao,
                              primaryColor: primaryColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (packages.isNotEmpty) ...[
                    _SectionEyebrow('PLANOS E VALORES', color: primaryColor),
                    const SizedBox(height: 8),
                    const Text(
                      'Escolha o nivel de acompanhamento e comece com clareza.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (var i = 0; i < packages.length; i++)
                          SizedBox(
                            width: serviceWidth,
                            child: _PackageTile(
                              pacote: packages[i],
                              featured: i == 0,
                              primaryColor: primaryColor,
                              onTap: () {
                                final path = landingRegisterPath(
                                  slug,
                                  data.trackingId,
                                  source: 'landing_offer',
                                );
                                trackLandingEvent(
                                  slug: slug,
                                  eventType: 'landing_cta_click',
                                  source: 'landing_offer',
                                  trackingId: data.trackingId,
                                  path: path,
                                );
                                context.go(path);
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionEyebrow(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final String title;
  final String description;
  final Color primaryColor;

  const _ServiceTile({
    required this.title,
    required this.description,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 130),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.check_circle, color: primaryColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  final PublicLandingPackageItem pacote;
  final bool featured;
  final Color primaryColor;
  final VoidCallback onTap;

  const _PackageTile({
    required this.pacote,
    required this.featured,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = LandingDesign.formatPrice(pacote.preco);
    final benefits = LandingDesign.packageBenefits(pacote);
    return Container(
      constraints: const BoxConstraints(minHeight: 310),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: featured ? const Color(0xFF121D31) : const Color(0xFF101827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              featured
                  ? primaryColor.withValues(alpha: 0.46)
                  : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow:
            featured
                ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.18),
                    blurRadius: 34,
                    offset: const Offset(0, 16),
                  ),
                ]
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featured) ...[
            Text(
              'MAIS PROCURADO',
              style: TextStyle(
                color: primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            pacote.nome,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            price,
            style: TextStyle(
              color: primaryColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (pacote.descricao.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              pacote.descricao,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          for (final benefit in benefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.done_rounded, color: primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: const TextStyle(
                        color: Color(0xFFE5E7EB),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: featured ? primaryColor : Colors.white,
                foregroundColor:
                    featured ? Colors.white : const Color(0xFF111827),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                pacote.cta.trim().isNotEmpty ? pacote.cta : 'Quero esse plano',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
