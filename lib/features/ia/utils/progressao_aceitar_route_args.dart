class ProgressaoAceitarRouteArgs {
  const ProgressaoAceitarRouteArgs({
    this.returnTo,
    this.alunoId,
    this.alunoNome,
  });

  final String? returnTo;
  final int? alunoId;
  final String? alunoNome;

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
    );
  }

  Map<String, Object?> toExtra() => {
    if (returnTo != null) 'returnTo': returnTo,
    if (alunoId != null) 'alunoId': alunoId,
    if (alunoNome != null) 'alunoNome': alunoNome,
  };
}
