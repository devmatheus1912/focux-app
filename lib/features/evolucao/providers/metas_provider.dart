import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../data/meta_corporal.dart';

final metasDoAlunoProvider = FutureProvider.autoDispose
    .family<List<MetaCorporal>, int>(
      (ref, alunoId) =>
          EvolucaoRepository(ref.read(apiClientProvider)).metas(alunoId),
    );

final minhasMetasProvider = FutureProvider.autoDispose<List<MetaCorporal>>(
  (ref) => EvolucaoRepository(ref.read(apiClientProvider)).minhasMetas(),
);
