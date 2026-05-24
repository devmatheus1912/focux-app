import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/exercicio_repository.dart';
import '../providers/exercicios_provider.dart';
import '../screens/widgets/exercise_media_thumb.dart';
import 'biblioteca_sync_status.dart';

const _bootstrapKey = 'biblioteca_bootstrap_v1_done';
const _mediaPublishKey = 'biblioteca_media_publish_v1_done';

/// Garante biblioteca curada + mídia/substitutos sem ação do personal.
class BibliotecaBootstrap {
  BibliotecaBootstrap._();

  static bool _running = false;

  /// Captura o [ProviderContainer] de forma síncrona — seguro após dispose da tela.
  static Future<void> ensureReady(BuildContext context) {
    return ensureReadyWithContainer(ProviderScope.containerOf(context));
  }

  static Future<void> ensureReadyWithContainer(ProviderContainer container) async {
    if (_running) return;
    _running = true;
    BibliotecaSyncStatus.instance.start('Preparando biblioteca de exercícios...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final repo = container.read(exercicioRepositoryProvider);
      var list = await container.read(exerciciosProvider.future);

      if (list.isEmpty) {
        BibliotecaSyncStatus.instance.start('Importando exercícios padrão...');
        await repo.importarSeedPremiumV1();
        container.invalidate(exerciciosProvider);
        list = await container.read(exerciciosProvider.future);
      }

      final needsEnrich =
          list.any(
            (exercicio) =>
                exercicio.curado &&
                (exercicio.gifUrl?.trim().isEmpty ?? true) &&
                (exercicio.substitutos?.trim().isEmpty ?? true),
          );

      if (needsEnrich || !(prefs.getBool(_bootstrapKey) ?? false)) {
        BibliotecaSyncStatus.instance.start('Enriquecendo demonstrações...');
        await repo.enriquecerBibliotecaCurada();
        container.invalidate(exerciciosProvider);
        await prefs.setBool(_bootstrapKey, true);
        list = await container.read(exerciciosProvider.future);
      }

      if (_needsMediaPublish(list)) {
        list = await _publishAllMedia(container, repo, prefs, list);
      } else {
        await prefs.setBool(_mediaPublishKey, true);
      }

      final pending = list.where(exercicioMissingPreviewPoster).length;
      BibliotecaSyncStatus.instance.stop(pendingMediaCount: pending);
    } catch (_) {
      await _stopAfterPartialFailure(container);
    } finally {
      _running = false;
    }
  }

  static Future<void> _stopAfterPartialFailure(ProviderContainer container) async {
    try {
      final pending =
          (await container.read(exerciciosProvider.future))
              .where(exercicioMissingPreviewPoster)
              .length;
      BibliotecaSyncStatus.instance.stop(
        pendingMediaCount: pending,
        warningMessage:
            'Sincronização parcial. As demonstrações continuam em segundo plano.',
      );
    } catch (_) {
      BibliotecaSyncStatus.instance.stop();
    }
  }

  static Future<List<Exercicio>> _publishAllMedia(
    ProviderContainer container,
    ExercicioRepository repo,
    SharedPreferences prefs,
    List<Exercicio> list,
  ) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final pending = list.where(exercicioMissingPreviewPoster).length;
      if (pending == 0) break;

      BibliotecaSyncStatus.instance.start(
        attempt == 0
            ? 'Publicando demonstrações ($pending)...'
            : 'Repetindo publicação ($pending)...',
      );
      BibliotecaSyncStatus.instance.updatePendingMedia(pending);

      await repo.publicarMidiasCuradas();
      container.invalidate(exerciciosProvider);
      list = await container.read(exerciciosProvider.future);

      if (!_needsMediaPublish(list)) {
        await prefs.setBool(_mediaPublishKey, true);
        return list;
      }
      await prefs.remove(_mediaPublishKey);
    }
    return list;
  }

  static bool _needsMediaPublish(List<Exercicio> list) {
    return list.any(exercicioMissingPreviewPoster);
  }
}
