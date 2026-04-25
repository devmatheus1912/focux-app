import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/personal_brand_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import 'progresso_semanal_widget.dart';

class AlunoDashboardScreen extends ConsumerWidget {
  const AlunoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alunoAsync = ref.watch(alunoMeProvider);

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      drawer: alunoAsync.when(
        data: (aluno) => _AlunoDrawer(aluno: aluno, isDark: isDark, ref: ref),
        loading: () => _AlunoDrawerPlaceholder(isDark: isDark),
        error: (_, __) => _AlunoDrawerPlaceholder(isDark: isDark),
      ),
      appBar: AppBar(
        backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: isDark ? EagleTokens.darkInk : EagleTokens.ink),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        title: Text(
          'Meu Treino',
          style: TextStyle(
            color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? EagleTokens.darkInk : EagleTokens.ink),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
            ),
            onPressed: () {
              final currentMode = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state =
                  currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Consumer(
              builder: (context, ref, _) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final brandAsync = ref.watch(personalBrandProvider);
                return brandAsync.maybeWhen(
                  data: (brand) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                        border: Border(
                          bottom: BorderSide(
                            color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: EagleTokens.brand,
                            backgroundImage: brand.logoUrl != null ? NetworkImage(brand.logoUrl!) : null,
                            child: brand.logoUrl == null
                                ? Text(
                                    brand.nomePersonal.isNotEmpty ? brand.nomePersonal[0].toUpperCase() : 'P',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  brand.nomePersonal,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                                  ),
                                ),
                                Text(
                                  'Seu personal',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? EagleTokens.darkInkMute
                                        : EagleTokens.inkMute,
                                  ),
                                ),
                                if (brand.slogan != null && brand.slogan!.isNotEmpty)
                                  Text(
                                    brand.slogan!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                );
              },
            ),
            alunoAsync.when(
              data: (aluno) => _AlunoProfileCard(aluno: aluno, isDark: isDark),
              loading: () => _ProfileCardSkeleton(isDark: isDark),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            const ProgressoSemanalWidget(),
            const SizedBox(height: 24),
            Text(
              'Meus Atalhos',
              style: TextStyle(
                color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.9,
              children: [
                _ShortcutBtn(
                  icon: Icons.fitness_center,
                  label: 'Meus\nTreinos',
                  onTap: () => context.push('/checkin/treinos'),
                  isDark: isDark,
                ),
                _ShortcutBtn(
                  icon: Icons.history,
                  label: 'Meu\nHistórico',
                  onTap: () => context.push('/checkin/historico'),
                  isDark: isDark,
                ),
                _ShortcutBtn(
                  icon: Icons.dynamic_feed,
                  label: 'Feed\ndo Personal',
                  onTap: () => context.push('/feed/aluno'),
                  isDark: isDark,
                ),
                _ShortcutBtn(
                  icon: Icons.chat_bubble_outline,
                  label: 'Falar\ncom Personal',
                  onTap: () => context.push('/chat/aluno'),
                  isDark: isDark,
                ),
                _ShortcutBtn(
                  icon: Icons.smart_toy,
                  label: 'IA\nAssistente',
                  onTap: () => context.push('/ia/chat'),
                  isDark: isDark,
                ),
                _ShortcutBtn(
                  icon: Icons.payments,
                  label: 'Meu\nFinanceiro',
                  onTap: () => context.push('/financeiro/aluno'),
                  isDark: isDark,
                ),
                _ShortcutBtn(
                  icon: Icons.calendar_month,
                  label: 'Minha\nAgenda',
                  onTap: () => context.push('/agenda/aluno'),
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────

class _AlunoProfileCard extends StatelessWidget {
  final Aluno aluno;
  final bool isDark;

  const _AlunoProfileCard({required this.aluno, required this.isDark});

  String _initials(String nome) {
    final parts = nome.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String? _genderLabel(String? genero) {
    if (genero == null) return null;
    switch (genero.toUpperCase()) {
      case 'M':
      case 'MASCULINO':
        return 'Masculino';
      case 'F':
      case 'FEMININO':
        return 'Feminino';
      default:
        return genero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final muteColor = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final cardColor = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final lineColor = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;

    final hasFoto = aluno.fotoUrl != null && aluno.fotoUrl!.isNotEmpty;
    final genderLabel = _genderLabel(aluno.genero);
    final telefone = aluno.telefone ?? aluno.whatsapp;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineColor),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: EagleTokens.brand, width: 2.5),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: EagleTokens.brandSoft,
                backgroundImage: hasFoto ? NetworkImage(aluno.fotoUrl!) : null,
                child: hasFoto
                    ? null
                    : Text(
                        _initials(aluno.nome),
                        style: TextStyle(
                          color: EagleTokens.brand,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aluno.nome,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (aluno.objetivo != null && aluno.objetivo!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      aluno.objetivo!,
                      style: TextStyle(
                        color: EagleTokens.brand,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (genderLabel != null)
                        _Chip(label: genderLabel, isDark: isDark),
                      if (aluno.idade != null)
                        _Chip(
                          label: '${aluno.idade} anos',
                          icon: Icons.cake_outlined,
                          isDark: isDark,
                        ),
                      if (telefone != null && telefone.isNotEmpty)
                        _Chip(
                          label: telefone,
                          icon: Icons.phone_outlined,
                          isDark: isDark,
                        ),
                      if (aluno.tipoConsultoria != null &&
                          aluno.tipoConsultoria!.isNotEmpty)
                        _Chip(label: aluno.tipoConsultoria!, isDark: isDark),
                    ],
                  ),
                ],
              ),
            ),
            // Status dot
            const SizedBox(width: 8),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: aluno.status == 'ATIVO' ? EagleTokens.good : muteColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isDark;

  const _Chip({required this.label, this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? EagleTokens.darkCardHi
        : EagleTokens.brandSofter;
    final fg = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Skeleton while loading ────────────────────────────────────────────────────

class _ProfileCardSkeleton extends StatelessWidget {
  final bool isDark;

  const _ProfileCardSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final shimmer = isDark
        ? EagleTokens.darkCardHi
        : EagleTokens.lineSoft;

    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle, color: shimmer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 14, width: 140, decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 8),
                  Container(height: 10, width: 90, decoration: BoxDecoration(color: shimmer, borderRadius: BorderRadius.circular(6))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────

class _AlunoDrawer extends StatelessWidget {
  final Aluno aluno;
  final bool isDark;
  final WidgetRef ref;

  const _AlunoDrawer({
    required this.aluno,
    required this.isDark,
    required this.ref,
  });

  String _initials(String nome) {
    final parts = nome.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final drawerBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final headerBg = isDark ? EagleTokens.darkCardHi : EagleTokens.brandSoft;
    final textColor = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final dividerColor = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final hasFoto = aluno.fotoUrl != null && aluno.fotoUrl!.isNotEmpty;

    void nav(String route) {
      Navigator.pop(context);
      context.go(route);
    }

    return Drawer(
      backgroundColor: drawerBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            color: headerBg,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: EagleTokens.brand, width: 2.5),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: EagleTokens.brandSoft,
                    backgroundImage: hasFoto ? NetworkImage(aluno.fotoUrl!) : null,
                    child: hasFoto
                        ? null
                        : Text(
                            _initials(aluno.nome),
                            style: TextStyle(
                              color: EagleTokens.brand,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        aluno.nome,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (aluno.objetivo != null && aluno.objetivo!.isNotEmpty)
                        Text(
                          aluno.objetivo!,
                          style: TextStyle(
                            color: EagleTokens.brand,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Nav links ───────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DrawerItem(
                  icon: Icons.fitness_center,
                  label: 'Meus Treinos',
                  isDark: isDark,
                  onTap: () => nav('/checkin/treinos'),
                ),
                _DrawerItem(
                  icon: Icons.calendar_month,
                  label: 'Agenda',
                  isDark: isDark,
                  onTap: () => nav('/agenda/aluno'),
                ),
                _DrawerItem(
                  icon: Icons.history,
                  label: 'Histórico',
                  isDark: isDark,
                  onTap: () => nav('/checkin/historico'),
                ),
                _DrawerItem(
                  icon: Icons.dynamic_feed,
                  label: 'Feed',
                  isDark: isDark,
                  onTap: () => nav('/feed/aluno'),
                ),
                _DrawerItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat com Personal',
                  isDark: isDark,
                  onTap: () => nav('/chat/aluno'),
                ),
                _DrawerItem(
                  icon: Icons.smart_toy,
                  label: 'IA',
                  isDark: isDark,
                  onTap: () => nav('/ia/aluno'),
                ),
                ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: const Text('Deixar Depoimento'),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go('/depoimentos-aluno');
                  },
                ),
                Divider(
                  color: dividerColor,
                  thickness: 1,
                  height: 24,
                  indent: 16,
                  endIndent: 16,
                ),
                // ── Logout ────────────────────────────────────────────────
                ListTile(
                  leading: Icon(Icons.logout, color: EagleTokens.brand, size: 22),
                  title: Text(
                    'Sair',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlunoDrawerPlaceholder extends StatelessWidget {
  final bool isDark;
  const _AlunoDrawerPlaceholder({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    return Drawer(
      backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menu do Aluno',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Carregando dados do perfil...',
                style: TextStyle(
                  color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? EagleTokens.darkInk : EagleTokens.ink;

    return ListTile(
      leading: Icon(icon, color: EagleTokens.brand, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
    );
  }
}

// ── Shortcut Button ─────────────────────────────────────────────────────────────

class _ShortcutBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _ShortcutBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? null : Border.all(color: EagleTokens.line, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark ? const Color(0xFF8DA4E2) : EagleTokens.brand,
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ink,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
