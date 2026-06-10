import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../ia/data/ia_repository.dart';
import '../../treinos/providers/treinos_provider.dart';
import '../constants/aluno_360_layout.dart';
import '../providers/aluno_detail_providers.dart';
import '../providers/alunos_provider.dart';
import '../utils/aluno360_copilot_logic.dart';
import 'aluno360_copilot_executar_confirm.dart';

class Aluno360CopilotExecutarAcaoButton extends ConsumerStatefulWidget {
  const Aluno360CopilotExecutarAcaoButton({
    super.key,
    required this.alunoId,
    required this.spec,
    required this.primary,
  });

  final int alunoId;
  final CopilotExecutarAcaoSpec spec;
  final Color primary;

  @override
  ConsumerState<Aluno360CopilotExecutarAcaoButton> createState() =>
      _Aluno360CopilotExecutarAcaoButtonState();
}

class _Aluno360CopilotExecutarAcaoButtonState
    extends ConsumerState<Aluno360CopilotExecutarAcaoButton> {
  var _executing = false;

  void _invalidateAfterExecutar(String backendTipo) {
    ref.invalidate(aluno360Provider(widget.alunoId));
    ref.invalidate(alunoProvider(widget.alunoId));
    if (backendTipo == 'REDUZIR_CARGA') {
      ref.invalidate(treinosDoAlunoProvider(widget.alunoId));
    }
  }

  bool _shouldSurfaceIaError(Object error) {
    if (error is IaOperationalException) {
      return error.quotaExhausted || error.planUpgradeRequired;
    }
    return false;
  }

  Future<void> _executar() async {
    final spec = widget.spec;
    if (_executing) return;

    final confirmed = await showCopilotExecutarConfirmSheet(
      context,
      spec: spec,
      primary: widget.primary,
    );
    if (!confirmed || !mounted) return;

    setState(() => _executing = true);
    unawaited(
      AnalyticsService.instance.track(
        ProductEvents.aluno360CopilotExecutarAcao,
        props: {
          'aluno_id': widget.alunoId,
          'tipo_acao': spec.backendTipo,
        },
      ),
    );
    try {
      final resp = await IaRepository(
        ref.read(apiClientProvider),
      ).executarAcaoCopiloto(
        alunoId: widget.alunoId,
        tipoAcao: spec.backendTipo,
        parametros: spec.parametros,
      );
      _invalidateAfterExecutar(spec.backendTipo);
      if (!mounted) return;
      if (resp.ok) {
        FeedbackHelper.showOperacaoSuccess(context, resp.mensagem);
      } else {
        FeedbackHelper.showOperacaoWarn(context, resp.mensagem);
      }
    } catch (e) {
      if (!mounted) return;
      if (_shouldSurfaceIaError(e)) {
        FeedbackHelper.showOperacaoWarn(
          context,
          friendlyError(e, fallback: 'IA indisponível agora.'),
        );
      } else {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(
            content: Text(
              friendlyError(e, fallback: 'Não foi possível aplicar a ação.'),
            ),
          ),
          placement: FeedbackPlacement.operacaoTop,
        );
      }
    } finally {
      if (mounted) setState(() => _executing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    return Semantics(
      button: true,
      label: _executing ? spec.executingSemantics : spec.label,
      child: SizedBox(
        width: double.infinity,
        height: 40,
        child: OutlinedButton.icon(
          onPressed: _executing ? null : _executar,
          icon:
              _executing
                  ? FxLoading(size: 16, strokeWidth: 2, color: widget.primary)
                  : Icon(spec.icon, size: 16),
          label: Text(
            _executing ? spec.executingLabel : spec.label,
            style: Aluno360Layout.chipLabelStyle(
              context,
              color: widget.primary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.primary,
            side: BorderSide(color: widget.primary.withValues(alpha: 0.32)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
      ),
    );
  }
}
