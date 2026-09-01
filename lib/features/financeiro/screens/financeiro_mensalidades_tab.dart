import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';
import '../providers/financeiro_provider.dart';
import '../utils/financeiro_hub_display.dart';

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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              8,
              FxSettingsLayout.pageInset,
              4,
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar por nome do aluno',
                hintStyle: TextStyle(
                  color: mute,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FxIcon(name: 'search', size: 18, color: mute),
                ),
                suffixIcon:
                    _searchCtrl.text.isNotEmpty
                        ? IconButton(
                          tooltip: 'Limpar busca',
                          icon: FxIcon(name: 'x', size: 16, color: mute),
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
                    : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        8,
                        FxSettingsLayout.pageInset,
                        110,
                      ),
                      children: [
                        FxSettingsGroup(
                          children: [
                            FxSettingsTile(
                              fxIcon: 'plus',
                              label: 'Nova mensalidade',
                              value: '',
                              onTap: _abrirFormularioNovaMensalidade,
                            ),
                            FxSettingsTile(
                              fxIcon: 'calendar',
                              label: 'Atualizar atrasos',
                              value: '',
                              showDivider: false,
                              onTap: _atualizarAtrasos,
                            ),
                          ],
                        ),
                        const SizedBox(height: FxSettingsLayout.groupGap),
                        FxSettingsGroup(
                          header: 'Lançamentos',
                          caption: 'Toque na linha para editar, PIX ou marcar paga.',
                          children: [
                            for (var i = 0; i < _filtered.length; i++)
                              FxSettingsTile(
                                fxIcon: _filtered[i].status == 'ATRASADO'
                                    ? 'alert-triangle'
                                    : _filtered[i].status == 'PAGO'
                                        ? 'circle-check'
                                        : 'coin',
                                label: _filtered[i].alunoNome,
                                subtitle: financeiroMensalidadeSubtitle(
                                  _filtered[i].status,
                                  _filtered[i].mesReferencia,
                                ),
                                value: formatBrlCurrency(
                                  _filtered[i].valor,
                                  showDecimals: false,
                                ),
                                numeric: true,
                                danger: _filtered[i].status == 'ATRASADO',
                                showDivider: i != _filtered.length - 1,
                                onTap: () => _abrirAcoes(_filtered[i]),
                              ),
                          ],
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
