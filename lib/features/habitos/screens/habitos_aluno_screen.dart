import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/subscription/models/subscription_plan.dart';
import '../data/habito_repository.dart';
import '../utils/habitos_display.dart';

final _repoProvider = Provider(
  (ref) => HabitoRepository(ref.read(apiClientProvider)),
);

class HabitosAlunoScreen extends ConsumerStatefulWidget {
  const HabitosAlunoScreen({super.key});

  @override
  ConsumerState<HabitosAlunoScreen> createState() => _HabitosAlunoScreenState();
}

class _HabitosAlunoScreenState extends ConsumerState<HabitosAlunoScreen> {
  List<Habito> _habitos = [];
  bool _loading = true;
  String? _error;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lista = await ref.read(_repoProvider).meusHabitos();
      if (!mounted) return;
      setState(() {
        _habitos = lista;
        _fetchedAt = DateTime.now();
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

  Future<void> _toggle(Habito h) async {
    try {
      final result = await ref.read(_repoProvider).toggleHoje(h.id);
      setState(() {
        _habitos =
            _habitos
                .map(
                  (x) =>
                      x.id == h.id
                          ? Habito(
                            id: x.id,
                            titulo: x.titulo,
                            descricao: x.descricao,
                            icone: x.icone,
                            tipo: x.tipo,
                            metaDiaria: x.metaDiaria,
                            metaSemanal: x.metaSemanal,
                            feitosNaSemana:
                                result.feito
                                    ? x.feitosNaSemana + 1
                                    : (x.feitosNaSemana - 1).clamp(0, 7),
                            feitoHoje: result.feito,
                            streakAtual: result.streak,
                            badgeSemana: result.streak >= 7,
                            alunoId: x.alunoId,
                          )
                          : x,
                )
                .toList();
      });
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forDark(isDark);
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    return fxScreenA11yScope(
      label: 'Meus hábitos',
      child: FeatureGate(
        featureName: 'Habit Coaching',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'habitCoaching',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Meus hábitos',
            subtitle: freshnessLabel ?? 'Sua jornada de consistência diária',
          ),
          body:
              _loading
                  ? const SkeletonList(count: 5)
                  : _error != null
                  ? FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    title: FocuxMicrocopy.naoFoiPossivelCarregar,
                    message: _error!,
                    onRetry: _carregar,
                  )
                  : RefreshIndicator(
                    onRefresh: _carregar,
                    child:
                        _habitos.isEmpty
                            ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 48),
                                FxEmptyState(
                                  icon: 'dumbbell',
                                  title: 'Nenhum hábito ainda',
                                  subtitle:
                                      'Seu personal ainda não cadastrou hábitos. Avise para começar sua jornada.',
                                ),
                              ],
                            )
                            : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _habitos.length,
                              itemBuilder: (_, i) {
                                final h = _habitos[i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: chrome.listCard(
                                    primary:
                                        h.feitoHoje
                                            ? EagleTokens.good
                                            : primary,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () async {
                                        await context.push(
                                          habitoAlunoDetailPath(h.id),
                                          extra: h,
                                        );
                                        if (mounted) await _carregar();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Semantics(
                                              label:
                                                  h.feitoHoje
                                                      ? 'Desmarcar hábito ${h.titulo}'
                                                      : 'Marcar hábito ${h.titulo}',
                                              child: Checkbox(
                                                value: h.feitoHoje,
                                                onChanged: (_) => _toggle(h),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    h.titulo,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: chrome.ink,
                                                      decoration:
                                                          h.feitoHoje
                                                              ? TextDecoration
                                                                  .lineThrough
                                                              : null,
                                                    ),
                                                  ),
                                                  if (h.descricao != null &&
                                                      h.descricao!.isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 2,
                                                          ),
                                                      child: Text(
                                                        h.descricao!,
                                                        style: TextStyle(
                                                          color: chrome.mute,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: BrandPalette.soft(
                                                  primary,
                                                  dark: isDark,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '${h.streakAtual} dias',
                                                style: TextStyle(
                                                  color: EagleTokens.warn,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: EagleTokens.goodSoft,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                '${h.feitosNaSemana}/${h.metaSemanal}',
                                                style: const TextStyle(
                                                  color: EagleTokens.good,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
        ),
      ),
    );
  }
}
