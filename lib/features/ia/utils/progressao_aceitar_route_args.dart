import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/estado_da_rota.dart';
class ProgressaoAceitarRouteArgs {
  const ProgressaoAceitarRouteArgs({
    this.returnTo,
    this.alunoId,
    this.alunoNome,
    this.alunoFotoUrl,
  });

  final String? returnTo;
  final int? alunoId;
  final String? alunoNome;
  final String? alunoFotoUrl;

  /// Resolves navigation context from [GoRouter] extra (hot-reload safe).
  static ProgressaoAceitarRouteArgs resolve(BuildContext context) =>
      fromExtra(estadoDaRota(context)?.extra);

  static ProgressaoAceitarRouteArgs fromExtra(Object? extra) {
    if (extra is! Map) return const ProgressaoAceitarRouteArgs();
    final rawAlunoId = extra['alunoId'];
    final alunoId = switch (rawAlunoId) {
      final int value => value,
      final String value => int.tryParse(value),
      _ => null,
    };
    return ProgressaoAceitarRouteArgs(
      returnTo: extra['returnTo']?.toString(),
      alunoId: alunoId,
      alunoNome: extra['alunoNome']?.toString(),
      alunoFotoUrl: extra['alunoFotoUrl']?.toString(),
    );
  }

  Map<String, Object?> toExtra() => {
    if (returnTo != null) 'returnTo': returnTo,
    if (alunoId != null) 'alunoId': alunoId,
    if (alunoNome != null) 'alunoNome': alunoNome,
    if (alunoFotoUrl != null) 'alunoFotoUrl': alunoFotoUrl,
  };
}
