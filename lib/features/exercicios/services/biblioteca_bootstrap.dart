import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/exercicios_provider.dart';
import 'biblioteca_sync_status.dart';

const _bootstrapKey = 'biblioteca_bootstrap_v1_done';

/// Garante biblioteca curada + substitutos. Publicação de demos fica em standby.
class BibliotecaBootstrap {
  BibliotecaBootstrap._();

  static bool _running = false;

  /// Captura o [ProviderContainer] de forma síncrona — seguro após dispose da tela.
  static Future<void> ensureReady(BuildContext context) {
    return ensureReadyWithContainer(ProviderScope.containerOf(context));
  }

  static Future<void> ensureReadyWithContainer(
    ProviderContainer container,
  ) async {
    if (_running) return;
    _running = true;
    BibliotecaSyncStatus.instance.start('Preparando biblioteca...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final repo = container.read(exercicioRepositoryProvider);
      var exercicios = await container.read(exerciciosProvider.future);

      if (exercicios.isEmpty) {
        BibliotecaSyncStatus.instance.start('Importando exercícios padrão...');
        await repo.importarSeedPremiumV1();
        container.invalidate(exerciciosProvider);
        exercicios = await container.read(exerciciosProvider.future);
      }

      final needsEnrich = exercicios.any(
        (exercicio) =>
            exercicio.curado &&
            (exercicio.gifUrl?.trim().isEmpty ?? true) &&
            (exercicio.substitutos?.trim().isEmpty ?? true),
      );

      if (needsEnrich || !(prefs.getBool(_bootstrapKey) ?? false)) {
        BibliotecaSyncStatus.instance.start('Organizando biblioteca...');
        await repo.enriquecerBibliotecaCurada();
        container.invalidate(exerciciosProvider);
        await prefs.setBool(_bootstrapKey, true);
      }

      BibliotecaSyncStatus.instance.stop(pendingMediaCount: 0);
    } catch (_) {
      BibliotecaSyncStatus.instance.stop();
    } finally {
      _running = false;
    }
  }
}
