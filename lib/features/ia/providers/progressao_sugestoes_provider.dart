import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/ia_repository.dart';

/// Pending load-progression suggestions; [alunoId] null lists all personal alunos.
final progressaoSugestoesProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, int?>((ref, alunoId) async {
      return IaRepository(ref.read(apiClientProvider)).sugestoesProgressao(
        alunoId: alunoId,
      );
    });
