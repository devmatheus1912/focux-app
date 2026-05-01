import 'package:flutter/material.dart';

/// Wraps any async screen with try/catch + friendly error UI.
/// Prevents red-screen-of-death for connection, parsing, and API errors.
///
/// Usage:
/// ```dart
/// SafeAsyncScreen(
///   futureBuilder: () => myApiFuture(),
///   builder: (context, data) => MyContent(data: data),
/// )
/// ```
class SafeAsyncScreen<T> extends StatefulWidget {
  final Future<T> Function() futureBuilder;
  final Widget Function(BuildContext context, T data) builder;
  final String? title;
  final VoidCallback? onBack;

  const SafeAsyncScreen({
    super.key,
    required this.futureBuilder,
    required this.builder,
    this.title,
    this.onBack,
  });

  @override
  State<SafeAsyncScreen<T>> createState() => _SafeAsyncScreenState<T>();
}

class _SafeAsyncScreenState<T> extends State<SafeAsyncScreen<T>> {
  late Future<T> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.futureBuilder();
  }

  void _retry() {
    setState(() {
      _future = widget.futureBuilder();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _LoadingView(title: widget.title);
        }
        if (snap.hasError) {
          return _ErrorView(
            error: snap.error.toString(),
            title: widget.title,
            onRetry: _retry,
            onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
          );
        }
        return widget.builder(context, snap.data as T);
      },
    );
  }
}

/// Standalone error page widget — use directly in any screen catch block.
class ApiErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onBack;

  const ApiErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return _ErrorView(
      error: message,
      onRetry: onRetry,
      onBack: onBack ?? () => Navigator.of(context).maybePop(),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final String? title;
  const _LoadingView({this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : Colors.white,
      appBar: title != null ? AppBar(title: Text(title!), elevation: 0) : null,
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final String? title;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _ErrorView({
    required this.error,
    this.title,
    required this.onRetry,
    required this.onBack,
  });

  String _friendlyMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('connection') || lower.contains('socket') || lower.contains('timeout')) {
      return 'Sem conexão com o servidor.\nVerifique sua internet e tente novamente.';
    }
    if (lower.contains('401') || lower.contains('unauthorized')) {
      return 'Sessão expirada.\nFaça login novamente.';
    }
    if (lower.contains('403') || lower.contains('forbidden')) {
      return 'Você não tem permissão para acessar este recurso.';
    }
    if (lower.contains('404') || lower.contains('not found')) {
      return 'Recurso não encontrado.\nEste conteúdo pode ter sido removido.';
    }
    if (lower.contains('500') || lower.contains('internal server')) {
      return 'Erro no servidor.\nTente novamente em alguns instantes.';
    }
    if (lower.contains('format') || lower.contains('type') || lower.contains('null')) {
      return 'Erro ao processar dados.\nTente novamente.';
    }
    return 'Algo deu errado.\nTente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1E) : Colors.white,
      appBar: title != null
          ? AppBar(title: Text(title!), elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack))
          : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi_off_rounded, color: Colors.red, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                _friendlyMessage(error),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15, height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 180,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tentar novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onBack,
                child: Text('Voltar', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
