import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/friendly_error.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/theme_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import '../utils/perfil_readiness.dart';
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

  Future<void> _handleChecklistAction(
    PerfilChecklistAction action,
    PerfilPersonal perfil,
  ) async {
    switch (action) {
      case PerfilChecklistAction.photo:
        await _pickAndUploadPhoto();
      case PerfilChecklistAction.editProfile:
        await _openEditPerfil(perfil);
      case PerfilChecklistAction.brand:
        if (mounted) context.push('/identidade-visual');
      case PerfilChecklistAction.wallet:
        if (mounted) context.push('/perfil/wallet');
      case PerfilChecklistAction.convites:
        if (mounted) context.push('/convites');
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
                  onChecklistAction:
                      (action) => _handleChecklistAction(action, perfil),
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
                  onChecklistAction:
                      (action) => _handleChecklistAction(action, perfil),
                ),
            data:
                (dashboard) => _PerfilBody(
                  perfil: perfil,
                  dashboard: dashboard,
                  uploadingPhoto: _uploadingPhoto,
                  onPickPhoto: _pickAndUploadPhoto,
                  onEditPerfil: () => _openEditPerfil(perfil),
                  onLogout: _logout,
                  onChecklistAction:
                      (action) => _handleChecklistAction(action, perfil),
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
      backgroundColor: Colors.transparent,
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
      backgroundColor: Colors.transparent,
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
  final void Function(PerfilChecklistAction action) onChecklistAction;

  const _PerfilBody({
    required this.perfil,
    required this.dashboard,
    required this.uploadingPhoto,
    this.loadingMetrics = false,
    required this.onPickPhoto,
    required this.onEditPerfil,
    required this.onLogout,
    required this.onChecklistAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
    final accent = BrandPalette.softened(primaryColor);
    final heroPrimary = BrandPalette.softened(primaryColor, amount: 0.10);
    final heroSecondary = BrandPalette.softened(secondaryColor, amount: 0.14);
    final readiness = PerfilReadinessView.from(
      perfil: perfil,
      dashboard: dashboard,
    );
    final profileScore = readiness.score;
    final brandSubtitle =
        (perfil.slogan ?? '').trim().isNotEmpty
            ? perfil.slogan!.trim()
            : 'Marca ativa no app';
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

    final primaryCta =
        readiness.nextStep ??
        const PerfilNextStep(
          label: 'Operação',
          buttonLabel: 'Convidar alunos',
          action: PerfilChecklistAction.convites,
        );
    final profileComplete = profileScore >= 100;
    final usingDefaultBrand = _usesDefaultPalette(primaryColor, secondaryColor);

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar:
          profileComplete
              ? _PerfilStickyBar(
                accent: accent,
                isDark: isDark,
              )
              : null,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: const GradientRotation(160 * math.pi / 180),
                      colors:
                          isDark
                              ? [EagleTokens.brandInk, EagleTokens.brandDeep]
                              : [heroPrimary, heroSecondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: heroPrimary.withValues(alpha: isDark ? 0.22 : 0.24),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                        spreadRadius: -8,
                      ),
                    ],
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
                                const SizedBox(width: 6),
                                Consumer(
                                  builder: (context, ref, _) {
                                    final themeDark =
                                        Theme.of(context).brightness ==
                                        Brightness.dark;
                                    return _HeroAction(
                                      icon:
                                          themeDark
                                              ? Icons.wb_sunny_outlined
                                              : Icons.dark_mode_outlined,
                                      onTap:
                                          () => ref
                                              .read(themeModeProvider.notifier)
                                              .toggle(),
                                    );
                                  },
                                ),
                                const SizedBox(width: 6),
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
                              onEdit: onEditPerfil,
                              onWallet: () => context.push('/perfil/wallet'),
                              onCopilot:
                                  () => goPersonalShellTab(
                                    context,
                                    '/ia/copiloto',
                                  ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.16),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(28),
                                bottomRight: Radius.circular(28),
                              ),
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
                padding: EdgeInsets.fromLTRB(18, 16, 18, profileComplete ? 28 : 96),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _CardSection(
                      title: 'Identidade visual',
                      subtitle:
                          'Logo, slogan e paleta aplicados no app e na experiência do aluno.',
                      trailingLabel: 'Abrir',
                      onTrailingTap: () {
                        HapticFeedback.selectionClick();
                        context.push('/identidade-visual');
                      },
                      isDark: isDark,
                      accent: accent,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.push('/identidade-visual');
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _BrandPreview(
                                primary: heroPrimary,
                                secondary: heroSecondary,
                                profileName: perfil.nome,
                                subtitle: brandSubtitle,
                                logoUrl: perfil.logoUrl ?? dashboard.logoUrl,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 14),
                              _BrandPaletteStrip(
                                primary: primaryColor,
                                secondary: secondaryColor,
                                mute: mute,
                                usingDefault: usingDefaultBrand,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CompletenessCard(
                      score: profileScore,
                      accent: accent,
                      isDark: isDark,
                      items: readiness.items,
                      nextStep: readiness.nextStep,
                      onChecklistAction: onChecklistAction,
                    ),
                    const SizedBox(height: 14),
                    _ProfessionalDataPanel(
                      perfil: perfil,
                      dashboard: dashboard,
                      bioText: bioText,
                      accent: accent,
                      mute: mute,
                      line: line,
                      isDark: isDark,
                      onEdit: onEditPerfil,
                    ),
                    const SizedBox(height: 14),
                    _CardSection(
                      title: 'Conta e plano',
                      subtitle: 'Acesso, billing, IA, documentos e seguranca.',
                      isDark: isDark,
                      accent: accent,
                      child: Column(
                        children: [
                          _ActionTile(
                            icon: Icons.auto_awesome_outlined,
                            label: 'Copiloto IA',
                            value: '${_formatPlanLabel(perfil.plano)} ativo',
                            accent: accent,
                            mute: mute,
                            line: line,
                            onTap:
                                () => goPersonalShellTab(context, '/ia/copiloto'),
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
                            icon: Icons.groups_2_outlined,
                            label: 'Meus alunos',
                            value:
                                loadingMetrics
                                    ? '--'
                                    : '${dashboard.totalAlunos} cadastrados',
                            accent: accent,
                            mute: mute,
                            line: line,
                            onTap: () => goPersonalShellTab(context, '/alunos'),
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
                    if (!profileComplete) ...[
                      const SizedBox(height: 16),
                      _PerfilBottomActions(
                        profileComplete: profileComplete,
                        walletComplete: _hasWallet(perfil),
                        primaryCta: primaryCta,
                        onChecklistAction: onChecklistAction,
                      ),
                    ],
                  ]),
                ),
              ),
            ],
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
  final VoidCallback onEdit;
  final VoidCallback onWallet;
  final VoidCallback onCopilot;

  const _HeroQuickActions({
    required this.onBrand,
    required this.onEdit,
    required this.onWallet,
    required this.onCopilot,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.palette_outlined, 'Marca', onBrand),
      (Icons.edit_outlined, 'Perfil', onEdit),
      (Icons.account_balance_wallet_outlined, 'PIX', onWallet),
      (Icons.auto_awesome_outlined, 'IA', onCopilot),
    ];

    return Row(
      children:
          actions
              .map(
                (item) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        item.$3();
                      },
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(38),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
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
  final VoidCallback? onTrailingTap;
  final bool isDark;
  final Color accent;
  final Widget child;

  const _CardSection({
    required this.title,
    required this.isDark,
    required this.child,
    this.subtitle,
    this.trailingLabel,
    this.onTrailingTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;

    return Container(
      decoration: chrome.panel(radius: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(color: mute, fontSize: 12, height: 1.35),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingLabel != null && onTrailingTap != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTrailingTap,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              trailingLabel!,
                              style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.north_east, size: 13, color: accent),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _BrandPaletteStrip extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final Color mute;
  final bool usingDefault;

  const _BrandPaletteStrip({
    required this.primary,
    required this.secondary,
    required this.mute,
    required this.usingDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.palette_outlined, size: 14, color: mute),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            usingDefault
                ? 'Paleta padrão Focux · toque para personalizar'
                : 'Sua paleta está ativa · toque para editar',
            style: TextStyle(
              color: mute,
              fontSize: 11.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _PaletteDot(color: primary),
        const SizedBox(width: 6),
        _PaletteDot(color: secondary),
      ],
    );
  }
}

class _PaletteDot extends StatelessWidget {
  final Color color;

  const _PaletteDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}

class _PerfilStickyBar extends StatelessWidget {
  const _PerfilStickyBar({required this.accent, required this.isDark});

  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? EagleTokens.darkCard : EagleTokens.card)
              .withValues(alpha: 0.96),
          border: Border(top: BorderSide(color: chrome.line.withValues(alpha: 0.7))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    goPersonalShellTab(context, '/alunos');
                  },
                  icon: const Icon(Icons.groups_2_outlined, size: 18),
                  label: const Text('Meus alunos'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    goPersonalShellTab(context, '/ia/copiloto');
                  },
                  icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                  label: const Text('Copiloto IA'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerfilBottomActions extends StatelessWidget {
  final bool profileComplete;
  final bool walletComplete;
  final PerfilNextStep primaryCta;
  final void Function(PerfilChecklistAction action) onChecklistAction;

  const _PerfilBottomActions({
    required this.profileComplete,
    required this.walletComplete,
    required this.primaryCta,
    required this.onChecklistAction,
  });

  @override
  Widget build(BuildContext context) {
    if (profileComplete) {
      return const SizedBox.shrink();
    }

    if (!walletComplete) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push('/perfil/wallet');
              },
              icon: const Icon(Icons.account_balance_wallet_outlined),
              label: const Text('Configurar PIX'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                onChecklistAction(primaryCta.action);
              },
              icon: Icon(
                primaryCta.action == PerfilChecklistAction.convites
                    ? Icons.person_add_outlined
                    : Icons.arrow_forward_rounded,
                size: 18,
              ),
              label: Text(primaryCta.buttonLabel),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          HapticFeedback.selectionClick();
          onChecklistAction(primaryCta.action);
        },
        icon: Icon(
          primaryCta.action == PerfilChecklistAction.convites
              ? Icons.person_add_outlined
              : Icons.arrow_forward_rounded,
          size: 18,
        ),
        label: Text(primaryCta.buttonLabel),
      ),
    );
  }
}

class _BrandPreview extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final String profileName;
  final String subtitle;
  final String? logoUrl;
  final bool isDark;

  const _BrandPreview({
    required this.primary,
    required this.secondary,
    required this.profileName,
    required this.subtitle,
    this.logoUrl,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child:
                logoUrl != null && logoUrl!.isNotEmpty
                    ? Image.network(
                      logoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Icon(
                            Icons.fitness_center,
                            color: primary,
                            size: 22,
                          ),
                    )
                    : Icon(Icons.fitness_center, color: primary, size: 22),
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
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6FE296),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
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

class _CompletenessCard extends StatelessWidget {
  final int score;
  final Color accent;
  final bool isDark;
  final List<PerfilChecklistItem> items;
  final PerfilNextStep? nextStep;
  final void Function(PerfilChecklistAction action) onChecklistAction;

  const _CompletenessCard({
    required this.score,
    required this.accent,
    required this.isDark,
    required this.items,
    required this.nextStep,
    required this.onChecklistAction,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final complete = score >= 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: chrome.panel(radius: 20),
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
                      complete ? 'Perfil pronto' : 'Prontidão comercial',
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complete
                          ? 'Seu perfil comercial está pronto para operar.'
                          : 'Faltam ${items.where((item) => !item.done).length} passos para parecer premium.',
                      style: TextStyle(color: mute, fontSize: 12, height: 1.35),
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
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : EagleTokens.lineSoft,
                      ),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: value,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accent.withValues(alpha: 0.72), accent],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
                      .map(
                        (item) => _ChecklistChip(
                          item: item,
                          accent: accent,
                          onTap:
                              item.done
                                  ? null
                                  : () => onChecklistAction(item.action),
                        ),
                      )
                      .toList(),
            ),
          if (!complete) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  if (nextStep != null) {
                    onChecklistAction(nextStep!.action);
                    return;
                  }
                  onChecklistAction(PerfilChecklistAction.convites);
                },
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(nextStep?.buttonLabel ?? 'Completar perfil'),
              ),
            ),
          ],
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
              'Operação pronta — use o Copiloto IA, convide alunos e acompanhe pelo dashboard.',
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
  final PerfilChecklistItem item;
  final Color accent;
  final VoidCallback? onTap;

  const _ChecklistChip({
    required this.item,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color =
        item.done
            ? accent
            : (isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color:
                item.done
                    ? accent.withValues(alpha: isDark ? 0.16 : 0.09)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : EagleTokens.lineSoft),
            borderRadius: BorderRadius.circular(999),
            border:
                onTap != null
                    ? Border.all(color: accent.withValues(alpha: 0.22))
                    : null,
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
        ),
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
  final VoidCallback onEdit;

  const _ProfessionalDataPanel({
    required this.perfil,
    required this.dashboard,
    required this.bioText,
    required this.accent,
    required this.mute,
    required this.line,
    required this.isDark,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;

    return _CardSection(
      title: 'Dados profissionais',
      subtitle: 'Contrato, canais publicos e prova de autoridade.',
      trailingLabel: 'Editar',
      onTrailingTap: onEdit,
      isDark: isDark,
      accent: accent,
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
            onTap: onEdit,
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
            onTap: onEdit,
          ),
          _InfoTile(
            icon: Icons.alternate_email,
            label: 'Instagram',
            value: _formatInstagram(perfil.instagram ?? dashboard.instagram),
            accent: accent,
            mute: mute,
            line: line,
            onTap: onEdit,
            showDivider: bioText.isNotEmpty,
          ),
          if (bioText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 13),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(14),
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
                      Icon(Icons.chevron_right, size: 18, color: mute),
                    ],
                  ),
                ),
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
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.mute,
    required this.line,
    this.showDivider = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
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
          if (onTap != null) Icon(Icons.chevron_right, size: 18, color: mute),
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
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
        padding: const EdgeInsets.symmetric(vertical: 15),
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
                          ? accent.withValues(alpha: 0.14)
                          : BrandPalette.soft(accent)),
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

bool _hasWallet(PerfilPersonal perfil) =>
    _hasText(perfil.chavePix) ||
    (_hasText(perfil.banco) &&
        _hasText(perfil.agencia) &&
        _hasText(perfil.conta));

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

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

bool _usesDefaultPalette(Color primary, Color secondary) {
  bool close(Color a, Color b) =>
      (a.red - b.red).abs() <= 8 &&
      (a.green - b.green).abs() <= 8 &&
      (a.blue - b.blue).abs() <= 8;

  return close(primary, BrandPalette.defaultPrimary) &&
      close(secondary, BrandPalette.defaultSecondary);
}
