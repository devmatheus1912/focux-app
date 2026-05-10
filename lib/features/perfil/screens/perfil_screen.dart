import 'dart:math' as math;

import 'package:flutter/material.dart';
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
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto atualizada com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
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
      loading:
          () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Erro: $error'))),
      data:
          (perfil) => dashboardAsync.when(
            loading:
                () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
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

class _PerfilBody extends StatelessWidget {
  final PerfilPersonal perfil;
  final DashboardData dashboard;
  final bool uploadingPhoto;
  final VoidCallback onPickPhoto;
  final VoidCallback onEditPerfil;
  final VoidCallback onLogout;

  const _PerfilBody({
    required this.perfil,
    required this.dashboard,
    required this.uploadingPhoto,
    required this.onPickPhoto,
    required this.onEditPerfil,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
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

    final stats = [
      ('Alunos', dashboard.totalAlunos.toString()),
      ('Treinos', '0'),
      ('Meses', '0'),
      ('Avaliação', '5.0'),
    ];

    final swatches = <Color>[
      primaryColor,
      secondaryColor,
      const Color(0xFF7BA3F0),
      Colors.white,
      const Color(0xFF111318),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: const GradientRotation(160 * math.pi / 180),
                  colors:
                      isDark
                          ? const [Color(0xFF2A44A8), Color(0xFF060D28)]
                          : [primaryColor, secondaryColor],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(painter: _GridTexturePainter()),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Column(
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
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              _HeroAction(
                                icon: Icons.edit_outlined,
                                onTap: onEditPerfil,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _Avatar(
                              nome: perfil.nome,
                              logoUrl: perfil.logoUrl ?? dashboard.logoUrl,
                              primaryColor: primaryColor,
                              onTap: onPickPhoto,
                              loading: uploadingPhoto,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          perfil.nome,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _buildSubtitle(perfil),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: EagleTokens.gold,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'PLANO ${_formatProfilePlan(perfil.plano)}',
                                style: const TextStyle(
                                  color: EagleTokens.gold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
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
                                    vertical: 14,
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    border:
                                        index < stats.length - 1
                                            ? Border(
                                              right: BorderSide(
                                                color: Colors.white.withValues(
                                                  alpha: 0.10,
                                                ),
                                              ),
                                            )
                                            : null,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        item.$2,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.$1,
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
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _CardSection(
                  title: 'Identidade visual',
                  trailingLabel: 'Editar',
                  onTap: () => context.push('/identidade-visual'),
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          ...swatches.map(
                            (color) =>
                                _ColorSwatch(color: color, borderColor: line),
                          ),
                          _AddSwatch(borderColor: line, mute: mute),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Cores aplicadas na sua marca, landing page e experiencia white-label.',
                        style: TextStyle(
                          color: mute,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _CardSection(
                  title: 'Informações',
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
                        value: _formatInstagram(
                          perfil.instagram ?? dashboard.instagram,
                        ),
                        accent: accent,
                        mute: mute,
                        line: line,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
                if ((perfil.descricaoProfissional ??
                        dashboard.descricaoProfissional ??
                        '')
                    .trim()
                    .isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _CardSection(
                    title: 'Bio profissional',
                    isDark: isDark,
                    child: Text(
                      perfil.descricaoProfissional ??
                          dashboard.descricaoProfissional ??
                          '',
                      style: TextStyle(color: ink, height: 1.55),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _CardSection(
                  title: 'Conta e plano',
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
                        onTap: () => launchUrl(
                          Uri.parse('https://focux-backend-production.up.railway.app/termos.html'),
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
                        onTap: () => launchUrl(
                          Uri.parse('https://focux-backend-production.up.railway.app/privacidade.html'),
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
                        onPressed: onEditPerfil,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar perfil'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.push('/paywall'),
                        icon: const Icon(Icons.north_east),
                        label: const Text('Ver upgrades'),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
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
        CircleAvatar(
          radius: 44,
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
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  )
                  : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: InkWell(
            onTap: loading ? null : onTap,
            borderRadius: BorderRadius.circular(26),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor, width: 2),
              ),
              child:
                  loading
                      ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      )
                      : Icon(Icons.edit, size: 14, color: primaryColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTap;
  final bool isDark;
  final Widget child;

  const _CardSection({
    required this.title,
    required this.isDark,
    required this.child,
    this.trailingLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                ),
                if (trailingLabel != null)
                  InkWell(
                    onTap: onTap,
                    child: Text(
                      trailingLabel!,
                      style: TextStyle(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final Color borderColor;

  const _ColorSwatch({required this.color, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color == Colors.white ? borderColor : Colors.transparent,
          width: 1.5,
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

class _GridTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..strokeWidth = 0.5;

    const step = 26.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _showDeleteAccountDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conta excluída com sucesso.')),
              );
              GoRouter.of(context).go('/login');
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
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
