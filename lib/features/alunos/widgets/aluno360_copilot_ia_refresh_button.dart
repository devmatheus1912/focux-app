import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../ia/data/ia_repository.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_copilot_ia_cache_store.dart';
import '../providers/aluno_detail_providers.dart';

class Aluno360CopilotIaRefreshButton extends ConsumerStatefulWidget {
  const Aluno360CopilotIaRefreshButton({
    super.key,
    required this.alunoId,
    required this.primary,
  });

  final int alunoId;
  final Color primary;

  @override
  ConsumerState<Aluno360CopilotIaRefreshButton> createState() =>
      Aluno360CopilotIaRefreshButtonState();
}

class Aluno360CopilotIaRefreshButtonState
    extends ConsumerState<Aluno360CopilotIaRefreshButton> {
  var _refreshing = false;

  Future<void> _refreshIa() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    ref.read(alunoCopilotIaRefreshingProvider(widget.alunoId).notifier).state =
        true;
    unawaited(
      AnalyticsService.instance.track(
        ProductEvents.aluno360CopilotRefresh,
        props: {'aluno_id': widget.alunoId},
      ),
    );
    await AlunoCopilotIaCacheStore.clear(widget.alunoId);
    ref.read(alunoCopilotIaSkipCacheProvider(widget.alunoId).notifier).state =
        true;
    ref.read(alunoCopilotoForceIaProvider(widget.alunoId).notifier).state = true;
    try {
      await ref.refresh(alunoCopilotoActionProvider(widget.alunoId).future);
      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          'Sugestão atualizada com IA',
          reserveBottom: Aluno360Layout.snackbarStickyReserve,
        );
      }
    } catch (e) {
      ref.read(alunoCopilotoForceIaProvider(widget.alunoId).notifier).state =
          false;
      if (!mounted) return;
      if (_shouldSurfaceIaRefreshError(e)) {
        FeedbackHelper.showWarn(
          context,
          friendlyError(e, fallback: 'IA indisponível agora.'),
          reserveBottom: Aluno360Layout.snackbarStickyReserve,
        );
      } else {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(
            content: Text(
              friendlyError(
                e,
                fallback:
                    'IA indisponível agora — mantendo sugestão do Aluno 360.',
              ),
            ),
          ),
          reserveBottom: Aluno360Layout.snackbarStickyReserve,
        );
      }
    } finally {
      ref.read(alunoCopilotIaRefreshingProvider(widget.alunoId).notifier).state =
          false;
      if (mounted) setState(() => _refreshing = false);
    }
  }

  bool _shouldSurfaceIaRefreshError(Object error) {
    if (error is IaOperationalException) {
      return error.quotaExhausted || error.planUpgradeRequired;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: _refreshing ? null : _refreshIa,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            foregroundColor: widget.primary,
          ),
          icon:
              _refreshing
                  ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: widget.primary,
                    ),
                  )
                  : Icon(Icons.refresh_rounded, size: iconSize),
          label: Text(
            _refreshing ? 'Atualizando…' : 'Atualizar',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
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
        onPressed: _refreshing ? null : _refreshIa,
        icon:
            _refreshing
                ? SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: widget.primary,
                  ),
                )
                : Icon(Icons.refresh_rounded, size: iconSize),
        tooltip: _refreshing ? 'Atualizando…' : 'Regenerar sugestão com IA',
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
