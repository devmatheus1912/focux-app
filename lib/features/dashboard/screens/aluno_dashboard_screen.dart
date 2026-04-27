import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/personal_brand_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../checkin/providers/checkin_provider.dart';
import '../../checkin/data/checkin_repository.dart';
import '../../evolucao/data/evolucao_repository.dart';
import 'progresso_semanal_widget.dart';

final minhasMedidasDashboardProvider =
    FutureProvider<List<MedidaCorporal>>((ref) async {
  final repo = EvolucaoRepository(ref.read(apiClientProvider));
  return repo.listarMinhasMedidas();
});

class AlunoDashboardScreen extends ConsumerWidget {
  const AlunoDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alunoAsync = ref.watch(alunoMeProvider);
    final brandAsync = ref.watch(personalBrandProvider);
    final treinosAsync = ref.watch(meusTreinosProvider);
    final medidasAsync = ref.watch(minhasMedidasDashboardProvider);

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
            brandAsync.when(
              data: (brand) => alunoAsync.when(
                data: (aluno) => _AlunoHeroCard(
                  aluno: aluno,
                  brand: brand,
                  isDark: isDark,
                ),
                loading: () => _HeroCardSkeleton(isDark: isDark),
                error: (_, __) => const SizedBox.shrink(),
              ),
              loading: () => _HeroCardSkeleton(isDark: isDark),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            treinosAsync.when(
              data: (treinos) => alunoAsync.when(
                data: (aluno) => _TodayFocusCard(
                  aluno: aluno,
                  treinos: treinos,
                  isDark: isDark,
                ),
                loading: () => _FocusCardSkeleton(isDark: isDark),
                error: (_, __) => _FocusCardSkeleton(isDark: isDark),
              ),
              loading: () => _FocusCardSkeleton(isDark: isDark),
              error: (_, __) => _FocusCardSkeleton(isDark: isDark),
            ),
            const SizedBox(height: 16),
            alunoAsync.when(
              data: (aluno) => _StudentStatsRow(
                aluno: aluno,
                treinos: treinosAsync.valueOrNull ?? const [],
                isDark: isDark,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            const ProgressoSemanalWidget(),
            const SizedBox(height: 16),
            alunoAsync.when(
              data: (aluno) => _ProgressCheckpointCard(
                aluno: aluno,
                medidasAsync: medidasAsync,
                isDark: isDark,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text(
              'Acoes rapidas',
              style: TextStyle(
                color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _QuickActionStrip(isDark: isDark),
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
            const SizedBox(height: 20),
            alunoAsync.when(
              data: (aluno) => _AlunoProfileCard(aluno: aluno, isDark: isDark),
              loading: () => _ProfileCardSkeleton(isDark: isDark),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────

class _AlunoHeroCard extends StatelessWidget {
  final Aluno aluno;
  final PersonalBrand brand;
  final bool isDark;

  const _AlunoHeroCard({
    required this.aluno,
    required this.brand,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = aluno.nome.split(' ').first;
    final slogan = brand.slogan?.trim().isNotEmpty == true
        ? brand.slogan!
        : 'Seu treino organizado para hoje.';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                backgroundImage:
                    brand.logoUrl != null ? NetworkImage(brand.logoUrl!) : null,
                child: brand.logoUrl == null
                    ? Text(
                        brand.nomePersonal.isNotEmpty
                            ? brand.nomePersonal[0].toUpperCase()
                            : 'P',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ola, $firstName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slogan,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.45,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(
                icon: Icons.person_outline,
                label: 'Seu personal',
                value: brand.nomePersonal,
              ),
              if (aluno.objetivo?.trim().isNotEmpty == true)
                _HeroPill(
                  icon: Icons.flag_outlined,
                  label: 'Foco atual',
                  value: aluno.objetivo!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayFocusCard extends StatelessWidget {
  final Aluno aluno;
  final List<ExecucaoTreino> treinos;
  final bool isDark;

  const _TodayFocusCard({
    required this.aluno,
    required this.treinos,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final next = treinos.isEmpty ? null : treinos.first;
    final completedFields = [
      aluno.telefone,
      aluno.whatsapp,
      aluno.objetivo,
      aluno.genero,
      aluno.peso?.toString(),
      aluno.altura?.toString(),
      aluno.dataNascimento,
      aluno.fotoUrl,
    ].where((e) => e != null && e.toString().trim().isNotEmpty).length;
    final profileCompletion = (completedFields / 8 * 100).round();
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hoje',
            style: TextStyle(
              color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            next != null
                ? 'Seu proximo passo esta pronto: ${next.treinoNome}.'
                : 'Seu personal ainda nao liberou um treino para hoje.',
            style: TextStyle(color: mute, height: 1.5),
          ),
          const SizedBox(height: 16),
          if (next != null)
            _PrimaryActionCard(
              title: next.treinoNome,
              subtitle:
                  '${next.exercicios.length} exercicios para seguir seu plano com clareza.',
              cta: 'Treinar agora',
              onTap: () => context.push('/checkin/executar', extra: next.treinoId),
            )
          else
            _PrimaryActionCard(
              title: 'Perfil e acompanhamento',
              subtitle:
                  'Enquanto o treino nao chega, deixe seu perfil completo para melhorar os proximos ajustes.',
              cta: 'Completar perfil',
              onTap: () => context.push('/aluno/perfil'),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniMetricCard(
                  label: 'Perfil',
                  value: '$profileCompletion%',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniMetricCard(
                  label: 'Treinos ativos',
                  value: '${treinos.length}',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onTap;

  const _PrimaryActionCard({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EagleTokens.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(height: 1.45)),
          const SizedBox(height: 12),
          FilledButton(onPressed: onTap, child: Text(cta)),
        ],
      ),
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MiniMetricCard({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.brandSofter,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _StudentStatsRow extends StatelessWidget {
  final Aluno aluno;
  final List<ExecucaoTreino> treinos;
  final bool isDark;

  const _StudentStatsRow({
    required this.aluno,
    required this.treinos,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Objetivo', aluno.objetivo?.trim().isNotEmpty == true ? aluno.objetivo! : 'Definir'),
      ('Consultoria', aluno.tipoConsultoria?.trim().isNotEmpty == true ? aluno.tipoConsultoria! : 'Padrao'),
      ('Proximos', '${treinos.length}'),
    ];

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(
            child: _MiniMetricCard(
              label: cards[i].$1,
              value: cards[i].$2,
              isDark: isDark,
            ),
          ),
          if (i != cards.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _ProgressCheckpointCard extends StatelessWidget {
  final Aluno aluno;
  final AsyncValue<List<MedidaCorporal>> medidasAsync;
  final bool isDark;

  const _ProgressCheckpointCard({
    required this.aluno,
    required this.medidasAsync,
    required this.isDark,
  });

  String _formatarData(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final dia = parsed.day.toString().padLeft(2, '0');
    final mes = parsed.month.toString().padLeft(2, '0');
    return '$dia/$mes';
  }

  int _profileCompletion() {
    final filled = [
      aluno.telefone,
      aluno.whatsapp,
      aluno.objetivo,
      aluno.genero,
      aluno.peso?.toString(),
      aluno.altura?.toString(),
      aluno.dataNascimento,
      aluno.fotoUrl,
    ].where((value) => value != null && value.toString().trim().isNotEmpty).length;
    return (filled / 8 * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
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
                      'Checkpoint pessoal',
                      style: TextStyle(
                        color: ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Veja seu progresso e ajuste o que falta sem esperar o personal chamar.',
                      style: TextStyle(color: mute, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: () => context.push('/aluno/perfil'),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Abrir'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          medidasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(
              'Seu progresso corporal vai aparecer aqui assim que o app conseguir buscar as medidas.',
              style: TextStyle(color: mute, height: 1.45),
            ),
            data: (medidas) {
              final ultima = medidas.isNotEmpty ? medidas.first : null;
              final pesos = medidas.where((item) => item.peso != null).toList()
                ..sort((a, b) => a.data.compareTo(b.data));
              final diff = pesos.length >= 2
                  ? pesos.last.peso! - pesos.first.peso!
                  : null;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MiniMetricCard(
                          label: 'Perfil',
                          value: '${_profileCompletion()}%',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniMetricCard(
                          label: 'Ultimo peso',
                          value: ultima?.peso != null
                              ? '${ultima!.peso!.toStringAsFixed(1)} kg'
                              : 'Sem peso',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniMetricCard(
                          label: 'Variacao',
                          value: diff == null
                              ? '--'
                              : '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : EagleTokens.brand.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      ultima == null
                          ? 'Seu historico corporal ainda esta vazio. Registrar uma medida agora melhora os proximos ajustes do treino.'
                          : 'Ultima atualizacao em ${_formatarData(ultima.data)}${ultima.fotoUrl != null && ultima.fotoUrl!.isNotEmpty ? ' com foto de progresso.' : '.'}',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickActionStrip extends StatelessWidget {
  final bool isDark;

  const _QuickActionStrip({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InlineActionButton(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            onTap: () => context.push('/chat/aluno'),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InlineActionButton(
            icon: Icons.person_outline,
            label: 'Perfil',
            onTap: () => context.push('/aluno/perfil'),
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InlineActionButton(
            icon: Icons.smart_toy_outlined,
            label: 'IA',
            onTap: () => context.push('/ia/aluno'),
            isDark: isDark,
          ),
        ),
      ],
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _InlineActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.darkCard : EagleTokens.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: EagleTokens.brand, size: 18),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCardSkeleton extends StatelessWidget {
  final bool isDark;

  const _HeroCardSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final shimmer = isDark ? EagleTokens.darkCardHi : EagleTokens.lineSoft;
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: shimmer,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _FocusCardSkeleton extends StatelessWidget {
  final bool isDark;

  const _FocusCardSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final shimmer = isDark ? EagleTokens.darkCard : EagleTokens.lineSoft;
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: shimmer,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

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
                  icon: Icons.person_outline,
                  label: 'Meu Perfil',
                  isDark: isDark,
                  onTap: () => nav('/aluno/perfil'),
                ),
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
          border: Border.all(color: isDark ? EagleTokens.darkLine : EagleTokens.line, width: 1),
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
