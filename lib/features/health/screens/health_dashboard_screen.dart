import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/health/health_service.dart';
import '../../../core/theme/design_tokens.dart';

/// Screen showing synced Apple Health / Google Fit data.
///
/// Displays: steps, calories, heart rate, sleep.
/// Authorization flow is handled inline.
class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  bool _authorized = false;
  bool _loading = true;
  HealthSummary? _summary;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final auth = await HealthService.isAuthorized();
      if (auth) {
        await _loadData();
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestAccess() async {
    setState(() => _loading = true);
    try {
      final granted = await HealthService.requestAuthorization();
      if (granted) {
        await _loadData();
      } else {
        if (mounted) setState(() { _loading = false; });
      }
    } catch (_) {
      if (mounted) {
        setState(() { _loading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saúde não disponível neste dispositivo')),
        );
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final summary = await HealthService.getTodaySummary();
      if (mounted) {
        setState(() {
          _authorized = true;
          _summary = summary;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        title: const Text('Saúde & Wearables'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_authorized
              ? _buildAuthPrompt(primary)
              : _buildDashboard(isDark, primary),
    );
  }

  Widget _buildAuthPrompt(Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite, size: 64, color: primary),
            ),
            const SizedBox(height: 24),
            const Text('Conecte seu Apple Health\nou Google Fit',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Sincronize passos, frequência cardíaca, calorias e sono para acompanhar sua saúde.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: EagleTokens.inkMute)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _requestAccess,
                icon: const Icon(Icons.sync, color: Colors.white),
                label: const Text('Conectar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(bool isDark, Color primary) {
    final s = _summary!;
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Resumo de Hoje', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : EagleTokens.ink)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _MetricCard(
              icon: Icons.directions_walk, label: 'Passos',
              value: '${s.steps}', color: const Color(0xFF22C55E), isDark: isDark)),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(
              icon: Icons.local_fire_department, label: 'Calorias',
              value: '${s.caloriesBurned.toInt()} kcal', color: const Color(0xFFF59E0B), isDark: isDark)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _MetricCard(
              icon: Icons.favorite, label: 'FC Média',
              value: s.avgHeartRate > 0 ? '${s.avgHeartRate.toInt()} bpm' : '--',
              color: const Color(0xFFEF4444), isDark: isDark)),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(
              icon: Icons.bedtime, label: 'Sono',
              value: s.sleepHours > 0 ? '${s.sleepHours.toStringAsFixed(1)}h' : '--',
              color: const Color(0xFF8B5CF6), isDark: isDark)),
          ]),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await HealthService.revokeAccess();
              if (mounted) setState(() { _authorized = false; _summary = null; });
            },
            icon: const Icon(Icons.link_off, size: 18),
            label: const Text('Desconectar saúde'),
            style: OutlinedButton.styleFrom(foregroundColor: EagleTokens.bad),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MetricCard({
    required this.icon, required this.label,
    required this.value, required this.color, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : EagleTokens.ink)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, color: EagleTokens.inkMute)),
      ]),
    );
  }
}
