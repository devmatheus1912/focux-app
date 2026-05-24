import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../exercicios/providers/exercicios_provider.dart';

const _bootstrapKey = 'biblioteca_bootstrap_v1_done';
const _mediaPublishKey = 'biblioteca_media_publish_v1_done';

/// Garante biblioteca curada + mídia/substitutos sem ação do personal.
class BibliotecaBootstrap {
  BibliotecaBootstrap._();

  static bool _running = false;

  static Future<void> ensureReady(WidgetRef ref) async {
    if (_running) return;
    _running = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final repo = ref.read(exercicioRepositoryProvider);
      var list = await ref.read(exerciciosProvider.future);

      if (list.isEmpty) {
        await repo.importarSeedPremiumV1();
        ref.invalidate(exerciciosProvider);
        list = await ref.read(exerciciosProvider.future);
      }

      final needsEnrich =
          list.any(
            (exercicio) =>
                exercicio.curado &&
                (exercicio.gifUrl?.trim().isEmpty ?? true) &&
                (exercicio.substitutos?.trim().isEmpty ?? true),
          );

      if (needsEnrich || !(prefs.getBool(_bootstrapKey) ?? false)) {
        await repo.enriquecerBibliotecaCurada();
        ref.invalidate(exerciciosProvider);
        await prefs.setBool(_bootstrapKey, true);
      }

      list = await ref.read(exerciciosProvider.future);
      final needsMediaPublish = list.any(
        (exercicio) =>
            exercicio.curado &&
            !(exercicio.gifUrl?.contains('/upload/v') ?? false),
      );
      if (needsMediaPublish && !(prefs.getBool(_mediaPublishKey) ?? false)) {
        await repo.publicarMidiasCuradas();
        ref.invalidate(exerciciosProvider);
        await prefs.setBool(_mediaPublishKey, true);
      }
    } catch (_) {
      // Falha silenciosa — telas individuais ainda têm fallback manual.
    } finally {
      _running = false;
    }
  }
}
