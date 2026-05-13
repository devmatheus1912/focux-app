import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/friendly_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';

class FinanceiroAlunoScreen extends ConsumerStatefulWidget {
  const FinanceiroAlunoScreen({super.key});

  @override
  ConsumerState<FinanceiroAlunoScreen> createState() => _FinanceiroAlunoScreenState();
}

class _FinanceiroAlunoScreenState extends ConsumerState<FinanceiroAlunoScreen> {
  List<Mensalidade> _mensalidades = [];
  bool _loading = true;
  String? _erro;

  static const _mesesNomes = [
    '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final result = await FinanceiroRepository(ref.read(apiClientProvider))
          .minhasMensalidades();
      if (mounted) setState(() { _mensalidades = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = friendlyError(e); _loading = false; });
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PAGO': return EagleTokens.good;
      case 'ATRASADO': return EagleTokens.bad;
      default: return EagleTokens.warn;
    }
  }

  String _formatarMes(String mesReferencia) {
    // mesReferencia format: "2026-04-01"
    try {
      final parts = mesReferencia.split('-');
      if (parts.length < 2) return mesReferencia;
      final ano = parts[0];
      final mes = int.parse(parts[1]);
      if (mes < 1 || mes > 12) return mesReferencia;
      return '${_mesesNomes[mes]} $ano';
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      return mesReferencia;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Minhas Mensalidades',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _carregar,
            tooltip: 'Recarregar',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          : _erro != null
              ? _buildError(isDark, ink, mute, primary)
              : _mensalidades.isEmpty
                  ? _buildEmpty(isDark, ink, mute, primary)
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: _mensalidades.length,
                        itemBuilder: (_, i) => _MensalidadeCard(
                          m: _mensalidades[i],
                          isDark: isDark,
                          formatarMes: _formatarMes,
                          statusColor: _statusColor,
                        ),
                      ),
                    ),
    );
  }

  Widget _buildError(bool isDark, Color ink, Color mute, Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: EagleTokens.bad.withValues(alpha: isDark ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.cloud_off_rounded, color: EagleTokens.bad, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              'Erro ao carregar',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: ink),
            ),
            const SizedBox(height: 4),
            Text(
              _erro ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: mute, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar novamente'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primary,
                side: BorderSide(color: primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark, Color ink, Color mute, Color primary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.receipt_long_rounded, color: primary, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhuma mensalidade',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: ink),
          ),
          const SizedBox(height: 4),
          Text(
            'Suas cobranças aparecerão aqui.',
            style: TextStyle(color: mute, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MensalidadeCard extends StatelessWidget {
  final Mensalidade m;
  final bool isDark;
  final String Function(String) formatarMes;
  final Color Function(String) statusColor;

  const _MensalidadeCard({
    required this.m,
    required this.isDark,
    required this.formatarMes,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final sColor = statusColor(m.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatarMes(m.mesReferencia),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: ink,
                    letterSpacing: -0.15,
                  ),
                ),
              ),
              Text(
                'R\$ ${m.valor.toStringAsFixed(0)}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: sColor.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  m.status,
                  style: TextStyle(
                    color: sColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const Spacer(),
              if (m.pagoEm != null)
                Text(
                  'Pago em ${m.pagoEm}',
                  style: TextStyle(
                    fontSize: 11,
                    color: EagleTokens.good,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
