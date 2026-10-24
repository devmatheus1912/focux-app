import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/ficha_historico_repository.dart';
import '../models/ficha_historico.dart';

final fichaHistoricoRepositoryProvider = Provider<FichaHistoricoRepository>(
  (ref) => FichaHistoricoRepository(ref.read(apiClientProvider)),
);

final fichasAnterioresProvider = FutureProvider.autoDispose
    .family<List<FichaHistorico>, int>(
      (ref, alunoId) => ref.watch(fichaHistoricoRepositoryProvider).listar(alunoId),
    );

final fichaAnteriorProvider = FutureProvider.autoDispose
    .family<FichaHistorico, ({int alunoId, int fichaId})>(
      (ref, chave) =>
          ref.watch(fichaHistoricoRepositoryProvider).buscar(chave.alunoId, chave.fichaId),
    );
