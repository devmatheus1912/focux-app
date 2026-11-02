import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/meta_corporal.dart';
import 'evolucao_home_provider.dart';

/// Metas vêm na mesma chamada da Evolução.
final metasDoAlunoProvider = FutureProvider.autoDispose
    .family<List<MetaCorporal>, int>(
      (ref, alunoId) async =>
          (await ref.watch(evolucaoHomeProvider(alunoId).future)).metas,
    );
