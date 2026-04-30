import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/public_personal_data.dart';

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
    final primeiroPacote = data.pacotes.isNotEmpty ? data.pacotes.first : null;
    final accent = data.isEnterprise ? primaryColor : Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            primeiroPacote != null && primeiroPacote.preco.trim().isNotEmpty
                ? 'Comece com ${primeiroPacote.preco}.\nConstrua sua rotina com suporte real.'
                : 'Comece hoje.\nSeu personal esta esperando.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.go(_registerPath(slug, data.trackingId));
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
              child: const Text(
                'Quero comecar agora',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _registerPath(String slug, String? trackingId) {
  final track = trackingId?.trim();
  final params = {
    'p': slug,
    'src': 'landing_cta',
    if (track != null && track.isNotEmpty) 'track': track,
  };
  return Uri(path: '/register/aluno', queryParameters: params).toString();
}
