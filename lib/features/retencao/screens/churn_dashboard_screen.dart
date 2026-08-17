import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../features/alunos/utils/alunos_list_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../data/retencao_repository.dart';

final retencaoRepositoryProvider = Provider(
  (ref) => RetencaoRepository(ref.read(apiClientProvider)),
);

String _riscoLabel(String risco) => switch (risco.trim().toUpperCase()) {
  'ALTO' => 'Risco alto',
  'MEDIO' || 'MÉDIO' => 'Risco médio',
  'BAIXO' => 'Saudável',
  _ => risco,
};

int _riscoSortOrder(String risco) => switch (risco.trim().toUpperCase()) {
  'ALTO' => 0,
  'MEDIO' || 'MÉDIO' => 1,
  'BAIXO' => 2,
  _ => 3,
};

List<RetencaoAlunoScore> _sortedScores(List<RetencaoAlunoScore> scores) {
  final copy = List<RetencaoAlunoScore>.from(scores);
  copy.sort((a, b) {
    final risk = _riscoSortOrder(
      a.riscoChurn,
    ).compareTo(_riscoSortOrder(b.riscoChurn));
    if (risk != 0) return risk;
    return b.scoreAtual.compareTo(a.scoreAtual);
  });
  return copy;
}

class ChurnDashboardScreen extends ConsumerStatefulWidget {
  const ChurnDashboardScreen({super.key});

  @override
  ConsumerState<ChurnDashboardScreen> createState() =>
      _ChurnDashboardScreenState();
}

class _ChurnDashboardScreenState extends ConsumerState<ChurnDashboardScreen> {
  List<RetencaoAlunoScore> _scores = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref.read(retencaoRepositoryProvider).listarBase();
      if (!mounted) return;
      setState(() {
        _scores = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final sorted = _sortedScores(_scores);
    final alto =
        _scores.where((s) => s.riscoChurn.toUpperCase() == 'ALTO').length;
    final medio =
        _scores.where((s) {
          final r = s.riscoChurn.toUpperCase();
          return r == 'MEDIO' || r == 'MÉDIO';
        }).length;
    final saudavel =
        _scores.where((s) => s.riscoChurn.toUpperCase() == 'BAIXO').length;

    return fxScreenA11yScope(
      label: 'Saúde da base',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Saúde da base',
          subtitle: 'Score de retenção por aluno',
          onBack: () => safePopOrGo(context, '/dashboard/personal'),
        ),
        body:
            _loading
                ? Center(child: FxLoading(color: primary))
                : _error != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: _error!,
                  onRetry: _load,
                )
                : RefreshIndicator(
                  color: primary,
                  onRefresh: _load,
                  child:
                      sorted.isEmpty
                          ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 48),
                              FxEmptyState(
                                icon: 'activity',
                                title: 'Scores em breve',
                                subtitle:
                                    'A rotina calcula os scores aos domingos. '
                                    'Cadastre alunos e aguarde a primeira leitura.',
                              ),
                            ],
                          )
                          : CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    TokensStrip.s4,
                                    8,
                                    TokensStrip.s4,
                                    14,
                                  ),
                                  child: _ChurnSummaryStrip(
                                    alto: alto,
                                    medio: medio,
                                    saudavel: saudavel,
                                    isDark: isDark,
                                    primary: primary,
                                  ),
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  TokensStrip.s4,
                                  0,
                                  TokensStrip.s4,
                                  24,
                                ),
                                sliver: SliverList.separated(
                                  itemCount: sorted.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final score = sorted[index];
                                    return FxStaggerItem(
                                      index: index,
                                      child: _ChurnScoreCard(
                                        score: score,
                                        isDark: isDark,
                                        primary: primary,
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          context.push(
                                            '/alunos/${score.alunoId}',
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                ),
      ),
    );
  }
}

class _ChurnSummaryStrip extends StatelessWidget {
  final int alto;
  final int medio;
  final int saudavel;
  final bool isDark;
  final Color primary;

  const _ChurnSummaryStrip({
    required this.alto,
    required this.medio,
    required this.saudavel,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: fxListCardDecoration(context, accent: primary, radius: 20),
      child: Row(
        children: [
          Expanded(
            child: _SummaryChip(
              label: 'Alto',
              value: alto,
              fg: EagleTokens.bad,
              bg: EagleTokens.badSoft,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryChip(
              label: 'Médio',
              value: medio,
              fg: EagleTokens.warn,
              bg: EagleTokens.warnSoft,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryChip(
              label: 'Saudável',
              value: saudavel,
              fg: EagleTokens.good,
              bg: EagleTokens.goodSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int value;
  final Color fg;
  final Color bg;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.fg,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final ink = fxScreenInk(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTypography.mono(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ink.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChurnScoreCard extends StatelessWidget {
  final RetencaoAlunoScore score;
  final bool isDark;
  final Color primary;
  final VoidCallback onTap;

  const _ChurnScoreCard({
    required this.score,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final nome = fxTitleCaseName(score.alunoNome);
    final riskLabel = _riscoLabel(score.riscoChurn);
    final (pillFg, pillBg) = alunoHeroRiscoMetricBadgeColors(
      isDark,
      score.riscoChurn,
    );
    final accent =
        score.riscoChurn.toUpperCase() == 'ALTO' ? EagleTokens.bad : null;
    final delta = score.delta;
    final deltaColor =
        delta > 0
            ? EagleTokens.bad
            : delta < 0
            ? EagleTokens.good
            : mute;

    return Semantics(
      button: true,
      label: '$nome. Score ${score.scoreAtual}. $riskLabel.',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: chrome.listCard(
            primary: accent ?? primary,
            radius: TokensStrip.rCard,
            selected: score.riscoChurn.toUpperCase() == 'ALTO',
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  fxInitials(nome),
                  style: AppTypography.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: pillFg,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Score ',
                          style: TextStyle(
                            fontSize: 12,
                            color: mute,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${score.scoreAtual}',
                          style: AppTypography.mono(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                        if (delta != 0) ...[
                          const SizedBox(width: 6),
                          Icon(
                            delta > 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 14,
                            color: deltaColor,
                          ),
                          Text(
                            delta > 0 ? '+$delta' : '$delta',
                            style: AppTypography.mono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: deltaColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  riskLabel,
                  style: AppTypography.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: pillFg,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 20, color: mute),
            ],
          ),
        ),
      ),
    );
  }
}
