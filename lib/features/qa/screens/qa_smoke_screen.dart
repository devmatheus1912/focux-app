import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../data/qa_endpoint_runner.dart';
import '../data/qa_smoke_catalog.dart';
import '../widgets/qa_route_preview.dart';
import '../../../core/theme/tokens_strip.dart';

/// Tela QA — navega por todas as rotas de smoke test catalogadas.
///
/// Apenas disponível em debug/profile mode.
/// Para cada rota, exibe status (✅ visitada, ⏳ pendente, ❌ erro).
class QaSmokeScreen extends StatefulWidget {
  const QaSmokeScreen({super.key});

  @override
  State<QaSmokeScreen> createState() => _QaSmokeScreenState();
}

class _QaSmokeScreenState extends State<QaSmokeScreen> {
  final Map<String, _RouteResult> _results = {};
  final Map<String, _EndpointResult> _endpointResults = {};
  bool _running = false;
  int _currentIndex = -1;
  int _batchTotal = 0;
  String? _batchLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('🧪 QA Smoke Test'),
        actions: [
          TextButton.icon(
            onPressed: _running ? null : () => context.go('/qa/tokens-strip'),
            icon: const Icon(Icons.palette_outlined),
            label: const Text('TOKENS'),
          ),
          TextButton.icon(
            onPressed: _running ? null : _runPublicRoutes,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Públicas'),
          ),
          TextButton.icon(
            onPressed: _running ? null : _runPrivateRoutes,
            icon: const Icon(Icons.lock_open),
            label: const Text('Logadas'),
          ),
          TextButton.icon(
            onPressed: _running ? null : _runEndpoints,
            icon: const Icon(Icons.cloud_outlined),
            label: const Text('APIs'),
          ),
          TextButton.icon(
            onPressed: _resetResults,
            icon: const Icon(Icons.refresh),
            label: const Text('Limpar'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_running)
            LinearProgressIndicator(
              value:
                  _currentIndex >= 0 && _batchTotal > 0
                      ? (_currentIndex + 1) / _batchTotal
                      : null,
            ),
          if (_running && _batchLabel != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _batchLabel!,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
                  ),
                ),
              ),
            ),

          DecoratedBox(
            decoration: fxListCardDecoration(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _statChip('Rotas', qaSmokeRoutes.length, Colors.blue),
                  const SizedBox(width: 8),
                  _statChip(
                    '✅',
                    _results.values.where((r) => r.ok).length,
                    Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _statChip(
                    '❌',
                    _results.values.where((r) => !r.ok).length,
                    Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _statChip(
                    'API ✅',
                    _endpointResults.values.where((r) => r.ok).length,
                    Colors.teal,
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: qaSmokeRoutes.length,
              itemBuilder: (context, index) {
                final route = qaSmokeRoutes[index];
                final result = _results[route.id];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: fxListTileCardShell(
                    context: context,
                    child: ListTile(
                      leading: _statusIcon(result),
                      title: Text(
                        route.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _routeSubtitle(route, result, isDark),
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              result != null && !result.ok
                                  ? Colors.red.shade700
                                  : isDark
                                  ? EagleTokens.darkInkMute
                                  : TokensStrip.textSecondary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _areaChip(route.area, isDark),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.open_in_new, size: 18),
                            onPressed:
                                _running
                                    ? null
                                    : () => _navigateAndRecord(route),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'API Endpoints (${qaSmokeEndpoints.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: qaSmokeEndpoints.length,
              itemBuilder: (context, index) {
                final ep = qaSmokeEndpoints[index];
                final result = _endpointResults[ep.id];
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    leading: _endpointStatusIcon(result),
                    title: Text(ep.path, style: const TextStyle(fontSize: 12)),
                    subtitle: Text(
                      _endpointSubtitle(ep, result),
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            result != null && !result.ok
                                ? Colors.red.shade700
                                : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _routeSubtitle(
    QaSmokeRoute route,
    _RouteResult? result,
    bool isDark,
  ) {
    if (result != null && !result.ok && result.error != null) {
      return result.error!;
    }
    return '${route.authMode} • ${route.path}';
  }

  String _endpointSubtitle(QaSmokeEndpoint ep, _EndpointResult? result) {
    if (result == null) {
      return '${ep.authMode} • expect anon: ${ep.expectedAnonymousStatus}';
    }
    if (result.ok) {
      return '${ep.method} • HTTP ${result.statusCode}';
    }
    return result.error ?? '${ep.method} • falhou';
  }

  Widget _statusIcon(_RouteResult? result) {
    if (result == null) {
      return const Icon(Icons.radio_button_unchecked, color: Colors.grey);
    }
    return result.ok
        ? const Icon(Icons.check_circle, color: Colors.green)
        : const Icon(Icons.error, color: Colors.red);
  }

  Widget _endpointStatusIcon(_EndpointResult? result) {
    if (result == null) {
      return _methodChip('…');
    }
    return Icon(
      result.ok ? Icons.check_circle : Icons.error,
      color: result.ok ? Colors.green : Colors.red,
      size: 18,
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _areaChip(String area, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(area, style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _methodChip(String method) {
    Color color;
    switch (method) {
      case 'GET':
        color = Colors.green;
        break;
      case 'POST':
        color = Colors.blue;
        break;
      case 'DELETE':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Future<void> _waitForRouteTransition() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future.delayed(const Duration(milliseconds: 350));
  }

  Future<void> _navigateAndRecord(QaSmokeRoute route) async {
    if (_running) return;
    try {
      final previewError = await QaRoutePreviewDialog.show(context, route.path);
      if (!mounted) return;
      setState(() {
        _results[route.id] = _RouteResult(
          ok: previewError == null,
          error: previewError,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results[route.id] = _RouteResult(ok: false, error: e.toString());
      });
    }
  }

  Future<void> _runPublicRoutes() => _runRouteBatch(
    qaPublicRoutes,
    label: 'Testando rotas públicas…',
  );

  Future<void> _runPrivateRoutes() => _runRouteBatch(
    qaPrivateRoutes,
    label: 'Testando rotas logadas…',
  );

  Future<void> _runRouteBatch(
    List<QaSmokeRoute> routes, {
    required String label,
  }) async {
    if (_running) return;
    setState(() {
      _running = true;
      _batchTotal = routes.length;
      _currentIndex = 0;
      _batchLabel = label;
    });

    for (var i = 0; i < routes.length; i++) {
      if (!mounted) break;
      final route = routes[i];
      setState(() {
        _currentIndex = i;
        _batchLabel = '$label ${route.label}';
      });

      try {
        final previewError = await QaRoutePreviewDialog.showTimed(
          context,
          route.path,
        );
        if (!mounted) break;
        await _waitForRouteTransition();

        setState(() {
          _results[route.id] = _RouteResult(
            ok: previewError == null,
            error: previewError,
          );
        });
      } catch (e) {
        if (!mounted) break;
        setState(() {
          _results[route.id] = _RouteResult(ok: false, error: e.toString());
        });
      }
    }

    if (mounted) {
      setState(() {
        _running = false;
        _currentIndex = -1;
        _batchTotal = 0;
        _batchLabel = null;
      });
    }
  }

  Future<void> _runEndpoints() async {
    if (_running) return;
    setState(() {
      _running = true;
      _batchTotal = qaSmokeEndpoints.length;
      _currentIndex = 0;
      _batchLabel = 'Testando APIs…';
    });

    for (var i = 0; i < qaSmokeEndpoints.length; i++) {
      if (!mounted) break;
      final endpoint = qaSmokeEndpoints[i];
      setState(() {
        _currentIndex = i;
        _batchLabel = 'API ${endpoint.method} ${endpoint.path}';
      });

      final result = await runQaSmokeEndpoint(endpoint);
      if (!mounted) break;

      setState(() {
        _endpointResults[endpoint.id] = _EndpointResult(
          ok: result.ok,
          statusCode: result.statusCode,
          error: result.error,
        );
      });
    }

    if (mounted) {
      setState(() {
        _running = false;
        _currentIndex = -1;
        _batchTotal = 0;
        _batchLabel = null;
      });
    }
  }

  void _resetResults() {
    setState(() {
      _results.clear();
      _endpointResults.clear();
      _currentIndex = -1;
      _batchTotal = 0;
      _batchLabel = null;
    });
  }
}

class _RouteResult {
  final bool ok;
  final String? error;
  const _RouteResult({required this.ok, this.error});
}

class _EndpointResult {
  final bool ok;
  final int? statusCode;
  final String? error;
  const _EndpointResult({required this.ok, this.statusCode, this.error});
}
