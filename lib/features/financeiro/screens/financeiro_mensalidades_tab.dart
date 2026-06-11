import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../utils/financeiro_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_error_state.dart';
import '../data/financeiro_repository.dart';

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final r =
          await FinanceiroRepository(ref.read(apiClientProvider)).listar();
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

  InputDecoration _fxDeco(String label, {IconData? icon, String? hint}) {
    final chrome = ShellChrome.of(context);
    final line = chrome.line;
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: mute,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(color: mute.withValues(alpha: 0.5), fontSize: 13.5),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: mute) : null,
      filled: true,
      fillColor: chrome.cardFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: FxInputDeco.outlineBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: FxInputDeco.outlineBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: FxInputDeco.outlineBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 1.6),
      ),
      errorBorder: FxInputDeco.outlineBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EagleTokens.bad),
      ),
      focusedErrorBorder: FxInputDeco.outlineBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: EagleTokens.bad, width: 1.6),
      ),
    );
  }

  Future<void> _editarMensalidade(Mensalidade m) async {
    const statuses = ['PENDENTE', 'PAGO', 'ATRASADO'];
    final valorCtrl = TextEditingController(text: m.valor.toStringAsFixed(2));
    final mesReferenciaCtrl = TextEditingController(
      text: m.mesReferencia.length >= 7 ? m.mesReferencia : m.mesReferencia,
    );
    String selectedStatus = m.status;
    bool salvando = false;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: ShellSurface(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: StatefulBuilder(
                builder:
                    (ctx, setModalState) => Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Editar Mensalidade',
                                  style: AppTypography.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: TokensStrip.s4),
                          TextFormField(
                            controller: valorCtrl,
                            decoration: _fxDeco(
                              'Valor (R\$)',
                              icon: Icons.attach_money,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Informe o valor';
                              }
                              final parsed = double.tryParse(
                                v.trim().replaceAll(',', '.'),
                              );
                              if (parsed == null || parsed <= 0) {
                                return 'Valor inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: mesReferenciaCtrl,
                            decoration: _fxDeco(
                              'Mês Referência',
                              icon: Icons.calendar_month,
                              hint: '2026-04-01',
                            ),
                            readOnly: true,
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate:
                                    DateTime.tryParse(mesReferenciaCtrl.text) ??
                                    DateTime(now.year, now.month, 1),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(now.year + 5),
                                selectableDayPredicate: (day) => day.day == 1,
                              );
                              if (picked != null) {
                                final mes = picked.month.toString().padLeft(
                                  2,
                                  '0',
                                );
                                mesReferenciaCtrl.text =
                                    '${picked.year}-$mes-01';
                              }
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Selecione o mês de referência';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: selectedStatus,
                            decoration: _fxDeco('Status', icon: Icons.flag),
                            items:
                                statuses
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (v) => setModalState(
                                  () => selectedStatus = v ?? selectedStatus,
                                ),
                          ),
                          const SizedBox(height: TokensStrip.s5),
                          FxLiquidPrimaryButton(
                            label: salvando ? 'Salvando...' : 'Salvar',
                            icon: Icons.save,
                            loading: salvando,
                            onPressed:
                                salvando
                                    ? null
                                    : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setModalState(() => salvando = true);
                                      try {
                                        final valor = double.parse(
                                          valorCtrl.text.trim().replaceAll(
                                            ',',
                                            '.',
                                          ),
                                        );
                                        await FinanceiroRepository(
                                          ref.read(apiClientProvider),
                                        ).editarMensalidade(
                                          m.id,
                                          valor: valor,
                                          mesReferencia:
                                              mesReferenciaCtrl.text.trim(),
                                          status: selectedStatus,
                                        );
                                        if (ctx.mounted) {
                                          Navigator.of(ctx).pop();
                                        }
                                        _load();
                                        if (mounted) {
                                          FeedbackHelper.showSuccess(
                                            context,
                                            'Mensalidade atualizada!',
                                          );
                                        }
                                      } catch (e) {
                                        setModalState(() => salvando = false);
                                        if (ctx.mounted) {
                                          FeedbackHelper.showError(
                                            ctx,
                                            friendlyError(e),
                                          );
                                        }
                                      }
                                    },
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ),
    );
  }

  Future<void> _atualizarAtrasos() async {
    try {
      await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).atualizarAtrasos();
      _load();
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Mensalidades atualizadas!');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _registrarContato(Mensalidade m) async {
    const tipos = ['WHATSAPP', 'LIGACAO', 'EMAIL', 'PRESENCIAL', 'OUTRO'];
    String? tipoSelecionado = tipos.first;
    final obsCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, set) => AlertDialog(
                  title: const Text('Registrar Contato'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: tipoSelecionado,
                        decoration: InputDecoration(
                          labelText: 'Tipo',
                          border: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items:
                            tipos
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => set(() => tipoSelecionado = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: obsCtrl,
                        decoration: InputDecoration(
                          labelText: 'Observação (opcional)',
                          border: FxInputDeco.outlineBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    FxLiquidPrimaryButton(
                      label: 'Registrar',
                      expand: false,
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
          ),
    );
    if (confirm != true || tipoSelecionado == null) return;
    try {
      await FinanceiroRepository(
        ref.read(apiClientProvider),
      ).registrarContato(m.id, tipoSelecionado!, obsCtrl.text.trim());
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Contato registrado!');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _pagar(int id) async {
    try {
      await FinanceiroRepository(ref.read(apiClientProvider)).pagar(id);
      _load();
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _mostrarPix(int id) async {
    PixData? pix;
    bool carregando = true;
    String? erro;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setDialogState) {
              if (carregando && pix == null && erro == null) {
                FinanceiroRepository(ref.read(apiClientProvider))
                    .gerarPix(id)
                    .then((p) {
                      setDialogState(() {
                        pix = p;
                        carregando = false;
                      });
                    })
                    .catchError((e) {
                      setDialogState(() {
                        erro = friendlyError(e);
                        carregando = false;
                      });
                    });
              }

              return AlertDialog(
                title: const Text('PIX - Escaneie ou copie'),
                content:
                    carregando
                        ? const SizedBox(height: 80, child: FxLoading())
                        : erro != null
                        ? Text(erro!)
                        : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.memory(
                              base64Decode(pix!.qrCodeBase64),
                              width: 200,
                              height: 200,
                            ),
                            const SizedBox(height: TokensStrip.s4),
                            TextButton.icon(
                              icon: const Icon(Icons.copy),
                              label: const Text('Copiar codigo PIX'),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: pix!.pixCopiaECola),
                                );
                                FeedbackHelper.showSuccess(
                                  context,
                                  'Código PIX copiado!',
                                );
                              },
                            ),
                          ],
                        ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _abrirFormularioNovaMensalidade() {
    final formKey = GlobalKey<FormState>();
    final valorCtrl = TextEditingController();
    final mesReferenciaCtrl = TextEditingController();
    int? alunoSelecionadoId;
    bool salvando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: ShellSurface(
              radius: 28,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: StatefulBuilder(
                builder:
                    (ctx, setModalState) => Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Nova Mensalidade',
                                  style: AppTypography.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                          const SizedBox(height: TokensStrip.s4),
                          ref
                              .watch(alunosProvider)
                              .when(
                                loading: () => const LinearProgressIndicator(),
                                error:
                                    (e, _) => Text(
                                      'Nao foi possivel carregar alunos.',
                                      style: TextStyle(
                                        color: Theme.of(ctx).colorScheme.error,
                                      ),
                                    ),
                                data:
                                    (alunos) => DropdownButtonFormField<int>(
                                      initialValue: alunoSelecionadoId,
                                      decoration: _fxDeco(
                                        'Aluno',
                                        icon: Icons.person,
                                      ),
                                      items:
                                          alunos
                                              .map(
                                                (a) => DropdownMenuItem<int>(
                                                  value: a.id,
                                                  child: Text(a.nome),
                                                ),
                                              )
                                              .toList(),
                                      onChanged:
                                          (value) => setModalState(
                                            () => alunoSelecionadoId = value,
                                          ),
                                      validator:
                                          (value) =>
                                              value == null
                                                  ? 'Selecione um aluno'
                                                  : null,
                                    ),
                              ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: valorCtrl,
                            decoration: _fxDeco(
                              'Valor (R\$)',
                              icon: Icons.attach_money,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Informe o valor';
                              }
                              final parsed = double.tryParse(
                                v.trim().replaceAll(',', '.'),
                              );
                              if (parsed == null || parsed <= 0) {
                                return 'Valor invalido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: mesReferenciaCtrl,
                            decoration: _fxDeco(
                              'Mês Referência',
                              icon: Icons.calendar_month,
                              hint: '2026-04-01',
                            ),
                            readOnly: true,
                            onTap: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: DateTime(now.year, now.month, 1),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(now.year + 5),
                                helpText: 'Selecione o mes de referencia',
                                fieldLabelText: 'Mes/Ano',
                                initialEntryMode:
                                    DatePickerEntryMode.calendarOnly,
                                selectableDayPredicate: (day) => day.day == 1,
                              );
                              if (picked != null) {
                                final mes = picked.month.toString().padLeft(
                                  2,
                                  '0',
                                );
                                mesReferenciaCtrl.text =
                                    '${picked.year}-$mes-01';
                              }
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Selecione o mes de referencia';
                              }
                              if (!RegExp(
                                r'^\d{4}-\d{2}-01$',
                              ).hasMatch(v.trim())) {
                                return 'Formato invalido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: TokensStrip.s5),
                          FxLiquidPrimaryButton(
                            label:
                                salvando ? 'Salvando...' : 'Lancar Mensalidade',
                            icon: Icons.check,
                            loading: salvando,
                            onPressed:
                                salvando
                                    ? null
                                    : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setModalState(() => salvando = true);
                                      try {
                                        final alunoId = alunoSelecionadoId!;
                                        final valor = double.parse(
                                          valorCtrl.text.trim().replaceAll(
                                            ',',
                                            '.',
                                          ),
                                        );
                                        final mesReferencia =
                                            mesReferenciaCtrl.text.trim();
                                        await FinanceiroRepository(
                                          ref.read(apiClientProvider),
                                        ).criar(alunoId, valor, mesReferencia);
                                        if (ctx.mounted) {
                                          Navigator.of(ctx).pop();
                                        }
                                        _load();
                                        if (mounted) {
                                          FeedbackHelper.showSuccess(
                                            context,
                                            'Mensalidade lançada com sucesso!',
                                          );
                                        }
                                      } catch (e) {
                                        setModalState(() => salvando = false);
                                        if (ctx.mounted) {
                                          FeedbackHelper.showError(
                                            ctx,
                                            friendlyError(e),
                                          );
                                        }
                                      }
                                    },
                          ),
                        ],
                      ),
                    ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
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
                    ? DashboardErrorState(
                      chromeOnDark: chrome.isDark,
                      primary: primary,
                      message: _erro!,
                      onRetry: _load,
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
                        final statusColor = _statusColor(m.status);
                        final isPending =
                            m.status == 'PENDENTE' || m.status == 'ATRASADO';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: fxListCardDecoration(context, radius: 20),
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
                                          style: FinanceiroTypography.alunoNome(
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
                                    style: FinanceiroTypography.valorMonetario(
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
                                      icon: Icons.check_circle_outline_rounded,
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
    );
  }

  Widget _buildMensalidadesLoading(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 4, 16, 80),
      itemCount: 5,
      itemBuilder:
          (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 82,
              decoration: fxListCardDecoration(context, radius: 20),
              child: const SizedBox.shrink(),
            ),
          ),
    );
  }

  Widget _buildMensalidadesEmpty(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: chrome.isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.receipt_long_rounded, color: primary, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhuma mensalidade',
            style: AppTypography.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque + para lançar a primeira.',
            style: TextStyle(color: mute, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MiniAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: chrome.headerAction(radius: 10),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
