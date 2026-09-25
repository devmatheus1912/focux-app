import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:focux_app/features/alunos/providers/aluno_timeline360_paged_provider.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/providers/plano_features_provider.dart';

/// Plano fixo, sem bootstrap/rede.
class SeededPlanoFeaturesNotifier extends PlanoFeaturesNotifier {
  SeededPlanoFeaturesNotifier(this.seed);

  final AsyncValue<PlanoFeatures> seed;

  @override
  AsyncValue<PlanoFeatures> build() => seed;
}

Override seededPlanoFeatures(PlanoFeatures features) =>
    planoFeaturesProvider.overrideWith(
      () => SeededPlanoFeaturesNotifier(AsyncData(features.normalizeForTier())),
    );

/// Timeline 360 fixa, sem fetch.
class SeededTimeline360Notifier extends Timeline360PagedNotifier {
  SeededTimeline360Notifier(super.alunoId, this.seed);

  final Timeline360PagedState seed;

  @override
  AsyncValue<Timeline360PagedState> build() => AsyncData(seed);
}

Override seededTimeline360(int alunoId, Timeline360PagedState seed) =>
    alunoTimeline360PagedProvider(
      alunoId,
    ).overrideWith(() => SeededTimeline360Notifier(alunoId, seed));
