import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../perfil/providers/perfil_provider.dart';

class LandingPageConfigScreen extends ConsumerWidget {
  const LandingPageConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final perfilAsync = ref.watch(perfilProvider);

    return Scaffold(
      backgroundColor: bg,
      body: perfilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Nao foi possivel carregar a configuracao da landing agora.',
              style: TextStyle(color: mute),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (perfil) {
          final brand = _hexToColor(
            perfil.corPrimaria,
            Theme.of(context).colorScheme.primary,
          );
          final slug = perfil.slug ?? 'seu-perfil';
          final publicUrl = 'https://focux.app/p/$slug';
          final servicesCount = perfil.servicos.length;
          final packagesCount = perfil.pacotes.length;
          final faqCount = perfil.faq.length;
          final heroReady = (perfil.slogan?.trim().isNotEmpty ?? false) &&
              (perfil.descricaoProfissional?.trim().isNotEmpty ?? false);
          final mediaReady = (perfil.logoUrl?.trim().isNotEmpty ?? false) ||
              (perfil.videoUrl?.trim().isNotEmpty ?? false) ||
              (perfil.heroImageUrl?.trim().isNotEmpty ?? false);
          final trackingReady = perfil.trackingId?.trim().isNotEmpty ?? false;

          final configs = [
            (
              icon: Icons.design_services_outlined,
              label: 'Servicos publicados',
              value: servicesCount == 0
                  ? 'Nenhum servico configurado'
                  : '$servicesCount servicos em destaque',
            ),
            (
              icon: Icons.sell_outlined,
              label: 'Pacotes e valores',
              value: packagesCount == 0
                  ? 'Nenhum pacote com preco'
                  : '$packagesCount pacotes ativos',
            ),
            (
              icon: Icons.help_outline,
              label: 'FAQ de venda',
              value: faqCount == 0
                  ? 'Nenhuma pergunta configurada'
                  : '$faqCount perguntas publicadas',
            ),
            (
              icon: Icons.palette_outlined,
              label: 'Cor principal',
              value: perfil.corPrimaria?.toUpperCase() ?? '#3B5FE2',
            ),
            (
              icon: Icons.camera_alt_outlined,
              label: 'Midia de autoridade',
              value: mediaReady
                  ? 'Logo/video configurados'
                  : 'Sem logo ou video ainda',
            ),
            (
              icon: Icons.query_stats_outlined,
              label: 'Tracking',
              value: trackingReady
                  ? 'Campanha marcada'
                  : 'Sem origem de campanha',
            ),
            (
              icon: Icons.edit_note_outlined,
              label: 'Copy principal',
              value: heroReady
                  ? 'Hero da landing preenchido'
                  : 'Complete slogan e descricao',
            ),
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 54),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perfil.plano,
                        style: TextStyle(
                          color: brand,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sua landing comercial',
                        style: TextStyle(
                          color: ink,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Aqui fica o resumo do que ja esta pronto para captar alunos e o que ainda falta preencher.',
                        style: TextStyle(color: mute, fontSize: 14, height: 1.55),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0x14182640) : BrandPalette.softer(brand),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: brand.withValues(alpha: 0.26),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: brand.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.public, color: brand, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Link publico',
                                    style: TextStyle(
                                      color: Color(0xFF2BB673),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    perfil.nome,
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: dark ? EagleTokens.darkCard : EagleTokens.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: dark ? EagleTokens.darkLine : EagleTokens.line,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  publicUrl,
                                  style: TextStyle(
                                    color: brand,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: publicUrl));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Link copiado!')),
                                  );
                                },
                                icon: Icon(Icons.copy, color: brand, size: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: 'Servicos',
                                value: servicesCount.toString(),
                                dark: dark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MetricCard(
                                label: 'Pacotes',
                                value: packagesCount.toString(),
                                dark: dark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MetricCard(
                                label: 'FAQ',
                                value: faqCount.toString(),
                                dark: dark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'Checklist da landing',
                    style: TextStyle(
                      color: ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final config in configs)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: dark ? EagleTokens.darkCard : EagleTokens.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: dark ? EagleTokens.darkLine : EagleTokens.line,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: brand.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(config.icon, color: brand, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      config.label,
                                      style: TextStyle(
                                        color: ink,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      config.value,
                                      style: TextStyle(
                                        color: mute,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => context.push('/identidade-visual'),
                          style: FilledButton.styleFrom(
                            backgroundColor: brand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Editar conteudo da landing'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: publicUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Link da landing copiado.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.share_outlined, size: 16),
                          label: const Text('Compartilhar landing page'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final bool dark;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: dark ? EagleTokens.darkCard : EagleTokens.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dark ? EagleTokens.darkLine : EagleTokens.line,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: dark ? EagleTokens.darkInk : EagleTokens.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: dark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

Color _hexToColor(String? hex, Color fallback) {
  if (hex == null) return fallback;
  final clean = hex.replaceAll('#', '');
  if (clean.length != 6) return fallback;
  final value = int.tryParse('FF$clean', radix: 16);
  if (value == null) return fallback;
  return Color(value);
}
