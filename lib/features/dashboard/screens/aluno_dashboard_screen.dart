import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/providers/personal_brand_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../chat/data/chat_repository.dart';
import '../../checkin/providers/checkin_provider.dart';
import '../../checkin/data/checkin_repository.dart';
import '../data/aluno_autonomy_plan.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../../notificacoes/widgets/notificacao_badge_button.dart';
import 'progresso_semanal_widget.dart';

final minhasMedidasDashboardProvider = FutureProvider<List<MedidaCorporal>>((
  ref,
) async {
  final repo = EvolucaoRepository(ref.read(apiClientProvider));
  return repo.listarMinhasMedidas();
});

final chatAlunoDashboardProvider = FutureProvider<List<ChatMsg>>((ref) async {
  final repo = ChatRepository(ref.read(apiClientProvider));
  return repo.historicoAluno();
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
    final historicoAsync = ref.watch(historicoCheckinProvider);
    final chatAsync = ref.watch(chatAlunoDashboardProvider);

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
        elevation: 0,
        title: Text(
          'Meu Treino',
          style: TextStyle(
            color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
        ),
        actions: [
          NotificacaoBadgeButton(isDark: isDark),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
            ),
            onPressed: () {
              final currentMode = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state =
                  currentMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
            },
          ),
          alunoAsync.when(
            data:
                (aluno) => _AlunoAppBarProfileMenu(
                  aluno: aluno,
                  isDark: isDark,
                  onProfile: () => context.push('/aluno/perfil'),
                  onLogout: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
            loading:
                () => const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: CircleAvatar(radius: 17),
                ),
            error: (_, __) => const SizedBox(width: 8),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            treinosAsync.when(
              data:
                  (treinos) => alunoAsync.when(
                    data:
                        (aluno) => _TodayFocusCard(
                          experience: buildAlunoHomeExperience(
                            aluno: aluno,
                            medidas: medidasAsync.valueOrNull ?? const [],
                            treinos: treinos,
                            historico: historicoAsync.valueOrNull ?? const [],
                            mensagens: chatAsync.valueOrNull ?? const [],
                          ),
                          isDark: isDark,
                        ),
                    loading: () => _FocusCardSkeleton(isDark: isDark),
                    error: (_, __) => _FocusCardSkeleton(isDark: isDark),
                  ),
              loading: () => _FocusCardSkeleton(isDark: isDark),
              error: (_, __) => _FocusCardSkeleton(isDark: isDark),
            ),
            const SizedBox(height: 12),
            brandAsync.when(
              data:
                  (brand) => alunoAsync.when(
                    data:
                        (aluno) => _AlunoHeroCard(
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
            const SizedBox(height: 12),
            alunoAsync.when(
              data:
                  (aluno) => _StudentStatsRow(
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
            _PerformanceEvolutionCard(
              historicoAsync: historicoAsync,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            alunoAsync.when(
              data:
                  (aluno) => _StudentJourneyCard(
                    aluno: aluno,
                    treinos: treinosAsync.valueOrNull ?? const [],
                    medidasAsync: medidasAsync,
                    historicoAsync: historicoAsync,
                    chatAsync: chatAsync,
                    isDark: isDark,
                  ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            _StudentToolsSection(isDark: isDark),
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

enum _AlunoHeaderAction { profile, logout }

class _AlunoAppBarProfileMenu extends StatelessWidget {
  final Aluno aluno;
  final bool isDark;
  final VoidCallback onProfile;
  final Future<void> Function() onLogout;

  const _AlunoAppBarProfileMenu({
    required this.aluno,
    required this.isDark,
    required this.onProfile,
    required this.onLogout,
  });

  String _initials(String nome) {
    final parts = nome.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    if (parts.length == 1 || parts[1].isEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hasFoto = aluno.fotoUrl != null && aluno.fotoUrl!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: PopupMenuButton<_AlunoHeaderAction>(
        tooltip: 'Perfil do aluno',
        offset: const Offset(0, 42),
        onSelected: (action) async {
          switch (action) {
            case _AlunoHeaderAction.profile:
              onProfile();
              break;
            case _AlunoHeaderAction.logout:
              await onLogout();
              break;
          }
        },
        itemBuilder:
            (context) => const [
              PopupMenuItem(
                value: _AlunoHeaderAction.profile,
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 10),
                    Text('Perfil'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _AlunoHeaderAction.logout,
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 10),
                    Text('Sair'),
                  ],
                ),
              ),
            ],
        child: CircleAvatar(
          radius: 17,
          backgroundColor: BrandPalette.soft(primary, dark: isDark),
          backgroundImage: hasFoto ? NetworkImage(aluno.fotoUrl!.trim()) : null,
          child:
              hasFoto
                  ? null
                  : Text(
                    _initials(aluno.nome),
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
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
    final slogan =
        brand.slogan?.trim().isNotEmpty == true
            ? brand.slogan!
            : 'Seu treino organizado para hoje.';
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: BrandPalette.soft(primary, dark: isDark),
            backgroundImage:
                brand.logoUrl != null ? NetworkImage(brand.logoUrl!) : null,
            child:
                brand.logoUrl == null
                    ? Text(
                      brand.nomePersonal.isNotEmpty
                          ? brand.nomePersonal[0].toUpperCase()
                          : 'P',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w800,
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
                  'Acompanhamento de $firstName',
                  style: TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  slogan,
                  style: TextStyle(color: mute, fontSize: 12.5, height: 1.35),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: [
                _HeroPill(
                  icon: Icons.person_outline,
                  value: brand.nomePersonal,
                  isDark: isDark,
                ),
                if (aluno.objetivo?.trim().isNotEmpty == true)
                  _HeroPill(
                    icon: Icons.flag_outlined,
                    value: aluno.objetivo!,
                    isDark: isDark,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;

  const _HeroPill({
    required this.icon,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: BrandPalette.soft(primary, dark: isDark),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primary, size: 14),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TodayFocusCard extends StatelessWidget {
  final AlunoHomeExperience experience;
  final bool isDark;

  const _TodayFocusCard({required this.experience, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final action = experience.action;
    final score = experience.score;
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final softText = onPrimary.withValues(alpha: 0.72);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, BrandPalette.deep(primary)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.16 : 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  action.eyebrow,
                  style: TextStyle(
                    color: softText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.verified_outlined, color: softText, size: 18),
              const SizedBox(width: 6),
              Text(
                'Focux ${score.value}',
                style: TextStyle(
                  color: softText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            action.title,
            style: TextStyle(
              color: onPrimary,
              fontSize: 25,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            action.description,
            style: TextStyle(color: softText, fontSize: 13, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed:
                      () =>
                          context.push(action.route, extra: action.routeExtra),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    action.cta,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _WorkoutMetricPill(
                value: '${score.value}',
                label: 'score',
                onPrimary: onPrimary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WorkoutInsightPill(
                icon: Icons.trending_up_rounded,
                label: score.rhythmLabel,
                onPrimary: onPrimary,
              ),
              _WorkoutInsightPill(
                icon: Icons.person_pin_circle_outlined,
                label: score.riskLabel,
                onPrimary: onPrimary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _HomeNarrativeRail(
            items: experience.narratives,
            onPrimary: onPrimary,
          ),
        ],
      ),
    );
  }
}

class _HomeNarrativeRail extends StatelessWidget {
  final List<String> items;
  final Color onPrimary;

  const _HomeNarrativeRail({required this.items, required this.onPrimary});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: onPrimary.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  items[i],
                  style: TextStyle(
                    color: onPrimary.withValues(alpha: 0.78),
                    fontSize: 11.5,
                    height: 1.32,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (i != items.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _WorkoutMetricPill extends StatelessWidget {
  final String value;
  final String label;
  final Color onPrimary;

  const _WorkoutMetricPill({
    required this.value,
    required this.label,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: onPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: onPrimary.withValues(alpha: 0.68),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutInsightPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color onPrimary;

  const _WorkoutInsightPill({
    required this.icon,
    required this.label,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: onPrimary.withValues(alpha: 0.82), size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: onPrimary.withValues(alpha: 0.82),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
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
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : BrandPalette.softer(primary),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, height: 1.15),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
      (
        'Objetivo',
        aluno.objetivo?.trim().isNotEmpty == true ? aluno.objetivo! : 'Definir',
      ),
      (
        'Consultoria',
        aluno.tipoConsultoria?.trim().isNotEmpty == true
            ? aluno.tipoConsultoria!
            : 'Padrão',
      ),
      ('Próximos', '${treinos.length}'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth < 360;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final card in cards)
              SizedBox(
                width:
                    twoColumns
                        ? (constraints.maxWidth - 10) / 2
                        : (constraints.maxWidth - 20) / 3,
                child: _MiniMetricCard(
                  label: card.$1,
                  value: card.$2,
                  isDark: isDark,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PerformanceEvolutionCard extends StatelessWidget {
  final AsyncValue<List<ExecucaoTreino>> historicoAsync;
  final bool isDark;

  const _PerformanceEvolutionCard({
    required this.historicoAsync,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
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
      child: historicoAsync.when(
        loading:
            () => const SizedBox(
              height: 96,
              child: Center(child: CircularProgressIndicator()),
            ),
        error:
            (_, __) => Text(
              'Sua evolução de performance vai aparecer aqui assim que o histórico carregar.',
              style: TextStyle(color: mute, height: 1.45),
            ),
        data: (historico) {
          final treinosConcluidos =
              historico
                  .where((treino) => treino.status == 'CONCLUIDO')
                  .toList();
          final ultimaEvolucao = _ultimaEvolucao(treinosConcluidos);
          final volumeSemana = _volumePeriodo(
            treinosConcluidos,
            _inicioSemana(),
          );
          final volumeMes = _volumePeriodo(treinosConcluidos, _inicioMes());

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: BrandPalette.soft(primary, dark: isDark),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.emoji_events_outlined, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evolução real',
                          style: TextStyle(
                            color: ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ultimaEvolucao == null
                              ? 'Registre as séries para o app enxergar carga, repetições e volume.'
                              : ultimaEvolucao.mensagem,
                          style: TextStyle(color: mute, height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Último PR',
                      value:
                          ultimaEvolucao == null
                              ? '--'
                              : _labelEvolucao(ultimaEvolucao.tipo),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Volume semana',
                      value: _fmtVolume(volumeSemana),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniMetricCard(
                      label: 'Volume mês',
                      value: _fmtVolume(volumeMes),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              if (ultimaEvolucao != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : BrandPalette.softer(primary),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${ultimaEvolucao.exercicioNome}: ${_fmtValor(ultimaEvolucao.valorAnterior, ultimaEvolucao.unidade)} -> ${_fmtValor(ultimaEvolucao.valorAtual, ultimaEvolucao.unidade)}'
                    '${ultimaEvolucao.percentual == null ? '' : ' (+${ultimaEvolucao.percentual}%)'}',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  EvolucaoPerformance? _ultimaEvolucao(List<ExecucaoTreino> historico) {
    for (final treino in historico) {
      if (treino.evolucoesPerformance.isNotEmpty) {
        return treino.evolucoesPerformance.first;
      }
      if (treino.evolucoesCarga.isNotEmpty) {
        final item = treino.evolucoesCarga.first;
        return EvolucaoPerformance(
          tipo: 'CARGA',
          exercicioId: item.exercicioId,
          exercicioNome: item.exercicioNome,
          valorAnterior: item.cargaAnteriorKg,
          valorAtual: item.cargaAtualKg,
          diferenca: item.diferencaKg,
          percentual: item.percentual,
          unidade: 'kg',
          mensagem: item.mensagem,
        );
      }
    }
    return null;
  }

  double _volumePeriodo(List<ExecucaoTreino> historico, DateTime inicio) {
    return historico
        .where((treino) {
          final data = _dataTreino(treino);
          return data != null && !data.isBefore(inicio);
        })
        .fold<double>(0, (total, treino) => total + _volumeTreino(treino));
  }

  double _volumeTreino(ExecucaoTreino treino) {
    var total = 0.0;
    for (final exercicio in treino.exercicios) {
      for (final serie in exercicio.seriesDetalhes) {
        final reps = _primeiroNumero(serie.repeticoes);
        final carga = serie.cargaKg;
        if (reps != null && carga != null) {
          total += carga * reps;
        }
      }
    }
    return total;
  }

  DateTime? _dataTreino(ExecucaoTreino treino) {
    return DateTime.tryParse(treino.concluidoEm ?? treino.iniciadoEm ?? '');
  }

  DateTime _inicioSemana() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(start.year, start.month, start.day);
  }

  DateTime _inicioMes() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  int? _primeiroNumero(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final match = RegExp(r'\d+').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  String _labelEvolucao(String tipo) {
    switch (tipo) {
      case 'REPETICOES':
        return 'Repetições';
      case 'VOLUME':
        return 'Volume';
      default:
        return 'Carga';
    }
  }

  String _fmtVolume(double value) {
    if (value <= 0) return '--';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}t';
    return '${value.toStringAsFixed(0)}kg';
  }

  String _fmtValor(double value, String unidade) {
    final formatted =
        value == value.roundToDouble()
            ? value.toStringAsFixed(0)
            : value.toStringAsFixed(1);
    if (unidade.isEmpty) return formatted;
    return '$formatted $unidade';
  }
}

class _StudentJourneyCard extends ConsumerStatefulWidget {
  final Aluno aluno;
  final List<ExecucaoTreino> treinos;
  final AsyncValue<List<MedidaCorporal>> medidasAsync;
  final AsyncValue<List<ExecucaoTreino>> historicoAsync;
  final AsyncValue<List<ChatMsg>> chatAsync;
  final bool isDark;

  const _StudentJourneyCard({
    required this.aluno,
    required this.treinos,
    required this.medidasAsync,
    required this.historicoAsync,
    required this.chatAsync,
    required this.isDark,
  });

  @override
  ConsumerState<_StudentJourneyCard> createState() =>
      _StudentJourneyCardState();
}

class _StudentJourneyCardState extends ConsumerState<_StudentJourneyCard> {
  final Set<String> _trackedSessionEvents = {};

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = widget.isDark ? EagleTokens.darkCard : EagleTokens.card;
    final line = widget.isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
    final ink = widget.isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = widget.isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    final medidas = widget.medidasAsync.valueOrNull ?? const <MedidaCorporal>[];
    final historico =
        widget.historicoAsync.valueOrNull ?? const <ExecucaoTreino>[];
    final mensagens = widget.chatAsync.valueOrNull ?? const <ChatMsg>[];

    final plan = buildAlunoAutonomyPlan(
      aluno: widget.aluno,
      medidas: medidas,
      treinos: widget.treinos,
      historico: historico,
      mensagens: mensagens,
    );
    final nextTask = plan.nextTask;
    final visibleTasks = [if (nextTask != null) nextTask];
    _trackVisibleTasks(visibleTasks, plan.profileCompletion);

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
                      'Central do aluno',
                      style: TextStyle(
                        color: ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pendências e próximos passos para você evoluir sem depender de cobrança do personal.',
                      style: TextStyle(color: mute, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: widget.isDark),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${plan.progress}%',
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value:
                  plan.tasks.isEmpty ? 1 : plan.doneCount / plan.tasks.length,
              minHeight: 9,
              backgroundColor: BrandPalette.soft(primary, dark: widget.isDark),
              valueColor: AlwaysStoppedAnimation(primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${plan.doneCount} de ${plan.tasks.length} pendências fechadas. Perfil ${plan.profileCompletion}%.',
            style: TextStyle(
              color: mute,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  widget.isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : BrandPalette.softer(primary),
              borderRadius: BorderRadius.circular(16),
            ),
            child: _NextBestTaskPanel(
              task: nextTask,
              isDark: widget.isDark,
              onTap: nextTask == null ? null : () => _openTask(nextTask),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  () => _showAlunoPlanSheet(
                    context,
                    isDark: widget.isDark,
                    primary: primary,
                    plan: plan,
                    onOpenTask: _openTask,
                  ),
              icon: const Icon(Icons.view_agenda_outlined, size: 17),
              label: Text(
                plan.tasks.isEmpty
                    ? 'Ver plano completo'
                    : 'Ver plano completo (${plan.tasks.length})',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _trackVisibleTasks(
    List<AlunoAutonomyTask> tasks,
    int profileCompletion,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final task in tasks) {
        _trackTask(task, 'VIEWED', profileCompletion);
        if (task.done) {
          _trackTask(task, 'COMPLETED', profileCompletion);
        }
      }
    });
  }

  void _openTask(AlunoAutonomyTask task) {
    _trackTask(task, 'CLICKED', null);
    context.push(task.route);
  }

  void _trackTask(
    AlunoAutonomyTask task,
    String action,
    int? profileCompletion,
  ) {
    final sessionKey = '$action:${task.id}:${task.done}';
    if (action != 'CLICKED' && !_trackedSessionEvents.add(sessionKey)) {
      return;
    }
    final eventName = switch (action) {
      'CLICKED' => ProductEvents.alunoAutonomyTaskClicked,
      'COMPLETED' => ProductEvents.alunoAutonomyTaskCompleted,
      _ => ProductEvents.alunoAutonomyTaskViewed,
    };
    final props = {
      'taskId': task.id,
      'taskTitle': task.title,
      'route': task.route,
      'priority': task.priority.name,
      'done': task.done,
      if (profileCompletion != null) 'profileCompletion': profileCompletion,
    };
    unawaited(AnalyticsService.instance.track(eventName, props: props));
    unawaited(
      ref
          .read(alunoRepositoryProvider)
          .registrarEventoAutonomia(
            taskId: task.id,
            taskTitle: task.title,
            action: action,
            route: task.route,
            priority: task.priority.name.toUpperCase(),
            done: task.done,
            profileCompletion: profileCompletion,
          )
          .catchError((_) {}),
    );
  }
}

void _showAlunoPlanSheet(
  BuildContext context, {
  required bool isDark,
  required Color primary,
  required AlunoAutonomyPlan plan,
  required void Function(AlunoAutonomyTask task) onOpenTask,
}) {
  final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
  final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
  final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
  final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: isDark ? 0.56 : 0.24),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final media = MediaQuery.of(sheetContext);
      return Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, media.viewPadding.bottom + 10),
        child: Container(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.76),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.12),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: BrandPalette.soft(primary, dark: isDark),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(Icons.route_outlined, size: 18, color: primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plano do aluno',
                          style: TextStyle(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.45,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${plan.doneCount} de ${plan.tasks.length} passos fechados.',
                          style: TextStyle(
                            color: mute,
                            fontSize: 12.2,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close_rounded, size: 18, color: mute),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value:
                      plan.tasks.isEmpty
                          ? 1
                          : plan.doneCount / plan.tasks.length,
                  minHeight: 8,
                  backgroundColor: BrandPalette.soft(primary, dark: isDark),
                  valueColor: AlwaysStoppedAnimation(primary),
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: plan.tasks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (_, index) {
                    final task = plan.tasks[index];
                    return _AutonomyTaskTile(
                      task: task,
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        onOpenTask(task);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _NextBestTaskPanel extends StatelessWidget {
  final AlunoAutonomyTask? task;
  final bool isDark;
  final VoidCallback? onTap;

  const _NextBestTaskPanel({
    required this.task,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final icon = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: BrandPalette.soft(primary, dark: isDark),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(_alunoTaskIcon(task?.kind), color: primary),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task == null ? 'Tudo em dia' : 'Próximo melhor passo',
          style: TextStyle(
            color: mute,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          task == null
              ? 'Sua rotina está organizada. Continue acompanhando treino, medidas e agenda.'
              : task!.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        if (task != null) ...[
          const SizedBox(height: 5),
          Text(
            task!.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: mute, fontSize: 12, height: 1.3),
          ),
        ],
      ],
    );
    final action =
        task == null
            ? null
            : FilledButton.tonal(
              onPressed: onTap,
              child: Text(task!.cta, overflow: TextOverflow.ellipsis),
            );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 390;
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Expanded(child: copy),
                ],
              ),
              if (action != null) ...[
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: action),
              ],
            ],
          );
        }

        return Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(child: copy),
            if (action != null) ...[
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 144),
                child: action,
              ),
            ],
          ],
        );
      },
    );
  }
}

IconData _alunoTaskIcon(AlunoTaskKind? kind) {
  switch (kind) {
    case AlunoTaskKind.perfil:
      return Icons.person_outline;
    case AlunoTaskKind.fotoDados:
      return Icons.add_a_photo_outlined;
    case AlunoTaskKind.medida:
      return Icons.straighten_outlined;
    case AlunoTaskKind.treino:
      return Icons.play_circle_outline;
    case AlunoTaskKind.chat:
      return Icons.chat_bubble_outline;
    case AlunoTaskKind.agenda:
      return Icons.calendar_month_outlined;
    case AlunoTaskKind.financeiro:
      return Icons.payments_outlined;
    case null:
      return Icons.check_circle_outline;
  }
}

class _AutonomyTaskTile extends StatelessWidget {
  final AlunoAutonomyTask task;
  final bool isDark;
  final VoidCallback onTap;

  const _AutonomyTaskTile({
    required this.task,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    final icon = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color:
            task.done
                ? EagleTokens.good.withValues(alpha: 0.14)
                : BrandPalette.soft(primary, dark: isDark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        task.done ? Icons.check_rounded : _alunoTaskIcon(task.kind),
        color: task.done ? EagleTokens.good : primary,
        size: 20,
      ),
    );
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          task.description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: mute, fontSize: 12.5, height: 1.4),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            _AutonomyTaskPill(
              label: _taskPriorityLabel(task.priority),
              color: _taskPriorityColor(task.priority, primary),
            ),
            _AutonomyTaskPill(
              label: task.done ? 'Sem ação agora' : _taskHint(task.kind),
              color: task.done ? EagleTokens.good : mute,
            ),
          ],
        ),
      ],
    );
    final action =
        task.done
            ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: EagleTokens.good.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Feito',
                style: TextStyle(
                  color: EagleTokens.good,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
            : TextButton(
              onPressed: onTap,
              child: Text(task.cta, overflow: TextOverflow.ellipsis),
            );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? EagleTokens.darkBg : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
            ),
          ),
          child:
              compact
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          icon,
                          const SizedBox(width: 12),
                          Expanded(child: copy),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: action,
                        ),
                      ),
                    ],
                  )
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Expanded(child: copy),
                      const SizedBox(width: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 132),
                        child: action,
                      ),
                    ],
                  ),
        );
      },
    );
  }
}

class _AutonomyTaskPill extends StatelessWidget {
  final String label;
  final Color color;

  const _AutonomyTaskPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _taskPriorityLabel(AlunoTaskPriority priority) {
  return switch (priority) {
    AlunoTaskPriority.alta => 'Prioridade alta',
    AlunoTaskPriority.media => 'Prioridade média',
    AlunoTaskPriority.baixa => 'Opcional',
  };
}

Color _taskPriorityColor(AlunoTaskPriority priority, Color primary) {
  return switch (priority) {
    AlunoTaskPriority.alta => EagleTokens.warn,
    AlunoTaskPriority.media => primary,
    AlunoTaskPriority.baixa => const Color(0xFF64748B),
  };
}

String _taskHint(AlunoTaskKind kind) {
  return switch (kind) {
    AlunoTaskKind.perfil => 'Atualize seus dados',
    AlunoTaskKind.fotoDados => 'Foto e medidas',
    AlunoTaskKind.medida => 'Registrar progresso',
    AlunoTaskKind.treino => 'Mover treino',
    AlunoTaskKind.chat => 'Chamar personal',
    AlunoTaskKind.agenda => 'Conferir horário',
    AlunoTaskKind.financeiro => 'Ver financeiro',
  };
}

class _StudentToolsSection extends StatelessWidget {
  final bool isDark;

  const _StudentToolsSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final tools = [
      _StudentToolAction(
        icon: Icons.fitness_center,
        title: 'Treinos',
        subtitle: 'Check-ins e histórico',
        route: '/checkin/treinos',
        emphasis: true,
      ),
      _StudentToolAction(
        icon: Icons.chat_bubble_outline,
        title: 'Personal',
        subtitle: 'Chat direto',
        route: '/chat/aluno',
      ),
      _StudentToolAction(
        icon: Icons.trending_up_rounded,
        title: 'Evolução',
        subtitle: 'Medidas e saúde',
        route: '/checkin/historico',
      ),
      _StudentToolAction(
        icon: Icons.smart_toy_outlined,
        title: 'IA',
        subtitle: 'Rotina guiada',
        route: '/ia/aluno',
      ),
      _StudentToolAction(
        icon: Icons.payments_outlined,
        title: 'Financeiro',
        subtitle: 'Pagamentos',
        route: '/financeiro/aluno',
      ),
      _StudentToolAction(
        icon: Icons.calendar_month_outlined,
        title: 'Agenda',
        subtitle: 'Horários',
        route: '/agenda/aluno',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: line),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF0B1220).withValues(alpha: 0.045),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
        ],
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
                      'Ferramentas',
                      style: TextStyle(
                        color: ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Acesso rápido ao que importa.',
                      style: TextStyle(color: mute, fontSize: 12.2),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: isDark),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${tools.length} atalhos',
                  style: TextStyle(
                    color: primary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              final compact = constraints.maxWidth < 270;
              final itemWidth =
                  compact
                      ? constraints.maxWidth
                      : (constraints.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final tool in tools)
                    SizedBox(
                      width: itemWidth,
                      child: _StudentToolTile(
                        action: tool,
                        isDark: isDark,
                        primary: primary,
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

class _StudentToolAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final bool emphasis;

  const _StudentToolAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.emphasis = false,
  });
}

class _StudentToolTile extends StatelessWidget {
  final _StudentToolAction action;
  final bool isDark;
  final Color primary;

  const _StudentToolTile({
    required this.action,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final bg =
        action.emphasis
            ? primary.withValues(alpha: isDark ? 0.18 : 0.075)
            : isDark
            ? EagleTokens.darkBg
            : const Color(0xFFF8FAFC);
    final border =
        action.emphasis
            ? primary.withValues(alpha: 0.16)
            : isDark
            ? EagleTokens.darkLine
            : EagleTokens.lineSoft;

    return InkWell(
      onTap: () => context.push(action.route),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 66),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: BrandPalette.soft(primary, dark: isDark),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(action.icon, color: primary, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    action.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: mute, fontSize: 10.7, height: 1.1),
                  ),
                ],
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
    final primary = Theme.of(context).colorScheme.primary;
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
            color:
                isDark
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
                border: Border.all(color: primary, width: 2.5),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: BrandPalette.soft(primary, dark: false),
                backgroundImage: hasFoto ? NetworkImage(aluno.fotoUrl!) : null,
                child:
                    hasFoto
                        ? null
                        : Text(
                          _initials(aluno.nome),
                          style: TextStyle(
                            color: primary,
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
                        color: primary,
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
    final primary = Theme.of(context).colorScheme.primary;
    final bg = isDark ? EagleTokens.darkCardHi : BrandPalette.softer(primary);
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
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
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
    final shimmer = isDark ? EagleTokens.darkCardHi : EagleTokens.lineSoft;

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
                  Container(
                    height: 14,
                    width: 140,
                    decoration: BoxDecoration(
                      color: shimmer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 90,
                    decoration: BoxDecoration(
                      color: shimmer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
