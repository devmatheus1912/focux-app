import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/env.dart';
import '../models/public_personal_data.dart';
import '../widgets/hero_section.dart';
import '../widgets/metodo_section.dart';
import '../widgets/social_proof_section.dart';
import '../widgets/sobre_section.dart';
import '../widgets/especialidades_section.dart';
import '../widgets/depoimentos_section.dart';
import '../widgets/galeria_section.dart';
import '../widgets/contato_section.dart';
import '../widgets/cta_final_section.dart';
import '../widgets/ofertas_section.dart';
import '../widgets/powered_by_footer.dart';
import '../widgets/tecnologia_section.dart';
import '../widgets/faq_section.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final _publicPersonalProvider =
    FutureProvider.autoDispose.family<PublicPersonalData, String>((ref, slug) async {
  // Public endpoint — no auth needed. Use raw http.
  final baseUrl = Env.apiUrl;
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
// Store launcher
// ---------------------------------------------------------------------------

const String _kAndroidStoreUrl = 'https://play.google.com/store/apps/details?id=com.focux.personal';
const String _kIosStoreUrl = 'https://apps.apple.com/app/focux-personal/id0000000000';
const String _kFallbackUrl = 'https://focux.app/baixar';

Future<void> _abrirStore(BuildContext context) async {
  final platform = Theme.of(context).platform;
  final url = platform == TargetPlatform.iOS ? _kIosStoreUrl : _kAndroidStoreUrl;
  final uri = Uri.parse(url);
  bool ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok) {
    try {
      ok = await launchUrl(Uri.parse(_kFallbackUrl), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir a loja. Tente novamente.')),
    );
  }
}

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
    final primary = Theme.of(context).colorScheme.primary;
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
              Icon(Icons.fitness_center, color: primary, size: 64),
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
                onPressed: () => _abrirStore(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
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
    final primaryColor = _hexColor(data.corPrimaria, Theme.of(context).colorScheme.primary);
    final secondaryColor = _hexColor(data.corSecundaria, const Color(0xFF0097A7));

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: HeroSection(data: data, slug: slug, primaryColor: primaryColor, secondaryColor: secondaryColor)),
        SliverToBoxAdapter(child: SocialProofSection(data: data)),
        SliverToBoxAdapter(child: MetodoSection(data: data, primaryColor: primaryColor)),
        SliverToBoxAdapter(child: SobreSection(data: data)),
        SliverToBoxAdapter(child: EspecialidadesSection(data: data, primaryColor: primaryColor)),
        SliverToBoxAdapter(child: TecnologiaSection(data: data, primaryColor: primaryColor, secondaryColor: secondaryColor)),
        SliverToBoxAdapter(child: OfertasSection(data: data, slug: slug, primaryColor: primaryColor)),
        SliverToBoxAdapter(child: FaqSection(data: data, primaryColor: primaryColor)),
        SliverToBoxAdapter(child: ContatoSection(data: data)),
        SliverToBoxAdapter(child: DepoimentosSection(data: data, primaryColor: primaryColor)),
        SliverToBoxAdapter(child: GaleriaSection(data: data)),
        SliverToBoxAdapter(child: CtaFinalSection(data: data, slug: slug, primaryColor: primaryColor)),
        SliverToBoxAdapter(child: PoweredByFooter(data: data)),
      ],
    );
  }
}
