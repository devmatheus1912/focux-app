import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../models/public_personal_data.dart';
import '../widgets/hero_section.dart';
import '../widgets/social_proof_section.dart';
import '../widgets/sobre_section.dart';
import '../widgets/especialidades_section.dart';
import '../widgets/depoimentos_section.dart';
import '../widgets/galeria_section.dart';
import '../widgets/contato_section.dart';
import '../widgets/cta_final_section.dart';
import '../widgets/powered_by_footer.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _publicPersonalProvider =
    FutureProvider.autoDispose.family<PublicPersonalData, String>((ref, slug) async {
  // Public endpoint — no auth needed. Use raw http.
  const baseUrl = 'https://focux-backend.onrender.com';
  final response = await http.get(Uri.parse('$baseUrl/api/public/personal/$slug'));
  if (response.statusCode == 403 || response.statusCode == 404) {
    throw Exception('NOT_AVAILABLE');
  }
  if (response.statusCode != 200) {
    throw Exception('Error ${response.statusCode}');
  }
  return PublicPersonalData.fromJson(
    jsonDecode(response.body) as Map<String, dynamic>,
  );
});

// ---------------------------------------------------------------------------
// Color helper
// ---------------------------------------------------------------------------

Color _hexColor(String? hex, Color fallback) {
  if (hex == null) return fallback;
  final clean = hex.replaceFirst('#', '');
  if (clean.length != 6) return fallback;
  return Color(int.parse('FF$clean', radix: 16));
}

// ---------------------------------------------------------------------------
// Main widget
// ---------------------------------------------------------------------------

class PersonalPublicLandingScreen extends ConsumerWidget {
  final String slug;
  const PersonalPublicLandingScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_publicPersonalProvider(slug));

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _NotAvailableView(slug: slug),
        data: (data) => _LandingContent(slug: slug, data: data),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _NotAvailableView
// ---------------------------------------------------------------------------

class _NotAvailableView extends StatelessWidget {
  final String slug;
  const _NotAvailableView({required this.slug});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B3E), Color(0xFF0A0F1E)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fitness_center, color: Color(0xFF3B5FE2), size: 64),
              const SizedBox(height: 24),
              const Text(
                'Focux Personal',
                style: TextStyle(
                    color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Esta página não está disponível.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B5FE2),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Baixar o app Focux Personal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LandingContent
// ---------------------------------------------------------------------------

class _LandingContent extends StatelessWidget {
  final String slug;
  final PublicPersonalData data;
  const _LandingContent({required this.slug, required this.data});

  @override
  Widget build(BuildContext context) {
    final primaryColor = _hexColor(data.corPrimaria, const Color(0xFF3B5FE2));
    final secondaryColor = _hexColor(data.corSecundaria, const Color(0xFF0097A7));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: HeroSection(data: data, slug: slug, primaryColor: primaryColor, secondaryColor: secondaryColor)),
        SliverToBoxAdapter(child: SocialProofSection(data: data)),
        SliverToBoxAdapter(child: SobreSection(data: data)),
        SliverToBoxAdapter(child: EspecialidadesSection(data: data, primaryColor: primaryColor)),
        SliverToBoxAdapter(child: ContatoSection(data: data)),
        SliverToBoxAdapter(child: DepoimentosSection(data: data, primaryColor: primaryColor)),
        SliverToBoxAdapter(child: GaleriaSection(data: data)),
        SliverToBoxAdapter(child: CtaFinalSection(data: data, slug: slug, primaryColor: primaryColor)),
        SliverToBoxAdapter(child: PoweredByFooter(data: data)),
      ],
    );
  }
}

