import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../data/qa_smoke_catalog.dart';

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
  bool _running = false;
  int _currentIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('🧪 QA Smoke Test'),
        actions: [
          TextButton.icon(
            onPressed: _running ? null : _runPublicRoutes,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Testar Públicas'),
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
          // Progress bar
          if (_running)
            LinearProgressIndicator(
              value:
                  _currentIndex >= 0
                      ? (_currentIndex + 1) / qaSmokeRoutes.length
                      : null,
            ),

          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? EagleTokens.darkCard : EagleTokens.card,
            child: Row(
              children: [
                _statChip('Total', qaSmokeRoutes.length, Colors.blue),
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
                  '⏳',
                  qaSmokeRoutes.length - _results.length,
                  Colors.orange,
                ),
              ],
            ),
          ),

          // Routes list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: qaSmokeRoutes.length,
              itemBuilder: (context, index) {
                final route = qaSmokeRoutes[index];
                final result = _results[route.id];

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isDark ? EagleTokens.darkCard : Colors.white,
                  child: ListTile(
                    leading: _statusIcon(result),
                    title: Text(
                      route.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${route.authMode} • ${route.path}',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? EagleTokens.darkInkMute
                                : EagleTokens.inkMute,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _areaChip(route.area, isDark),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 18),
                          onPressed: () => _navigateAndRecord(route),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Endpoints section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'API Endpoints (${qaSmokeEndpoints.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    dense: true,
                    leading: _methodChip(ep.method),
                    title: Text(ep.path, style: const TextStyle(fontSize: 12)),
                    subtitle: Text(
                      '${ep.authMode} • expect: ${ep.expectedAnonymousStatus}',
                      style: const TextStyle(fontSize: 10),
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

  Widget _statusIcon(_RouteResult? result) {
    if (result == null) {
      return const Icon(Icons.radio_button_unchecked, color: Colors.grey);
    }
    return result.ok
        ? const Icon(Icons.check_circle, color: Colors.green)
        : const Icon(Icons.error, color: Colors.red);
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

  Future<void> _navigateAndRecord(QaSmokeRoute route) async {
    try {
      if (mounted) {
        context.push(route.path);
      }
      // Registra como visitada com sucesso se não crashou
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _results[route.id] = _RouteResult(ok: true);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results[route.id] = _RouteResult(ok: false, error: e.toString());
        });
      }
    }
  }

  Future<void> _runPublicRoutes() async {
    setState(() => _running = true);

    for (int i = 0; i < qaPublicRoutes.length; i++) {
      if (!mounted) break;
      setState(() => _currentIndex = i);
      final route = qaPublicRoutes[i];

      try {
        context.push(route.path);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _results[route.id] = _RouteResult(ok: true);
          });
          // Go back
          if (context.canPop()) context.pop();
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _results[route.id] = _RouteResult(ok: false, error: e.toString());
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _running = false;
        _currentIndex = -1;
      });
    }
  }

  void _resetResults() {
    setState(() {
      _results.clear();
      _currentIndex = -1;
    });
  }
}

class _RouteResult {
  final bool ok;
  final String? error;
  const _RouteResult({required this.ok, this.error});
}
