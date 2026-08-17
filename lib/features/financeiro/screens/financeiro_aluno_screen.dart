import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/widgets/fx_empty_state.dart';
import 'package:focux_app/core/widgets/fx_error_state.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import 'package:focux_app/core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/skeleton_loader.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../features/alunos/utils/satellite_screen_utils.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';

class FinanceiroAlunoScreen extends ConsumerStatefulWidget {
  const FinanceiroAlunoScreen({super.key});

  @override
  ConsumerState<FinanceiroAlunoScreen> createState() =>
      _FinanceiroAlunoScreenState();
}

class _FinanceiroAlunoScreenState extends ConsumerState<FinanceiroAlunoScreen> {
  List<Mensalidade> _mensalidades = [];
  bool _loading = true;
  String? _erro;

  static const _mesesNomes = [
    '',
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final result =
          await FinanceiroRepository(
            ref.read(apiClientProvider),
          ).minhasMensalidades();
      if (mounted) {
        setState(() {
          _mensalidades = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PAGO':
        return EagleTokens.good;
      case 'ATRASADO':
        return EagleTokens.bad;
      default:
        return EagleTokens.warn;
    }
  }

  String _formatarMes(String mesReferencia) {
    try {
      final parts = mesReferencia.split('-');
      if (parts.length < 2) return mesReferencia;
      final ano = parts[0];
      final mes = int.parse(parts[1]);
      if (mes < 1 || mes > 12) return mesReferencia;
      return '${_mesesNomes[mes]} $ano';
    } catch (_) {
      return mesReferencia;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Minhas Mensalidades',
      child: FxShellScaffold(
        appBar: FxShellAppBar(
          title: 'Minhas Mensalidades',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22),
              onPressed: _carregar,
              tooltip: 'Recarregar',
            ),
          ],
        ),
        body:
            _loading
                ? const Padding(
                  padding: EdgeInsets.all(TokensStrip.s4),
                  child: SkeletonList(count: 5),
                )
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: isDark,
                  primary: primary,
                  title: FocuxMicrocopy.naoFoiPossivelCarregar,
                  message: _erro!,
                  onRetry: _carregar,
                )
                : _mensalidades.isEmpty
                ? RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 72),
                      FxEmptyState(
                        icon: 'coin',
                        title: 'Nenhuma mensalidade',
                        subtitle: 'Suas cobranças aparecerão aqui.',
                      ),
                    ],
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      8,
                      16,
                      32,
                    ),
                    itemCount: _mensalidades.length,
                    itemBuilder:
                        (_, i) => _MensalidadeCard(
                          m: _mensalidades[i],
                          isDark: isDark,
                          formatarMes: _formatarMes,
                          statusColor: _statusColor,
                        ),
                  ),
                ),
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
    final chrome = ShellChrome.forDark(isDark);
    final sColor = statusColor(m.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: chrome.listCard(),
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
                    color: chrome.ink,
                    letterSpacing: -0.15,
                  ),
                ),
              ),
              Text(
                'R\$ ${m.valor.toStringAsFixed(0)}',
                style: AppTypography.mono(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: chrome.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: sColor.withValues(alpha: isDark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  financeiroMensalidadeStatusLabel(m.status),
                  style: TextStyle(
                    color: financeiroMensalidadeStatusInk(
                      sColor,
                      status: m.status,
                      isDark: isDark,
                    ),
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
