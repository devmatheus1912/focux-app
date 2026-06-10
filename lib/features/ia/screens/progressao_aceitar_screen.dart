import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../features/alunos/constants/aluno_360_layout.dart';
import '../../../features/alunos/utils/satellite_screen_utils.dart';
import '../../../features/alunos/widgets/aluno360_action_empty_panel.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/ia_repository.dart';
import '../utils/ia_progressao_carga_delta.dart';
import '../utils/progressao_aceitar_route_args.dart';
import '../widgets/ia_carga_chip.dart';
import '../widgets/ia_expandable_copy.dart';
import '../widgets/ia_progressao_card_entrance.dart';

final sugestoesProgressaoProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int?>((
      ref,
      alunoId,
    ) async {
      return IaRepository(ref.read(apiClientProvider)).sugestoesProgressao(
        alunoId: alunoId,
      );
    });

class ProgressaoAceitarScreen extends ConsumerWidget {
  const ProgressaoAceitarScreen({super.key, this.args = const ProgressaoAceitarRouteArgs()});

  final ProgressaoAceitarRouteArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sugestoesAsync = ref.watch(sugestoesProgressaoProvider(args.alunoId));
    final firstName = satelliteFirstName(args.alunoNome, fallback: 'aluno');

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Sugestões pendentes',
        subtitle: args.alunoNome,
        onBack: () => safePopOrGo(context, args.returnTo ?? '/ia/copiloto'),
        actions: [
          Semantics(
            button: true,
            label: 'Atualizar sugestões pendentes',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(sugestoesProgressaoProvider(args.alunoId)),
            ),
          ),
        ],
      ),
      body: sugestoesAsync.when(
        loading: () => const FxLoading(),
        error:
            (e, _) => satelliteEmptyBody(
              child: Aluno360ActionEmptyPanel(
                icon: Icons.error_outline_rounded,
                title: 'Não carregou as sugestões',
                subtitle:
                    'Tente novamente. Se o problema continuar, volte ao aluno e gere uma nova progressão.',
                primaryLabel: 'Tentar novamente',
                primaryIcon: Icons.refresh,
                onPrimary:
                    () => ref.invalidate(sugestoesProgressaoProvider(args.alunoId)),
                secondaryActions: [
                  if (args.alunoId != null)
                    Aluno360SecondaryAction(
                      label: 'Voltar ao Aluno 360',
                      icon: Icons.person_outline,
                      onTap:
                          () => safePopOrGo(
                            context,
                            args.returnTo ?? '/alunos/${args.alunoId}',
                          ),
                    ),
                ],
              ),
            ),
        data: (lista) {
          if (lista.isEmpty) {
            return satelliteEmptyBody(
              child: Aluno360ActionEmptyPanel(
                icon: Icons.check_circle_outline,
                title: 'Nenhuma sugestão pendente',
                subtitle:
                    args.alunoId == null
                        ? 'Quando a IA sugerir progressão de carga, ela aparecerá aqui para você revisar e aplicar.'
                        : 'Gere uma progressão com IA para $firstName e volte aqui para revisar antes de aplicar no treino.',
                primaryLabel:
                    args.alunoId == null ? null : 'Gerar progressão com IA',
                primaryIcon: args.alunoId == null ? null : Icons.auto_awesome,
                onPrimary:
                    args.alunoId == null
                        ? null
                        : () => context.push(
                          '/alunos/${args.alunoId}/ia/progressao',
                          extra: args.alunoNome ?? 'Aluno',
                        ),
                showPrimary: args.alunoId != null,
                secondaryActions: [
                  if (args.alunoId != null)
                    Aluno360SecondaryAction(
                      label: 'Voltar ao Aluno 360',
                      icon: Icons.arrow_back_rounded,
                      onTap:
                          () => safePopOrGo(
                            context,
                            args.returnTo ?? '/alunos/${args.alunoId}',
                          ),
                    ),
                ],
              ),
            );
          }

          return Aluno360Layout.operacaoContentWidthLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(TokensStrip.s4),
              itemCount: lista.length,
              itemBuilder:
                  (_, i) => IaProgressaoCardEntrance(
                    index: i,
                    child: _CardSugestao(
                      sugestao: lista[i],
                      onAceitar: () => _acao(context, ref, lista[i], aceitar: true),
                      onRejeitar:
                          () => _acao(context, ref, lista[i], aceitar: false),
                    ),
                  ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _acao(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> sugestao, {
    required bool aceitar,
  }) async {
    final id = sugestao['id'] as int?;
    if (id == null) return;
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      if (aceitar) {
        await repo.aceitarSugestao(id);
      } else {
        await repo.rejeitarSugestao(id);
      }
      ref.invalidate(sugestoesProgressaoProvider(args.alunoId));
      if (context.mounted) {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(
            content: Text(
              aceitar
                  ? 'Sugestão aceita e carga aplicada no treino.'
                  : 'Sugestão descartada.',
            ),
            backgroundColor: aceitar ? EagleTokens.good : EagleTokens.warn,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(content: Text('Não foi possível concluir: $e')),
        );
      }
    }
  }
}

class _CardSugestao extends StatelessWidget {
  const _CardSugestao({
    required this.sugestao,
    required this.onAceitar,
    required this.onRejeitar,
  });

  final Map<String, dynamic> sugestao;
  final VoidCallback onAceitar;
  final VoidCallback onRejeitar;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final alunoNome = sugestao['alunoNome'] as String? ?? 'Aluno';
    final exercicio = sugestao['exercicio'] as String? ?? '—';
    final cargaAtual =
        sugestao['cargaAtual']?.toString() ??
        _formatKg(sugestao['cargaAnteriorKg']);
    final cargaSugerida =
        sugestao['cargaSugerida']?.toString() ??
        _formatKg(sugestao['cargaSugeridaKg']);
    final motivo =
        sugestao['justificativa'] as String? ??
        sugestao['motivo'] as String? ??
        '';
    final deltaLabel = _deltaLabelFromApi(sugestao) ??
        computeProgressaoDeltaLabel(cargaAtual, cargaSugerida);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Semantics(
        label:
            'Sugestão de $exercicio para $alunoNome. Atual $cargaAtual. Sugerido $cargaSugerida.',
        child: DecoratedBox(
          decoration: fxListCardDecoration(context, accent: primary),
          child: Padding(
            padding: const EdgeInsets.all(TokensStrip.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: primary,
                      child: const Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alunoNome,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Text(
                  exercicio,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: IaCargaChip(
                        label: 'Atual',
                        valor: cargaAtual.isEmpty ? '—' : cargaAtual,
                        color: TokensStrip.textSecondary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.arrow_forward_rounded, color: primary),
                    ),
                    Expanded(
                      child: IaCargaChip(
                        label: 'Sugerido',
                        valor: cargaSugerida.isEmpty ? '—' : cargaSugerida,
                        color: primary,
                        deltaLabel: deltaLabel,
                      ),
                    ),
                  ],
                ),
                if (motivo.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: TokensStrip.textSecondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: TokensStrip.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: IaExpandableCopy(
                            text: motivo,
                            expandLabel: 'Ler justificativa completa',
                            collapseLabel: 'Ver menos',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Rejeitar sugestão de $exercicio',
                        child: OutlinedButton.icon(
                          onPressed: onRejeitar,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Rejeitar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: EagleTokens.bad,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        button: true,
                        label: 'Aceitar sugestão de $exercicio e aplicar no treino',
                        child: FilledButton.icon(
                          onPressed: onAceitar,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Aceitar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: EagleTokens.good,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatKg(Object? raw) {
    if (raw == null) return '';
    final text = raw.toString().trim();
    if (text.isEmpty) return '';
    return text.endsWith('kg') ? text : '${text}kg';
  }

  static String? _deltaLabelFromApi(Map<String, dynamic> sugestao) {
    final raw = sugestao['deltaKg'];
    final value = switch (raw) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s.replaceAll(',', '.')),
      _ => null,
    };
    if (value == null || value.abs() < 0.01) return null;
    final sign = value > 0 ? '+' : '';
    final abs = value.abs();
    final formatted =
        abs == abs.roundToDouble()
            ? abs.toStringAsFixed(0)
            : abs.toStringAsFixed(1).replaceAll('.', ',');
    return '$sign$formatted kg';
  }
}
