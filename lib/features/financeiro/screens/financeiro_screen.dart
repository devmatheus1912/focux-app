import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/feedback_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../features/alunos/providers/alunos_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/subscription/models/subscription_plan.dart';
import '../data/financeiro_repository.dart';
import 'financeiro_dashboard_screen.dart';
import 'financeiro_resumo_screen.dart';
import '../../../core/utils/friendly_error.dart';

class FinanceiroScreen extends ConsumerStatefulWidget {
  const FinanceiroScreen({super.key});
  @override
  ConsumerState<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends ConsumerState<FinanceiroScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _periodFilter = 'agora';

  static const Map<String, String> _periodLabels = {
    'agora': 'agora',
    'mes_atual': 'este mes',
    'mes_anterior': 'mes anterior',
    'ano': 'ano',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BUG-18: Financeiro requer plano PREMIUM ou superior
    return FeatureGate(
      featureName: 'Financeiro',
      requiredPlan: SubscriptionPlan.PREMIUM,
      capability: 'financeiro',
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primary = Theme.of(context).colorScheme.primary;

    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // V3 Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap:
                            () => safePopOrGo(context, '/dashboard/personal'),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12, bottom: 4),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: ink,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESTE MÊS',
                            style: TextStyle(
                              fontSize: 11,
                              color: mute,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Financeiro',
                            style: GoogleFonts.outfit(
                              fontSize: 30,
                              color: ink,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    initialValue: _periodFilter,
                    tooltip: 'Filtrar periodo',
                    onSelected: (value) {
                      setState(() => _periodFilter = value);
                      if (value == 'ano') {
                        _tabController.animateTo(2);
                      }
                    },
                    itemBuilder:
                        (context) =>
                            _periodLabels.entries
                                .map(
                                  (entry) => PopupMenuItem<String>(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _periodLabels[_periodFilter] ?? 'agora',
                            style: TextStyle(
                              fontSize: 12,
                              color: ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: mute,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: primary,
              labelColor: primary,
              unselectedLabelColor: mute,
              indicatorWeight: 2.5,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_outlined), text: 'Resumo'),
                Tab(
                  icon: Icon(Icons.receipt_long_outlined),
                  text: 'Mensalidades',
                ),
                Tab(icon: Icon(Icons.bar_chart_outlined), text: 'Metricas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  FinanceiroDashboardScreen(),
                  _MensalidadesTab(),
                  FinanceiroResumoScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MensalidadesTab extends ConsumerStatefulWidget {
  const _MensalidadesTab();
  @override
  ConsumerState<_MensalidadesTab> createState() => _MensalidadesTabState();
}

class _MensalidadesTabState extends ConsumerState<_MensalidadesTab> {
  List<Mensalidade> _mensalidades = [];
  List<Mensalidade> _filtered = [];
  bool _loading = true;
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
        debugPrint('[Focux] Error: $e');
        // fallback: filter locally
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
    setState(() => _loading = true);
    try {
      final r =
          await FinanceiroRepository(ref.read(apiClientProvider)).listar();
      setState(() {
        _mensalidades = r;
        _filtered = r;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      setState(() => _loading = false);
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setModalState) => Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Editar Mensalidade',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: valorCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Valor (R\$)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
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
                          decoration: const InputDecoration(
                            labelText: 'Mês Referência',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_month),
                            hintText: '2026-04-01',
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
                              mesReferenciaCtrl.text = '${picked.year}-$mes-01';
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
                          value: selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.flag),
                          ),
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
                        const SizedBox(height: 24),
                        FilledButton.icon(
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
                                      if (ctx.mounted) Navigator.of(ctx).pop();
                                      _load();
                                      if (mounted) {
                                        FeedbackHelper.showSuccess(context, 'Mensalidade atualizada!');
                                      }
                                    } catch (e) {
                                      setModalState(() => salvando = false);
                                      if (ctx.mounted) {
                                        FeedbackHelper.showError(ctx, friendlyError(e));
                                      }
                                    }
                                  },
                          icon:
                              salvando
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(Icons.save),
                          label: Text(salvando ? 'Salvando...' : 'Salvar'),
                        ),
                      ],
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
                        value: tipoSelecionado,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          border: OutlineInputBorder(),
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
                        decoration: const InputDecoration(
                          labelText: 'Observacao (opcional)',
                          border: OutlineInputBorder(),
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
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Registrar'),
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
                        erro = e.toString();
                        carregando = false;
                      });
                    });
              }

              return AlertDialog(
                title: const Text('PIX - Escaneie ou copie'),
                content:
                    carregando
                        ? const SizedBox(
                          height: 80,
                          child: Center(child: CircularProgressIndicator()),
                        )
                        : erro != null
                        ? Text('Erro ao gerar PIX: $erro')
                        : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.memory(
                              base64Decode(pix!.qrCodeBase64),
                              width: 200,
                              height: 200,
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              icon: const Icon(Icons.copy),
                              label: const Text('Copiar codigo PIX'),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: pix!.pixCopiaECola),
                                );
                                FeedbackHelper.showSuccess(context, 'Código PIX copiado!');
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setModalState) => Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 24,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Nova Mensalidade',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(ctx).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                                    value: alunoSelecionadoId,
                                    decoration: const InputDecoration(
                                      labelText: 'Aluno',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.person),
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
                          decoration: const InputDecoration(
                            labelText: 'Valor (R\$)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
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
                          decoration: const InputDecoration(
                            labelText: 'Mes Referencia',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_month),
                            hintText: '2026-04-01',
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
                              mesReferenciaCtrl.text = '${picked.year}-$mes-01';
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
                        const SizedBox(height: 24),
                        FilledButton.icon(
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
                                      if (ctx.mounted) Navigator.of(ctx).pop();
                                      _load();
                                      if (mounted) {
                                        FeedbackHelper.showSuccess(context, 'Mensalidade lançada com sucesso!');
                                      }
                                    } catch (e) {
                                      setModalState(() => salvando = false);
                                      if (ctx.mounted) {
                                        FeedbackHelper.showError(ctx, friendlyError(e));
                                      }
                                    }
                                  },
                          icon:
                              salvando
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(Icons.check),
                          label: Text(
                            salvando ? 'Salvando...' : 'Lancar Mensalidade',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'atualizar',
          onPressed: _atualizarAtrasos,
          tooltip: 'Atualizar atrasos',
          child: const Icon(Icons.sync),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'nova',
          onPressed: _abrirFormularioNovaMensalidade,
          tooltip: 'Nova Mensalidade',
          child: const Icon(Icons.add),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar por nome do aluno...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchCtrl.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _filtered = _mensalidades);
                        },
                      )
                      : null,
              border: const OutlineInputBorder(),
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
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? EagleTokens.darkInkMute
                      : EagleTokens.inkMute,
            ),
          ),
        ),
        Expanded(
          child:
              _loading
                  ? _buildMensalidadesLoading(context)
                  : _filtered.isEmpty
                  ? _buildMensalidadesEmpty(context)
                  : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final m = _filtered[i];
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      final primary = Theme.of(context).colorScheme.primary;
                      final card = isDark ? EagleTokens.darkCard : EagleTokens.card;
                      final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
                      final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
                      final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
                      final statusColor = _statusColor(m.status);
                      final isPending = m.status == 'PENDENTE' || m.status == 'ATRASADO';
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
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.alunoNome,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: ink,
                                          letterSpacing: -0.15,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        m.mesReferencia.substring(0, 7),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: mute,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                    color: statusColor.withValues(alpha: isDark ? 0.18 : 0.10),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    m.status,
                                    style: TextStyle(
                                      color: statusColor,
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

  Widget _buildMensalidadesLoading(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 82,
          decoration: BoxDecoration(
            color: isDark ? EagleTokens.darkCard : EagleTokens.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? EagleTokens.darkLine : EagleTokens.line,
            ),
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildMensalidadesEmpty(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primary = Theme.of(context).colorScheme.primary;
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
            style: GoogleFonts.outfit(
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
