import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/ficha_modelo_repository.dart';
import '../models/ficha_modelo.dart';

final fichaModeloRepositoryProvider = Provider<FichaModeloRepository>(
  (ref) => FichaModeloRepository(ref.read(apiClientProvider)),
);

final fichaModelosProvider = FutureProvider.autoDispose<List<FichaModelo>>(
  (ref) => ref.watch(fichaModeloRepositoryProvider).listar(),
);

final fichaModeloProvider = FutureProvider.autoDispose.family<FichaModelo, int>(
  (ref, id) => ref.watch(fichaModeloRepositoryProvider).buscar(id),
);
