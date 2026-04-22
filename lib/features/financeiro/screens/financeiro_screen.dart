import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';
import 'financeiro_dashboard_screen.dart';
import 'financeiro_resumo_screen.dart';

class FinanceiroScreen extends ConsumerStatefulWidget {
  const FinanceiroScreen({super.key});
  @override
  ConsumerState<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends ConsumerState<FinanceiroScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Financeiro'),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
          Tab(icon: Icon(Icons.list_alt), text: 'Mensalidades'),
          Tab(icon: Icon(Icons.bar_chart), text: 'Resumo'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabController,
      children: const [
        FinanceiroDashboardScreen(),
        _MensalidadesTab(),
        FinanceiroResumoScreen(),
      ],
    ),
  );
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
        final results = await FinanceiroRepository(ref.read(apiClientProvider)).listarPorNome(query);
        if (mounted) setState(() => _filtered = results);
      } catch (_) {
        // fallback: filter locally
        if (mounted) {
          setState(() => _filtered = _mensalidades
              .where((m) => m.alunoNome.toLowerCase().contains(query.toLowerCase()))
              .toList());
        }
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await FinanceiroRepository(ref.read(apiClientProvider)).listar();
      setState(() {
        _mensalidades = r;
        _filtered = r;
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PAGO': return EagleTokens.good;
      case 'ATRASADO': return EagleTokens.bad;
      default: return EagleTokens.warn;
    }
  }

  Future<void> _editarMensalidade(Mensalidade m) async {
    const statuses = ['PENDENTE', 'PAGO', 'ATRASADO'];
    final valorCtrl = TextEditingController(text: m.valor.toStringAsFixed(2));
    final mesReferenciaCtrl = TextEditingController(text: m.mesReferencia.length >= 7 ? m.mesReferencia : m.mesReferencia);
    String selectedStatus = m.status;
    bool salvando = false;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Expanded(child: Text('Editar Mensalidade',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                ]),
                const SizedBox(height: 16),
                TextFormField(
                  controller: valorCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Valor (R\$)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o valor';
                    final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) return 'Valor inválido';
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
                      hintText: '2026-04-01'),
                  readOnly: true,
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.tryParse(mesReferenciaCtrl.text) ?? DateTime(now.year, now.month, 1),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(now.year + 5),
                      selectableDayPredicate: (day) => day.day == 1,
                    );
                    if (picked != null) {
                      final mes = picked.month.toString().padLeft(2, '0');
                      mesReferenciaCtrl.text = '${picked.year}-$mes-01';
                    }
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Selecione o mês de referência';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag)),
                  items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setModalState(() => selectedStatus = v ?? selectedStatus),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: salvando ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    setModalState(() => salvando = true);
                    try {
                      final valor = double.parse(valorCtrl.text.trim().replaceAll(',', '.'));
                      await FinanceiroRepository(ref.read(apiClientProvider)).editarMensalidade(
                        m.id,
                        valor: valor,
                        mesReferencia: mesReferenciaCtrl.text.trim(),
                        status: selectedStatus,
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      _load();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mensalidade atualizada!')));
                    } catch (e) {
                      setModalState(() => salvando = false);
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Erro ao salvar: $e')));
                    }
                  },
                  icon: salvando
                      ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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

  Future<void> _cobrarViaChat(Mensalidade m) async {
    try {
      final msg = await FinanceiroRepository(ref.read(apiClientProvider)).cobrarViaChat(m.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _atualizarAtrasos() async {
    try {
      await FinanceiroRepository(ref.read(apiClientProvider)).atualizarAtrasos();
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensalidades atualizadas!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _registrarContato(Mensalidade m) async {
    const tipos = ['WHATSAPP', 'LIGACAO', 'EMAIL', 'PRESENCIAL', 'OUTRO'];
    String? tipoSelecionado = tipos.first;
    final obsCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Registrar Contato'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: tipoSelecionado,
              decoration: const InputDecoration(labelText: 'Tipo', border: OutlineInputBorder()),
              items: tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => set(() => tipoSelecionado = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: obsCtrl,
              decoration: const InputDecoration(labelText: 'Observação (opcional)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Registrar')),
          ],
        ),
      ),
    );
    if (confirm != true || tipoSelecionado == null) return;
    try {
      await FinanceiroRepository(ref.read(apiClientProvider))
          .registrarContato(m.id, tipoSelecionado!, obsCtrl.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contato registrado!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _pagar(int id) async {
    try {
      await FinanceiroRepository(ref.read(apiClientProvider)).pagar(id);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _mostrarPix(int id) async {
    PixData? pix;
    bool carregando = true;
    String? erro;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (carregando && pix == null && erro == null) {
            FinanceiroRepository(ref.read(apiClientProvider))
                .gerarPix(id)
                .then((p) {
              setDialogState(() { pix = p; carregando = false; });
            }).catchError((e) {
              setDialogState(() { erro = e.toString(); carregando = false; });
            });
          }

          return AlertDialog(
            title: const Text('PIX — Escaneie ou copie'),
            content: carregando
                ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
                : erro != null
                    ? Text('Erro ao gerar PIX: $erro')
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.memory(base64Decode(pix!.qrCodeBase64), width: 200, height: 200),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            icon: const Icon(Icons.copy),
                            label: const Text('Copiar código PIX'),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: pix!.pixCopiaECola));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Código PIX copiado!')));
                            },
                          ),
                        ],
                      ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fechar')),
            ],
          );
        },
      ),
    );
  }

  void _abrirFormularioNovaMensalidade() {
    final formKey = GlobalKey<FormState>();
    final alunoIdCtrl = TextEditingController();
    final valorCtrl = TextEditingController();
    final mesReferenciaCtrl = TextEditingController();
    bool salvando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Expanded(child: Text('Nova Mensalidade',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                ]),
                const SizedBox(height: 16),
                TextFormField(
                  controller: alunoIdCtrl,
                  decoration: const InputDecoration(labelText: 'ID do Aluno',
                    border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o ID do aluno';
                    if (int.tryParse(v.trim()) == null) return 'ID inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: valorCtrl,
                  decoration: const InputDecoration(labelText: 'Valor (R\$)',
                    border: OutlineInputBorder(), prefixIcon: Icon(Icons.attach_money)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe o valor';
                    final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
                    if (parsed == null || parsed <= 0) return 'Valor inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: mesReferenciaCtrl,
                  decoration: const InputDecoration(labelText: 'Mês Referência',
                    border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_month),
                    hintText: '2026-04-01'),
                  readOnly: true,
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime(now.year, now.month, 1),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(now.year + 5),
                      helpText: 'Selecione o mês de referência',
                      fieldLabelText: 'Mês/Ano',
                      initialEntryMode: DatePickerEntryMode.calendarOnly,
                      selectableDayPredicate: (day) => day.day == 1,
                    );
                    if (picked != null) {
                      final mes = picked.month.toString().padLeft(2, '0');
                      mesReferenciaCtrl.text = '${picked.year}-$mes-01';
                    }
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Selecione o mês de referência';
                    if (!RegExp(r'^\d{4}-\d{2}-01$').hasMatch(v.trim())) return 'Formato inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: salvando ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    setModalState(() => salvando = true);
                    try {
                      final alunoId = int.parse(alunoIdCtrl.text.trim());
                      final valor = double.parse(valorCtrl.text.trim().replaceAll(',', '.'));
                      final mesReferencia = mesReferenciaCtrl.text.trim();
                      await FinanceiroRepository(ref.read(apiClientProvider))
                          .criar(alunoId, valor, mesReferencia);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      _load();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mensalidade lançada com sucesso!')));
                    } catch (e) {
                      setModalState(() => salvando = false);
                      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Erro ao lançar mensalidade: $e')));
                    }
                  },
                  icon: salvando
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check),
                  label: Text(salvando ? 'Salvando...' : 'Lançar Mensalidade'),
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
              suffixIcon: _searchCtrl.text.isNotEmpty
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
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('Nenhuma mensalidade encontrada.'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final m = _filtered[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(m.alunoNome),
                            subtitle: Text('${m.mesReferencia.substring(0, 7)} • R\$ ${m.valor.toStringAsFixed(2)}'),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Chip(
                                label: Text(m.status),
                                backgroundColor: _statusColor(m.status).withValues(alpha: 0.15),
                                labelStyle: TextStyle(color: _statusColor(m.status), fontSize: 12),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                tooltip: 'Editar mensalidade',
                                onPressed: () => _editarMensalidade(m),
                              ),
                              if (m.status == 'PENDENTE' || m.status == 'ATRASADO') ...[
                                IconButton(
                                  icon: const Icon(Icons.phone_in_talk, size: 20),
                                  tooltip: 'Registrar contato',
                                  onPressed: () => _registrarContato(m),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.pix, color: EagleTokens.brand),
                                  onPressed: () => _mostrarPix(m.id),
                                  tooltip: 'Gerar PIX',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline),
                                  onPressed: () => _pagar(m.id),
                                ),
                              ],
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ],
    ),
  );
}
