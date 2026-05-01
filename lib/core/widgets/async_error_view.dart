import 'package:flutter/material.dart';

/// Standard error widget for AsyncValue.when(error:) handlers.
///
/// Usage in any screen:
/// ```dart
/// asyncData.when(
///   loading: () => const LoadingView(),
///   error: (e, _) => AsyncErrorView(error: e, onRetry: () => ref.invalidate(provider)),
///   data: (d) => MyContent(data: d),
/// )
/// ```
class AsyncErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const AsyncErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

  String _friendlyMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('connection') || lower.contains('socket') || lower.contains('timeout')) {
      return 'Sem conexão com o servidor';
    }
    if (lower.contains('401') || lower.contains('unauthorized')) {
      return 'Sessão expirada';
    }
    if (lower.contains('403') || lower.contains('forbidden')) {
      return 'Sem permissão';
    }
    if (lower.contains('404') || lower.contains('not found')) {
      return 'Não encontrado';
    }
    if (lower.contains('500') || lower.contains('internal')) {
      return 'Erro no servidor';
    }
    return 'Falha ao carregar';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: isDark ? Colors.white30 : Colors.black26, size: 48),
            const SizedBox(height: 16),
            Text(
              _friendlyMessage(error.toString()),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Toque para tentar novamente',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : Colors.black26),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Tentar novamente', style: TextStyle(fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard loading shimmer view.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}
