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
    final proximoTreino = _heroProximoTreino(treinosAsync.valueOrNull);

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
          IconButton(
            icon: Icon(
              Icons.logout,
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
            ),
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
              data:
                  (brand) => alunoAsync.when(
                    data:
                        (aluno) => _AlunoHeroCard(
                          aluno: aluno,
                          brand: brand,
                          isDark: isDark,
                          proximoTreino: proximoTreino,
                        ),
                    loading: () => _HeroCardSkeleton(isDark: isDark),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
              loading: () => _HeroCardSkeleton(isDark: isDark),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            treinosAsync.when(
              data:
                  (treinos) => alunoAsync.when(
                    data:
                        (aluno) => _TodayFocusCard(
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
                  (aluno) => _ProgressCheckpointCard(
                    aluno: aluno,
                    medidasAsync: medidasAsync,
                    isDark: isDark,
                  ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
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
            Text(
              'Ações rápidas',
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
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 10.0;
                final btnWidth = (constraints.maxWidth - spacing * 2) / 3;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _ShortcutBtn(
                      icon: Icons.fitness_center,
                      label: 'Meus\nTreinos',
                      onTap: () => context.push('/checkin/treinos'),
                      isDark: isDark,
                      width: btnWidth,
                    ),
                    _ShortcutBtn(
                      icon: Icons.history,
                      label: 'Meu\nHistorico',
                      onTap: () => context.push('/checkin/historico'),
                      isDark: isDark,
                      width: btnWidth,
                    ),
                    _ShortcutBtn(
                      icon: Icons.dynamic_feed,
                      label: 'Feed\ndo Personal',
                      onTap: () => context.push('/feed/aluno'),
                      isDark: isDark,
                      width: btnWidth,
                    ),
                    _ShortcutBtn(
                      icon: Icons.chat_bubble_outline,
                      label: 'Falar\ncom Personal',
                      onTap: () => context.push('/chat/aluno'),
                      isDark: isDark,
                      width: btnWidth,
                    ),
                    _ShortcutBtn(
                      icon: Icons.smart_toy,
                      label: 'IA\nAssistente',
                      onTap: () => context.push('/ia/aluno'),
                      isDark: isDark,
                      width: btnWidth,
                    ),
                    _ShortcutBtn(
                      icon: Icons.payments,
                      label: 'Meu\nFinanceiro',
                      onTap: () => context.push('/financeiro/aluno'),
                      isDark: isDark,
                      width: btnWidth,
                    ),
                    _ShortcutBtn(
                      icon: Icons.calendar_month,
                      label: 'Minha\nAgenda',
                      onTap: () => context.push('/agenda/aluno'),
                      isDark: isDark,
                      width: btnWidth,
                    ),
                  ],
                );
              },
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

String? _heroProximoTreino(List<ExecucaoTreino>? treinos) {
  if (treinos == null || treinos.isEmpty) return null;
  final nome = treinos.first.treinoNome.trim();
  if (nome.isEmpty) return null;
  return 'Próximo treino: $nome';
}

// ── Profile Card ──────────────────────────────────────────────────────────────

class _AlunoHeroCard extends StatelessWidget {
  final Aluno aluno;
  final PersonalBrand brand;
  final bool isDark;
  final String? proximoTreino;

  const _AlunoHeroCard({
    required this.aluno,
    required this.brand,
    required this.isDark,
    this.proximoTreino,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = aluno.nome.split(' ').first;
    final slogan =
        brand.slogan?.trim().isNotEmpty == true
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
            BrandPalette.deep(Theme.of(context).colorScheme.primary),
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
                child:
                    brand.logoUrl == null
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
                      'Olá, $firstName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _HeroSubtitle(
                      streakDias: null,
                      proximoTreino: proximoTreino,
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

class _HeroSubtitle extends StatelessWidget {
  const _HeroSubtitle({this.streakDias, this.proximoTreino});

  final int? streakDias;
  final String? proximoTreino;

  @override
  Widget build(BuildContext context) {
    if (streakDias != null && streakDias! > 1) {
      return Text(
        '$streakDias dias seguidos',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.85),
        ),
      );
    }
    if (proximoTreino != null) {
      return Text(
        proximoTreino!,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white.withValues(alpha: 0.85),
        ),
      );
    }
    return const SizedBox.shrink();
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
                style: const TextStyle(color: Colors.white70, fontSize: 11),
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
    final completedFields =
        [
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
              onTap:
                  () => context.push('/checkin/executar', extra: next.treinoId),
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
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrandPalette.soft(primary, dark: false),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, height: 1.15),
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
            : 'Padrao',
      ),
      ('Proximos', '${treinos.length}'),
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
              'Sua evolucao de performance vai aparecer aqui assim que o historico carregar.',
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
                          'Evolucao real',
                          style: TextStyle(
                            color: ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ultimaEvolucao == null
                              ? 'Registre as series para o app enxergar carga, repeticoes e volume.'
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
                      label: 'Ultimo PR',
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
                      label: 'Volume mes',
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
        return 'Repeticoes';
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
    final filled =
        [
              aluno.telefone,
              aluno.whatsapp,
              aluno.objetivo,
              aluno.genero,
              aluno.peso?.toString(),
              aluno.altura?.toString(),
              aluno.dataNascimento,
              aluno.fotoUrl,
            ]
            .where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
            .length;
    return (filled / 8 * 100).round();
  }

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
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Abrir'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          medidasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:
                (_, __) => Text(
                  'Seu progresso corporal vai aparecer aqui assim que o app conseguir buscar as medidas.',
                  style: TextStyle(color: mute, height: 1.45),
                ),
            data: (medidas) {
              final ultima = medidas.isNotEmpty ? medidas.first : null;
              final pesos =
                  medidas.where((item) => item.peso != null).toList()
                    ..sort((a, b) => a.data.compareTo(b.data));
              final diff =
                  pesos.length >= 2
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
                          value:
                              ultima?.peso != null
                                  ? '${ultima!.peso!.toStringAsFixed(1)} kg'
                                  : 'Sem peso',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MiniMetricCard(
                          label: 'Variacao',
                          value:
                              diff == null
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
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : BrandPalette.softer(primary),
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
    final visibleTasks = [
      if (nextTask != null) nextTask,
      ...plan.tasks.where((task) => task.id != nextTask?.id).take(5),
    ];
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
          const SizedBox(height: 14),
          for (var i = 0; i < visibleTasks.length; i++) ...[
            _AutonomyTaskTile(
              task: visibleTasks[i],
              isDark: widget.isDark,
              onTap: () => _openTask(visibleTasks[i]),
            ),
            if (i != visibleTasks.length - 1) const SizedBox(height: 10),
          ],
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
          task == null ? 'Tudo em dia' : 'Proximo melhor passo',
          style: TextStyle(
            color: mute,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          task == null
              ? 'Sua rotina esta organizada. Continue acompanhando treino, medidas e agenda.'
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
              label: task.done ? 'Sem acao agora' : _taskHint(task.kind),
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
    AlunoTaskPriority.media => 'Prioridade media',
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
    AlunoTaskKind.agenda => 'Conferir horario',
    AlunoTaskKind.financeiro => 'Ver financeiro',
  };
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
    final primary = Theme.of(context).colorScheme.primary;
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
            Icon(icon, color: primary, size: 18),
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

// ── Shortcut Button ─────────────────────────────────────────────────────────────

class _ShortcutBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final double width;

  const _ShortcutBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;

    return SizedBox(
      width: width,
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isDark ? BrandPalette.accent(primary) : primary,
                ),
                const SizedBox(height: 10),
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
        ),
      ),
    );
  }
}
