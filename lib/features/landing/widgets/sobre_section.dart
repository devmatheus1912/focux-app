import 'package:flutter/material.dart';
import '../models/public_personal_data.dart';
import 'landing_design_helpers.dart';

class SobreSection extends StatelessWidget {
  final PublicPersonalData data;
  const SobreSection({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final portrait = LandingDesign.bioImageUrl(data);
    final aboutCopy = LandingDesign.aboutCopy(data);
    final specialty = LandingDesign.primarySpecialty(data);
    final years = LandingDesign.yearsExperience(data);
    final badgeValue = years >= 2 ? '$years+' : 'APP';
    final badgeLabel = years >= 2 ? 'ANOS' : 'GUIADO';

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 780;
        final horizontalPadding = wide ? 56.0 : 16.0;
        final contentWidth =
            (constraints.maxWidth - horizontalPadding * 2)
                .clamp(0.0, 1100.0)
                .toDouble();
        final mediaWidth =
            wide ? (contentWidth * 0.42).clamp(320.0, 460.0) : contentWidth;
        final copyWidth = wide ? contentWidth - mediaWidth - 54 : contentWidth;

        return Container(
          color: const Color(0xFF070B16),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            wide ? 56 : 34,
            horizontalPadding,
            wide ? 62 : 34,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Wrap(
                spacing: 54,
                runSpacing: 28,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: mediaWidth,
                    child: _SobreMediaCard(
                      imageUrl: portrait,
                      accent: accent,
                      badgeValue: badgeValue,
                      badgeLabel: badgeLabel,
                    ),
                  ),
                  SizedBox(
                    width: copyWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SOBRE O PERSONAL',
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          specialty == null
                              ? 'Metodo, presenca e clareza antes do aluno decidir.'
                              : 'Especialista em $specialty com rotina que o aluno entende.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          aboutCopy,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 15,
                            height: 1.75,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Column(
                          children: [
                            _CredentialRow(
                              icon:
                                  LandingDesign.showStudentCount(data)
                                      ? Icons.people_outline
                                      : Icons.groups_2_outlined,
                              title:
                                  LandingDesign.showStudentCount(data)
                                      ? '${data.totalAlunos}+ alunos'
                                      : 'Acompanhamento proximo',
                              subtitle:
                                  LandingDesign.showStudentCount(data)
                                      ? 'Historico de acompanhamento real'
                                      : 'Menos aluno perdido, mais direcao individual',
                              color: accent,
                            ),
                            if (LandingDesign.validCref(data) != null)
                              _CredentialRow(
                                icon: Icons.verified_outlined,
                                title: 'CREF ativo',
                                subtitle: LandingDesign.validCref(data)!,
                                color: accent,
                              ),
                            if (specialty != null)
                              _CredentialRow(
                                icon: Icons.bolt_outlined,
                                title: specialty,
                                subtitle: 'Especialidade em destaque',
                                color: accent,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SobreMediaCard extends StatelessWidget {
  final String? imageUrl;
  final Color accent;
  final String badgeValue;
  final String badgeLabel;

  const _SobreMediaCard({
    required this.imageUrl,
    required this.accent,
    required this.badgeValue,
    required this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
    return AspectRatio(
      aspectRatio: 0.82,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  hasImage
                      ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => _MediaFallback(accent: accent),
                      )
                      : _MediaFallback(accent: accent),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF050814).withValues(alpha: 0.58),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
            ),
          ),
          Positioned(
            right: -14,
            top: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.34),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    badgeValue,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    badgeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaFallback extends StatelessWidget {
  final Color accent;

  const _MediaFallback({required this.accent});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(accent, const Color(0xFF050814), 0.62)!,
            const Color(0xFF111827),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.photo_camera_back_outlined,
          color: Colors.white.withValues(alpha: 0.62),
          size: 58,
        ),
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _CredentialRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF101827),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
