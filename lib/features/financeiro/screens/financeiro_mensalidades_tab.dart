import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../utils/financeiro_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';
import '../providers/financeiro_provider.dart';
import '../utils/financeiro_mensalidade_status.dart';

part 'financeiro_mensalidades_tab_actions.part.dart';
part 'financeiro_mensalidades_tab_widgets.part.dart';

class FinanceiroMensalidadesTab extends ConsumerStatefulWidget {
  const FinanceiroMensalidadesTab({super.key, this.initialAlunoId});

  final int? initialAlunoId;

  @override
  ConsumerState<FinanceiroMensalidadesTab> createState() =>
      _FinanceiroMensalidadesTabState();
}

class _FinanceiroMensalidadesTabState
    extends ConsumerState<FinanceiroMensalidadesTab> {
  List<Mensalidade> _mensalidades = [];
  List<Mensalidade> _filtered = [];
  bool _loading = true;
  String? _erro;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() => _filtered = _mensalidades);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final results = await FinanceiroRepository(
          ref.read(apiClientProvider),
        ).listarPorNome(query);
        if (mounted) setState(() => _filtered = results);
      } catch (e) {
        // fallback: filter locally quando a busca remota falha
        if (mounted) {
          setState(
            () =>
                _filtered =
                    _mensalidades
                        .where(
                          (m) => m.alunoNome.toLowerCase().contains(
                            query.toLowerCase(),
                          ),
                        )
                        .toList(),
          );
        }
      }
    });
  }

  Future<void> _load({bool force = false}) async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      if (force) {
        invalidateFinanceiroCaches(ref);
      }
      final home = await ref.read(financeiroHomeProvider.future);
      final r = home.mensalidades;
      final alunoFilter = widget.initialAlunoId;
      final filtered =
          alunoFilter == null
              ? r
              : r.where((m) => m.alunoId == alunoFilter).toList();
      if (!mounted) return;
      setState(() {
        _mensalidades = r;
        _filtered = filtered;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;
    return fxScreenA11yScope(
      label: 'Mensalidades',
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.small(
              heroTag: 'atualizar',
              onPressed: _atualizarAtrasos,
              tooltip: 'Atualizar atrasos',
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              foregroundColor: Theme.of(context).colorScheme.primary,
              elevation: 0,
              child: const Icon(Icons.sync_rounded, size: 20),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'nova',
              onPressed: _abrirFormularioNovaMensalidade,
              tooltip: 'Nova Mensalidade',
              elevation: 0,
              child: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 12, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por nome do aluno...',
                  hintStyle: TextStyle(
                    color: mute,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: mute, size: 20),
                  suffixIcon:
                      _searchCtrl.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _filtered = _mensalidades);
                            },
                          )
                          : null,
                  filled: true,
                  fillColor: chrome.cardFill,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: FxInputDeco.outlineBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: chrome.line),
                  ),
                  enabledBorder: FxInputDeco.outlineBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: chrome.line),
                  ),
                  focusedBorder: FxInputDeco.outlineBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: primary, width: 1.6),
                  ),
                  isDense: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                'HISTÓRICO DE TRANSAÇÕES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: mute,
                ),
              ),
            ),
            Expanded(
              child:
                  _loading
                      ? _buildMensalidadesLoading(context)
                      : _erro != null
                      ? FxErrorState(
                        chromeOnDark: chrome.isDark,
                        primary: primary,
                        message: _erro!,
                        onRetry: () => _load(force: true),
                      )
                      : _filtered.isEmpty
                      ? _buildMensalidadesEmpty(context)
                      : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          4,
                          16,
                          80,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final m = _filtered[i];
                          final ink = chrome.ink;
                          final mute = chrome.mute;
                          final statusColor = financeiroMensalidadeStatusColor(
                            m.status,
                          );
                          final isPending =
                              m.status == 'PENDENTE' || m.status == 'ATRASADO';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: fxListCardDecoration(
                              context,
                              radius: 20,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.alunoNome,
                                            style:
                                                FinanceiroTypography.alunoNome(
                                                  context,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            m.mesReferencia.substring(0, 7),
                                            style: FinanceiroTypography.meta(
                                              context,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'R\$ ${m.valor.toStringAsFixed(0)}',
                                      style:
                                          FinanceiroTypography.valorMonetario(
                                            context,
                                            color: ink,
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
                                        color: statusColor.withValues(
                                          alpha: chrome.isDark ? 0.18 : 0.10,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        financeiroMensalidadeStatusLabel(
                                          m.status,
                                        ),
                                        style: TextStyle(
                                          color: financeiroMensalidadeStatusInk(
                                            statusColor,
                                            status: m.status,
                                            isDark: chrome.isDark,
                                          ),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    _MiniAction(
                                      icon: Icons.edit_rounded,
                                      color: mute,
                                      onTap: () => _editarMensalidade(m),
                                    ),
                                    if (isPending) ...[
                                      const SizedBox(width: 6),
                                      _MiniAction(
                                        icon: Icons.chat_bubble_outline_rounded,
                                        color: mute,
                                        onTap: () => _cobrarViaChat(m),
                                      ),
                                      const SizedBox(width: 6),
                                      _MiniAction(
                                        icon: Icons.phone_in_talk_rounded,
                                        color: mute,
                                        onTap: () => _registrarContato(m),
                                      ),
                                      const SizedBox(width: 6),
                                      _MiniAction(
                                        icon: Icons.pix_rounded,
                                        color: primary,
                                        onTap: () => _mostrarPix(m.id),
                                      ),
                                      const SizedBox(width: 6),
                                      _MiniAction(
                                        icon:
                                            Icons.check_circle_outline_rounded,
                                        color: EagleTokens.good,
                                        onTap: () => _pagar(m.id),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
