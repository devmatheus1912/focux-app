import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/friendly_error.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/config/env.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _uploadingPhoto = false;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (file == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final logoUrl = await MediaUploadService(
        ref.read(apiClientProvider),
      ).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: 'perfil',
        resourceType: 'image',
      );

      await ref.read(perfilRepositoryProvider).atualizar(logoUrl: logoUrl);
      ref.invalidate(perfilProvider);
      ref.invalidate(dashboardProvider);

      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(content: Text('Foto atualizada com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(
          content: Text(
            friendlyError(
              error,
              fallback: 'Nao foi possivel enviar a foto agora.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  Future<void> _openEditPerfil(PerfilPersonal perfil) async {
    final updated = await context.push<bool>('/perfil/editar', extra: perfil);
    if (updated == true) {
      ref.invalidate(perfilProvider);
      ref.invalidate(dashboardProvider);
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);
    final dashboardAsync = ref.watch(dashboardProvider);

    return perfilAsync.when(
      loading: () => const _PerfilLoadingScaffold(),
      error:
          (error, _) => _PerfilErrorScaffold(
            error: error,
            onRetry: () => ref.invalidate(perfilProvider),
          ),
      data:
          (perfil) => dashboardAsync.when(
            loading:
                () => _PerfilBody(
                  perfil: perfil,
                  dashboard: DashboardData(
                    totalAlunos: 0,
                    alunosAtivos: 0,
                    planoAtual: perfil.plano,
                    limiteAlunos: 0,
                    nomePersonal: perfil.nome,
                    logoUrl: perfil.logoUrl,
                    corPrimaria: perfil.corPrimaria,
                    corSecundaria: perfil.corSecundaria,
                    descricaoProfissional: perfil.descricaoProfissional,
                    instagram: perfil.instagram,
                  ),
                  uploadingPhoto: _uploadingPhoto,
                  loadingMetrics: true,
                  onPickPhoto: _pickAndUploadPhoto,
                  onEditPerfil: () => _openEditPerfil(perfil),
                  onLogout: _logout,
                ),
            error:
                (_, __) => _PerfilBody(
                  perfil: perfil,
                  dashboard: DashboardData(
                    totalAlunos: 0,
                    alunosAtivos: 0,
                    planoAtual: perfil.plano,
                    limiteAlunos: 0,
                    nomePersonal: perfil.nome,
                    logoUrl: perfil.logoUrl,
                    corPrimaria: perfil.corPrimaria,
                    corSecundaria: perfil.corSecundaria,
                    descricaoProfissional: perfil.descricaoProfissional,
                    instagram: perfil.instagram,
                  ),
                  uploadingPhoto: _uploadingPhoto,
                  onPickPhoto: _pickAndUploadPhoto,
                  onEditPerfil: () => _openEditPerfil(perfil),
                  onLogout: _logout,
                ),
            data:
                (dashboard) => _PerfilBody(
                  perfil: perfil,
                  dashboard: dashboard,
                  uploadingPhoto: _uploadingPhoto,
                  onPickPhoto: _pickAndUploadPhoto,
                  onEditPerfil: () => _openEditPerfil(perfil),
                  onLogout: _logout,
                ),
          ),
    );
  }
}

class _PerfilLoadingScaffold extends StatelessWidget {
  const _PerfilLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final surface = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                height: 286,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1AABA4), Color(0xFF0A1F24)],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              for (final height in [132.0, 178.0, 228.0])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: line),
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

class _PerfilErrorScaffold extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _PerfilErrorScaffold({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: EagleTokens.badSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.cloud_off_outlined,
                    color: EagleTokens.bad,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Perfil indisponivel',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  friendlyError(
                    error,
                    fallback: 'Nao foi possivel carregar seus dados agora.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mute, height: 1.35),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PerfilBody extends StatelessWidget {
  final PerfilPersonal perfil;
  final DashboardData dashboard;
  final bool uploadingPhoto;
  final bool loadingMetrics;
  final VoidCallback onPickPhoto;
  final VoidCallback onEditPerfil;
  final VoidCallback onLogout;

  const _PerfilBody({
    required this.perfil,
    required this.dashboard,
    required this.uploadingPhoto,
    this.loadingMetrics = false,
    required this.onPickPhoto,
    required this.onEditPerfil,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final themePrimary = theme.colorScheme.primary;

    final primaryColor = _parseColor(
      perfil.corPrimaria ?? dashboard.corPrimaria,
      fallback: themePrimary,
    );
    final secondaryColor = _parseColor(
      perfil.corSecundaria ?? dashboard.corSecundaria,
      fallback: BrandPalette.deep(themePrimary),
    );
    final accent = primaryColor;
    final profileScore = _profileScore(perfil, dashboard);
    final publicUrl = _publicProfileUrl(perfil);
    final displayPublicUrl = _displayPublicProfileUrl(perfil, publicUrl);
    final bioText =
        (perfil.descricaoProfissional ?? dashboard.descricaoProfissional ?? '')
            .trim();

    final stats = [
      _ProfileStat(
        label: 'Alunos',
        value: loadingMetrics ? '--' : dashboard.totalAlunos.toString(),
        icon: Icons.groups_2_outlined,
      ),
      _ProfileStat(
        label: 'Ativos',
        value: loadingMetrics ? '--' : dashboard.alunosAtivos.toString(),
        icon: Icons.bolt_outlined,
      ),
      _ProfileStat(label: 'Marca', value: '$profileScore%', icon: Icons.tune),
    ];

    final swatches = <Color>[
      primaryColor,
      secondaryColor,
      BrandPalette.soft(primaryColor),
      Colors.white,
      const Color(0xFF111318),
    ];

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: ColoredBox(
          color: bg,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: const GradientRotation(160 * math.pi / 180),
                      colors:
                          isDark
                              ? const [Color(0xFF159A9A), Color(0xFF0A2E2E)]
                              : [primaryColor, secondaryColor],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(painter: _ProfileTexturePainter()),
                        ),
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _HeroAction(
                                  icon: Icons.arrow_back_ios_new,
                                  onTap:
                                      () => safePopOrGo(
                                        context,
                                        '/dashboard/personal',
                                      ),
                                ),
                                Text(
                                  'Perfil',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                _HeroAction(
                                  icon: Icons.edit_outlined,
                                  onTap: onEditPerfil,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _Avatar(
                                  nome: perfil.nome,
                                  logoUrl: perfil.logoUrl ?? dashboard.logoUrl,
                                  primaryColor: primaryColor,
                                  onTap: onPickPhoto,
                                  loading: uploadingPhoto,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _PlanPill(
                                        label: _formatProfilePlan(perfil.plano),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        perfil.nome,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              height: 0.98,
                                            ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _buildSubtitle(perfil),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12.5,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _HeroQuickActions(
                              onBrand: () => context.push('/identidade-visual'),
                              onLanding: () => context.push('/landing-config'),
                              onWallet: () => context.push('/perfil/wallet'),
                              onPlans: () => context.push('/planos'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                              border: Border(
                                top: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                            child: Row(
                              children: List.generate(stats.length, (index) {
                                final item = stats[index];
                                return Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border:
                                          index < stats.length - 1
                                              ? Border(
                                                right: BorderSide(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.10),
                                                ),
                                              )
                                              : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          item.icon,
                                          size: 15,
                                          color: Colors.white.withValues(
                                            alpha: 0.78,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.value,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _CardSection(
                      title: 'Identidade visual',
                      subtitle:
                          'Marca aplicada no app, landing page e white-label.',
                      trailingLabel: 'Abrir',
                      onTap: () => context.push('/identidade-visual'),
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BrandPreview(
                            primary: primaryColor,
                            secondary: secondaryColor,
                            profileName: perfil.nome,
                            publicUrl: displayPublicUrl,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 9,
                            runSpacing: 9,
                            children: [
                              ...swatches.map(
                                (color) => _ColorSwatch(
                                  color: color,
                                  borderColor: line,
                                  selected: color == primaryColor,
                                ),
                              ),
                              _AddSwatch(borderColor: line, mute: mute),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CompletenessCard(
                      score: profileScore,
                      accent: accent,
                      isDark: isDark,
                      items: _profileChecklist(perfil, dashboard),
                      onPublicProfile:
                          publicUrl == null
                              ? () => context.push('/landing-config')
                              : () => launchUrl(
                                Uri.parse(publicUrl),
                                mode: LaunchMode.externalApplication,
                              ),
                      onLanding: () => context.push('/landing-config'),
                    ),
                    const SizedBox(height: 12),
                    _ProfessionalDataPanel(
                      perfil: perfil,
                      dashboard: dashboard,
                      bioText: bioText,
                      accent: accent,
                      mute: mute,
                      line: line,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _CardSection(
                      title: 'Conta e plano',
                      subtitle: 'Acesso, billing, IA, documentos e seguranca.',
                      isDark: isDark,
                      child: Column(
                        children: [
                          _ActionTile(
                            icon: Icons.auto_awesome_outlined,
                            label: 'Copiloto IA',
                            value: '${_formatPlanLabel(perfil.plano)} ativo',
                            accent: accent,
                            mute: mute,
                            line: line,
                            onTap: () => context.go('/ia/copiloto'),
                          ),
                          _ActionTile(
                            icon: Icons.workspace_premium_outlined,
                            label: 'Planos e assinatura',
                            value: 'Gerenciar',
                            accent: accent,
                            mute: mute,
                            line: line,
                            onTap: () => context.push('/planos'),
                          ),
                          _ActionTile(
                            icon: Icons.public_outlined,
                            label: 'Landing page',
                            value: publicUrl == null ? 'Configurar' : 'Editar',
                            accent: accent,
                            mute: mute,
                            line: line,
                            onTap: () => context.push('/landing-config'),
                          ),
                          _ActionTile(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Carteira e PIX',
                            value:
                                _hasWallet(perfil) ? 'Completa' : 'Configurar',
                            accent: accent,
                            mute: mute,
                            line: line,
                            onTap: () => context.push('/perfil/wallet'),
                          ),
                          _ActionTile(
                            icon: Icons.bolt_outlined,
                            label: 'Migracao Magica',
                            value: 'Abrir ferramenta',
                            accent: accent,
                            mute: mute,
                            line: line,
                            onTap: () => context.push('/migracao-magica'),
                          ),
                          _ActionTile(
                            icon: Icons.description_outlined,
                            label: 'Termos de uso',
                            value: '',
                            accent: accent,
                            mute: mute,
                            line: line,
                            onTap:
                                () => launchUrl(
                                  Uri.parse(
                                    'https://focux-backend-production.up.railway.app/termos.html',
                                  ),
                                  mode: LaunchMode.externalApplication,
                                ),
                          ),
                          _ActionTile(
                            icon: Icons.privacy_tip_outlined,
                            label: 'Politica de privacidade',
                            value: '',
                            accent: accent,
                            mute: mute,
                            line: line,
                            onTap:
                                () => launchUrl(
                                  Uri.parse(
                                    'https://focux-backend-production.up.railway.app/privacidade.html',
                                  ),
                                  mode: LaunchMode.externalApplication,
                                ),
                          ),
                          _ActionTile(
                            icon: Icons.logout,
                            label: 'Sair da conta',
                            value: '',
                            accent: EagleTokens.bad,
                            mute: mute,
                            line: line,
                            danger: true,
                            onTap: onLogout,
                          ),
                          _ActionTile(
                            icon: Icons.delete_forever_outlined,
                            label: 'Excluir minha conta',
                            value: '',
                            accent: EagleTokens.bad,
                            mute: mute,
                            line: line,
                            danger: true,
                            showDivider: false,
                            onTap: () => _showDeleteAccountDialog(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/perfil/wallet'),
                            icon: const Icon(
                              Icons.account_balance_wallet_outlined,
                            ),
                            label: const Text('PIX'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed:
                                publicUrl == null
                                    ? () => context.push('/landing-config')
                                    : () => launchUrl(
                                      Uri.parse(publicUrl),
                                      mode: LaunchMode.externalApplication,
                                    ),
                            icon: const Icon(Icons.north_east),
                            label: const Text('Ver perfil publico'),
                          ),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStat {
  final String label;
  final String value;
  final IconData icon;

  const _ProfileStat({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _PlanPill extends StatelessWidget {
  final String label;

  const _PlanPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: EagleTokens.gold, size: 13),
          const SizedBox(width: 5),
          Text(
            'PLANO $label',
            style: const TextStyle(
              color: EagleTokens.gold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroQuickActions extends StatelessWidget {
  final VoidCallback onBrand;
  final VoidCallback onLanding;
  final VoidCallback onWallet;
  final VoidCallback onPlans;

  const _HeroQuickActions({
    required this.onBrand,
    required this.onLanding,
    required this.onWallet,
    required this.onPlans,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.palette_outlined, 'Marca', onBrand),
      (Icons.public_outlined, 'Landing', onLanding),
      (Icons.account_balance_wallet_outlined, 'PIX', onWallet),
      (Icons.workspace_premium_outlined, 'Plano', onPlans),
    ];

    return Row(
      children:
          actions
              .map(
                (item) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: item.$3,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item.$1, color: Colors.white, size: 18),
                            const SizedBox(height: 4),
                            Text(
                              item.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(38),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String nome;
  final String? logoUrl;
  final Color primaryColor;
  final VoidCallback onTap;
  final bool loading;

  const _Avatar({
    required this.nome,
    required this.logoUrl,
    required this.primaryColor,
    required this.onTap,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 82,
          height: 82,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.92),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            backgroundImage:
                logoUrl != null && logoUrl!.isNotEmpty
                    ? NetworkImage(logoUrl!)
                    : null,
            child:
                logoUrl == null || logoUrl!.isEmpty
                    ? Text(
                      _initials(nome),
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                      ),
                    )
                    : null,
          ),
        ),
        Positioned(
          right: 1,
          bottom: 1,
          child: InkWell(
            onTap: loading ? null : onTap,
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              child:
                  loading
                      ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: FxLoading(strokeWidth: 2, color: Colors.white),
                      )
                      : const Icon(Icons.edit, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final VoidCallback? onTap;
  final bool isDark;
  final Widget child;

  const _CardSection({
    required this.title,
    required this.isDark,
    required this.child,
    this.subtitle,
    this.trailingLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final accent = Theme.of(context).colorScheme.primary;

    final content = Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
                if (trailingLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      trailingLabel!,
                      style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: TextStyle(color: mute, fontSize: 12, height: 1.3),
              ),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: content,
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final bool selected;

  const _ColorSwatch({
    required this.color,
    required this.borderColor,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              selected
                  ? Colors.black.withValues(alpha: 0.42)
                  : (color == Colors.white ? borderColor : Colors.transparent),
          width: selected ? 2 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _AddSwatch extends StatelessWidget {
  final Color borderColor;
  final Color mute;

  const _AddSwatch({required this.borderColor, required this.mute});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, style: BorderStyle.solid),
      ),
      child: Icon(Icons.add, size: 16, color: mute),
    );
  }
}

class _BrandPreview extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final String profileName;
  final String? publicUrl;
  final bool isDark;

  const _BrandPreview({
    required this.primary,
    required this.secondary,
    required this.profileName,
    required this.publicUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.fitness_center, color: primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  publicUrl ?? 'Landing ainda sem slug',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'LIVE',
              style: TextStyle(
                color: ink,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletenessCard extends StatelessWidget {
  final int score;
  final Color accent;
  final bool isDark;
  final List<_ProfileChecklistItem> items;
  final VoidCallback onPublicProfile;
  final VoidCallback onLanding;

  const _CompletenessCard({
    required this.score,
    required this.accent,
    required this.isDark,
    required this.items,
    required this.onPublicProfile,
    required this.onLanding,
  });

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final complete = score >= 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete ? 'Perfil pronto' : 'Prontidao comercial',
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      complete
                          ? 'Sua vitrine publica esta pronta para operar.'
                          : 'Perfil pronto para vender, atender e parecer premium.',
                      style: TextStyle(color: mute, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
              if (complete)
                _ReadyStamp(accent: accent)
              else
                Text(
                  '$score%',
                  style: TextStyle(
                    color: accent,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 8,
              backgroundColor:
                  isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : EagleTokens.lineSoft,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 10),
          if (complete)
            _ReadyFocusStrip(accent: accent, isDark: isDark)
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children:
                  items
                      .map((item) => _ChecklistChip(item: item, accent: accent))
                      .toList(),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPublicProfile,
                  icon: const Icon(Icons.north_east, size: 18),
                  label: Text(complete ? 'Ver publico' : 'Ver preview'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onLanding,
                  icon: const Icon(Icons.tune_outlined, size: 18),
                  label: const Text('Otimizar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadyStamp extends StatelessWidget {
  final Color accent;

  const _ReadyStamp({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 15, color: accent),
          const SizedBox(width: 5),
          Text(
            'PRONTO',
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyFocusStrip extends StatelessWidget {
  final Color accent;
  final bool isDark;

  const _ReadyFocusStrip({required this.accent, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : EagleTokens.lineSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt_outlined, color: accent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Proximo ganho: ajustar oferta, CTA e prova social.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: mute,
                fontSize: 11.8,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistChip extends StatelessWidget {
  final _ProfileChecklistItem item;
  final Color accent;

  const _ChecklistChip({required this.item, required this.accent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        item.done
            ? accent
            : (isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color:
            item.done
                ? accent.withValues(alpha: isDark ? 0.16 : 0.09)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : EagleTokens.lineSoft),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            item.label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalDataPanel extends StatelessWidget {
  final PerfilPersonal perfil;
  final DashboardData dashboard;
  final String bioText;
  final Color accent;
  final Color mute;
  final Color line;
  final bool isDark;

  const _ProfessionalDataPanel({
    required this.perfil,
    required this.dashboard,
    required this.bioText,
    required this.accent,
    required this.mute,
    required this.line,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;

    return _CardSection(
      title: 'Dados profissionais',
      subtitle: 'Contrato, canais publicos e prova de autoridade.',
      isDark: isDark,
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: perfil.email,
            accent: accent,
            mute: mute,
            line: line,
          ),
          _InfoTile(
            icon: Icons.badge_outlined,
            label: 'CREF',
            value: perfil.cref ?? 'Nao informado',
            accent: accent,
            mute: mute,
            line: line,
          ),
          _InfoTile(
            icon: Icons.trending_up_outlined,
            label: 'Especialidade',
            value:
                perfil.especialidades ??
                perfil.especialidade ??
                'Nao informada',
            accent: accent,
            mute: mute,
            line: line,
          ),
          _InfoTile(
            icon: Icons.alternate_email,
            label: 'Instagram',
            value: _formatInstagram(perfil.instagram ?? dashboard.instagram),
            accent: accent,
            mute: mute,
            line: line,
            showDivider: bioText.isNotEmpty,
          ),
          if (bioText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LeadingIcon(
                    icon: Icons.notes_outlined,
                    background:
                        isDark
                            ? accent.withValues(alpha: 0.14)
                            : BrandPalette.soft(accent),
                    color: accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bio profissional',
                          style: TextStyle(
                            color: mute,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          bioText,
                          style: TextStyle(
                            color: ink,
                            fontSize: 13.5,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
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
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color mute;
  final Color line;
  final bool showDivider;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.mute,
    required this.line,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border:
            showDivider
                ? Border(bottom: BorderSide(color: line, width: 0.5))
                : null,
      ),
      child: Row(
        children: [
          _LeadingIcon(
            icon: icon,
            background:
                isDark
                    ? accent.withValues(alpha: 0.14)
                    : BrandPalette.soft(accent),
            color: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: mute,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final Color mute;
  final Color line;
  final bool danger;
  final bool showDivider;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.mute,
    required this.line,
    required this.onTap,
    this.danger = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink =
        danger
            ? (isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad)
            : (isDark ? EagleTokens.darkInk : EagleTokens.ink);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border:
              showDivider
                  ? Border(bottom: BorderSide(color: line, width: 0.5))
                  : null,
        ),
        child: Row(
          children: [
            _LeadingIcon(
              icon: icon,
              background:
                  danger
                      ? (isDark ? const Color(0x24FF8B8B) : EagleTokens.badSoft)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : EagleTokens.lineSoft),
              color: danger ? ink : accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: TextStyle(
                  color: danger ? ink : mute,
                  fontSize: 12,
                  fontWeight: danger ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            if (!danger) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 18, color: mute),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color color;

  const _LeadingIcon({
    required this.icon,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }
}

class _ProfileTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.032)
          ..strokeWidth = 0.5;
    const step = 34.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _showDeleteAccountDialog(BuildContext context) {
  showDialog(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: const Text('Excluir conta'),
          content: const Text(
            'Esta ação é irreversível. Todos os seus dados pessoais serão anonimizados '
            'conforme a LGPD (Art. 18). Dados financeiros serão mantidos por 5 anos '
            'conforme legislação fiscal.\n\n'
            'Deseja realmente excluir sua conta?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: EagleTokens.bad),
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  final dio = ApiClient().dio;
                  await dio.delete('/api/lgpd/me/delete');
                  if (!context.mounted) return;
                  FeedbackHelper.showSnackBar(
                    context,
                    const SnackBar(
                      content: Text('Conta excluída com sucesso.'),
                    ),
                  );
                  GoRouter.of(context).go('/login');
                } catch (e) {
                  if (!context.mounted) return;
                  FeedbackHelper.showSnackBar(
                    context,
                    SnackBar(content: Text(friendlyError(e))),
                  );
                }
              },
              child: const Text('Excluir definitivamente'),
            ),
          ],
        ),
  );
}

class _ProfileChecklistItem {
  final String label;
  final bool done;

  const _ProfileChecklistItem(this.label, this.done);
}

List<_ProfileChecklistItem> _profileChecklist(
  PerfilPersonal perfil,
  DashboardData dashboard,
) {
  return [
    _ProfileChecklistItem(
      'Foto',
      _hasText(perfil.logoUrl ?? dashboard.logoUrl),
    ),
    _ProfileChecklistItem('CREF', _hasText(perfil.cref)),
    _ProfileChecklistItem(
      'Especialidade',
      _hasText(perfil.especialidades ?? perfil.especialidade),
    ),
    _ProfileChecklistItem(
      'Bio',
      _hasText(perfil.descricaoProfissional ?? dashboard.descricaoProfissional),
    ),
    _ProfileChecklistItem(
      'Instagram',
      _hasText(perfil.instagram ?? dashboard.instagram),
    ),
    _ProfileChecklistItem(
      'Cores',
      _hasText(perfil.corPrimaria ?? dashboard.corPrimaria),
    ),
    _ProfileChecklistItem('Landing', _hasText(perfil.slug)),
    _ProfileChecklistItem('PIX', _hasWallet(perfil)),
  ];
}

int _profileScore(PerfilPersonal perfil, DashboardData dashboard) {
  final items = _profileChecklist(perfil, dashboard);
  final done = items.where((item) => item.done).length;
  return ((done / items.length) * 100).round();
}

bool _hasWallet(PerfilPersonal perfil) =>
    _hasText(perfil.chavePix) ||
    (_hasText(perfil.banco) &&
        _hasText(perfil.agencia) &&
        _hasText(perfil.conta));

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String? _publicProfileUrl(PerfilPersonal perfil) {
  final slug = perfil.slug?.trim();
  if (slug == null || slug.isEmpty) return null;
  return '${Env.publicWebUrl}/p/$slug';
}

String? _displayPublicProfileUrl(PerfilPersonal perfil, String? canonicalUrl) {
  final domain = perfil.dominioCustomizado?.trim();
  if (domain != null && domain.isNotEmpty) {
    return '$domain aguardando CNAME';
  }
  return canonicalUrl;
}

String _buildSubtitle(PerfilPersonal perfil) {
  final specialty = perfil.especialidade ?? 'Personal Trainer';
  final ig = perfil.instagram?.trim();
  if (ig != null && ig.isNotEmpty) {
    return '$specialty  |  @${ig.replaceFirst('@', '')}';
  }
  return specialty;
}

String _formatPlanLabel(String value) {
  switch (value.trim().toUpperCase()) {
    case 'ENTERPRISE':
      return 'ENTERPRISE';
    case 'PREMIUM':
    case 'PRO':
      return 'PREMIUM';
    default:
      return 'FREE';
  }
}

String _formatProfilePlan(String value) {
  final label = _formatPlanLabel(value);
  return label == 'PREMIUM' ? 'PRO' : label;
}

String _formatInstagram(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Nao informado';
  }
  final normalized = value.trim();
  return normalized.startsWith('@') ? normalized : '@$normalized';
}

String _initials(String nome) {
  final parts = nome
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty);
  if (parts.isEmpty) return 'FP';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

Color _parseColor(String? value, {required Color fallback}) {
  if (value == null || value.trim().isEmpty) {
    return fallback;
  }

  final sanitized = value.trim().replaceFirst('#', '');
  if (sanitized.length != 6 && sanitized.length != 8) {
    return fallback;
  }

  final normalized = sanitized.length == 6 ? 'FF$sanitized' : sanitized;
  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null) {
    return fallback;
  }

  return Color(parsed);
}
