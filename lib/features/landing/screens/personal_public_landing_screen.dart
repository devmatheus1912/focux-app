import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class PublicPersonalData {
  final String nomePersonal;
  final String? slogan;
  final String? logoUrl;
  final String? corPrimaria;
  final String? corSecundaria;
  final String? descricaoProfissional;
  final String? especialidades;
  final String? instagram;
  final String? cref;
  final int totalAlunos;
  final int anoCriacao;
  final String plano;

  PublicPersonalData({
    required this.nomePersonal,
    this.slogan,
    this.logoUrl,
    this.corPrimaria,
    this.corSecundaria,
    this.descricaoProfissional,
    this.especialidades,
    this.instagram,
    this.cref,
    required this.totalAlunos,
    required this.anoCriacao,
    required this.plano,
  });

  factory PublicPersonalData.fromJson(Map<String, dynamic> j) => PublicPersonalData(
        nomePersonal: j['nomePersonal'] as String? ?? '',
        slogan: j['slogan'] as String?,
        logoUrl: j['logoUrl'] as String?,
        corPrimaria: j['corPrimaria'] as String?,
        corSecundaria: j['corSecundaria'] as String?,
        descricaoProfissional: j['descricaoProfissional'] as String?,
        especialidades: j['especialidades'] as String?,
        instagram: j['instagram'] as String?,
        cref: j['cref'] as String?,
        totalAlunos: j['totalAlunos'] as int? ?? 0,
        anoCriacao: j['anoCriacao'] as int? ?? DateTime.now().year,
        plano: j['plano'] as String? ?? 'PREMIUM',
      );

  bool get isEnterprise => plano == 'ENTERPRISE';
  bool get isPremiumOrAbove => plano == 'PREMIUM' || plano == 'ENTERPRISE';
}

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

    return CustomScrollView(
      slivers: [
        // SECTION 1 — HERO
        SliverToBoxAdapter(
          child: Container(
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
                ],
              ),
            ),
          ),
        ),

        // SECTION 2 — SOCIAL PROOF
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BadgeChip(
                      icon: Icons.people_outline,
                      label: '${data.totalAlunos} alunos'),
                  if (data.cref != null && data.cref!.isNotEmpty)
                    const _BadgeChip(
                        icon: Icons.verified_outlined, label: 'CREF ✓'),
                  _BadgeChip(
                      icon: Icons.calendar_today_outlined,
                      label: 'Desde ${data.anoCriacao}'),
                ],
              ),
            ),
          ),
        ),

        // SECTION 3 — SOBRE
        if (data.descricaoProfissional != null &&
            data.descricaoProfissional!.isNotEmpty)
          SliverToBoxAdapter(
            child: _Section(
              title: 'Sobre',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.logoUrl != null && data.isEnterprise)
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(data.logoUrl!),
                    )
                  else
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF3B5FE2),
                      child: Text(
                        data.nomePersonal.isNotEmpty
                            ? data.nomePersonal[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data.descricaoProfissional!,
                      style: const TextStyle(
                          color: Color(0xFFCBD5E1), fontSize: 14, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // SECTION 4 — ESPECIALIDADES
        if (data.especialidades != null && data.especialidades!.isNotEmpty)
          SliverToBoxAdapter(
            child: _Section(
              title: 'Especialidades',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.especialidades!
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .map((e) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: data.isEnterprise
                                ? primaryColor.withValues(alpha: 0.18)
                                : const Color(0xFF3B5FE2)
                                    .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: data.isEnterprise
                                  ? primaryColor.withValues(alpha: 0.4)
                                  : const Color(0xFF3B5FE2)
                                      .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            e,
                            style: TextStyle(
                              color: data.isEnterprise
                                  ? primaryColor
                                  : const Color(0xFF3B5FE2),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),

        // SECTION 5 — CONTATO
        if (data.instagram != null && data.instagram!.isNotEmpty)
          SliverToBoxAdapter(
            child: _Section(
              title: 'Contato',
              child: OutlinedButton.icon(
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text('@${data.instagram}'),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                        text: 'https://instagram.com/${data.instagram}'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Link do Instagram copiado!')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Color(0xFF374151)),
                ),
              ),
            ),
          ),

        // SECTION 6 — CTA FINAL
        SliverToBoxAdapter(
          child: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: data.isEnterprise
                  ? primaryColor
                  : const Color(0xFF3B5FE2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Comece hoje.\nSeu personal está esperando.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.3),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/register/aluno?p=$slug');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: data.isEnterprise
                          ? primaryColor
                          : const Color(0xFF3B5FE2),
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Criar minha conta grátis →',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // SECTION 7 — FOOTER (hide for enterprise)
        if (!data.isEnterprise)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const Divider(color: Color(0xFF1F2937)),
                  const SizedBox(height: 12),
                  Text(
                    'Powered by Focux Personal • ${DateTime.now().year}',
                    style: const TextStyle(
                        color: Color(0xFF6B7280), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BadgeChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF3B5FE2), size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          child,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
