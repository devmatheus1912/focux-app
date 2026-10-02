import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../ia/data/ia_repository.dart';
import '../../planos/data/plano_recurso.dart';
import '../../planos/utils/plan_gate.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_copilot_ia_cache_store.dart';
import '../providers/aluno_detail_providers.dart';
import '../utils/aluno360_ia_upgrade.dart';

class Aluno360CopilotIaRefreshButton extends ConsumerStatefulWidget {
  const Aluno360CopilotIaRefreshButton({
    super.key,
    required this.alunoId,
    required this.primary,
    this.prominent = false,
  });

  final int alunoId;
  final Color primary;
  final bool prominent;

  @override
  ConsumerState<Aluno360CopilotIaRefreshButton> createState() =>
      Aluno360CopilotIaRefreshButtonState();
}

class Aluno360CopilotIaRefreshButtonState
    extends ConsumerState<Aluno360CopilotIaRefreshButton> {
  var _refreshing = false;
  var _requestSeq = 0;

  Future<void> _refreshIa() async {
    final requestSeq = ++_requestSeq;
    setState(() => _refreshing = true);
    // Keep current card visible; status badge/spinner only.
    ref.read(alunoCopilotIaRefreshingProvider(widget.alunoId).notifier).value =
        true;
    unawaited(
      AnalyticsService.instance.track(
        ProductEvents.aluno360CopilotRefresh,
        props: {'aluno_id': widget.alunoId},
      ),
    );
    await AlunoCopilotIaCacheStore.clear(widget.alunoId);
    ref.read(alunoCopilotIaSkipCacheProvider(widget.alunoId).notifier).value =
        true;
    ref.read(alunoCopilotoForceIaProvider(widget.alunoId).notifier).value =
        true;
    try {
      ref.invalidate(alunoCopilotoActionProvider(widget.alunoId));
      await ref.read(alunoCopilotoActionProvider(widget.alunoId).future);
      if (!_isLatestRequest(requestSeq)) return;
      if (mounted) {
        FeedbackHelper.showOperacaoSuccess(
          context,
          'Sugestão atualizada com IA',
        );
      }
    } catch (e) {
      if (!_isLatestRequest(requestSeq)) return;
      // Keep deterministic card — clear forceIa only when no usable IA value.
      final ia = ref.read(alunoCopilotoActionProvider(widget.alunoId));
      if (!ia.hasValue) {
        ref.read(alunoCopilotoForceIaProvider(widget.alunoId).notifier).value =
            false;
      }
      if (!mounted) return;
      if (await surfaceAluno360IaUpgradeIfNeeded(context, e)) {
        return;
      }
      if (!mounted) return;
      if (_shouldSurfaceIaRefreshError(e)) {
        FeedbackHelper.showOperacaoWarn(
          context,
          friendlyError(e, fallback: 'IA indisponível agora.'),
        );
      } else {
        FeedbackHelper.showOperacaoError(
          context,
          friendlyError(
            e,
            fallback: 'IA indisponível agora — mantendo sugestão do Aluno 360.',
          ),
        );
      }
    } finally {
      // Always clear loading for the latest request (stale responses ignored).
      if (_isLatestRequest(requestSeq)) {
        ref
            .read(alunoCopilotIaRefreshingProvider(widget.alunoId).notifier)
            .value = false;
        if (mounted) setState(() => _refreshing = false);
      }
    }
  }

  bool _isLatestRequest(int requestSeq) => requestSeq == _requestSeq;

  bool _shouldSurfaceIaRefreshError(Object error) {
    if (error is IaOperationalException) {
      return error.quotaExhausted || error.planUpgradeRequired;
    }
    return false;
  }

  Future<void> _openUpgrade(SubscriptionPlan plano) {
    return UpgradePromptSheet.show(
      context: context,
      featureName: 'Prioridade do dia com IA',
      capability: PlanoRecursoKeys.ia,
      requiredPlan: plano,
      upgradePlano: plano,
      source: 'aluno360_copilot_ia',
    );
  }

  Widget _buildLocked(BuildContext context, PlanoRecurso ia) {
    final tier = PlanGate.tierLabel(ia.planoMinimo);
    final label = 'Gerar com IA · disponível no $tier';
    if (widget.prominent) {
      return Semantics(
        button: true,
        label: label,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openUpgrade(ia.planoMinimo),
            icon: const Icon(Icons.lock_rounded, size: 18),
            label: Text('Gerar com IA · $tier'),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        key: const ValueKey('aluno360_copilot_ia_locked'),
        onPressed: () => _openUpgrade(ia.planoMinimo),
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        icon: Icon(Icons.lock_rounded, size: 18, color: widget.primary),
        tooltip: label,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ia = PlanGate.watch(ref, PlanoRecursoKeys.ia);
    if (!ia.liberado) return _buildLocked(context, ia);

    if (widget.prominent) {
      return Semantics(
        button: true,
        label:
            _refreshing
                ? 'Gerando prioridade com IA'
                : 'Gerar prioridade com IA',
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _refreshIa,
            icon:
                _refreshing
                    ? FxLoading(
                      size: 18,
                      strokeWidth: 2,
                      color: Colors.white,
                    )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(_refreshing ? 'Gerando…' : 'Gerar com IA'),
            style: Aluno360Layout.operacaoFilledButtonStyle(
              context,
              widget.primary,
            ),
          ),
        ),
      );
    }

    final wideHeader = MediaQuery.sizeOf(context).width >= 400;
    final iconSize = wideHeader ? 20.0 : 18.0;

    if (wideHeader) {
      return Semantics(
        button: true,
        label:
            _refreshing
                ? 'Atualizando sugestão com IA'
                : 'Atualizar sugestão com IA',
        child: TextButton.icon(
          onPressed: _refreshIa,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            foregroundColor: widget.primary,
          ),
          icon:
              _refreshing
                  ? FxLoading(
                    size: iconSize,
                    strokeWidth: 2,
                    color: widget.primary,
                  )
                  : Icon(Icons.refresh_rounded, size: iconSize),
          label: Text(
            _refreshing ? 'Atualizando…' : 'Atualizar',
            style: Aluno360Layout.chipLabelStyle(
              context,
            ).copyWith(color: widget.primary),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label:
          _refreshing
              ? 'Atualizando sugestão com IA'
              : 'Atualizar sugestão com IA',
      child: IconButton.filledTonal(
        onPressed: _refreshIa,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        icon:
            _refreshing
                ? FxLoading(
                  size: iconSize,
                  strokeWidth: 2,
                  color: widget.primary,
                )
                : Icon(Icons.refresh_rounded, size: iconSize),
        tooltip: _refreshing ? 'Atualizando…' : 'Regenerar sugestão com IA',
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
