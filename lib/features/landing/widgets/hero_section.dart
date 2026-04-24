import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/public_personal_data.dart';

class HeroSection extends StatelessWidget {
  final PublicPersonalData data;
  final String slug;
  final Color primaryColor;
  final Color secondaryColor;
  
  const HeroSection({super.key, required this.data, required this.slug, required this.primaryColor, required this.secondaryColor});

  @override
  Widget build(BuildContext context) {
    final firstName = data.nomePersonal.split(' ').first;
    final heroGradient = data.isEnterprise
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, secondaryColor],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D1B3E), Color(0xFF1a2a5e)],
          );

    return Container(
      height: 380,
      decoration: BoxDecoration(gradient: heroGradient),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              backgroundImage: (data.isEnterprise && data.logoUrl != null)
                  ? NetworkImage(data.logoUrl!) as ImageProvider
                  : null,
              child: (data.isEnterprise && data.logoUrl != null)
                  ? null
                  : Text(
                      data.nomePersonal.isNotEmpty
                          ? data.nomePersonal[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w700),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              data.nomePersonal,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            if (data.isEnterprise &&
                data.slogan != null &&
                data.slogan!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  data.slogan!,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 15),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.go('/register/aluno?p=$slug');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: data.isEnterprise
                    ? primaryColor
                    : const Color(0xFF3B5FE2),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                elevation: 0,
              ),
              child: Text(
                'Quero treinar com $firstName →',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
            if (data.isEnterprise && data.videoUrl != null && data.videoUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  final uri = Uri.tryParse(data.videoUrl!);
                  if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.play_circle_outline, color: Colors.white70, size: 18),
                label: const Text('Ver vídeo de apresentação',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
