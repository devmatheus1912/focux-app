import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/financeiro_repository.dart';
import 'financeiro_dashboard_screen.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabController,
      children: const [
        FinanceiroDashboardScreen(),
        _MensalidadesTab(),
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
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await FinanceiroRepository(ref.read(apiClientProvider)).listar();
      setState(() { _mensalidades = r; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'PAGO': return Colors.green;
      case 'ATRASADO': return Colors.red;
      default: return Colors.orange;
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
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _mensalidades.isEmpty
            ? const Center(child: Text('Nenhuma mensalidade lançada.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _mensalidades.length,
                itemBuilder: (_, i) {
                  final m = _mensalidades[i];
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
                        if (m.status == 'PENDENTE' || m.status == 'ATRASADO') ...[
                          IconButton(
                            icon: const Icon(Icons.phone_in_talk, size: 20),
                            tooltip: 'Registrar contato',
                            onPressed: () => _registrarContato(m),
                          ),
                          IconButton(
                            icon: const Icon(Icons.pix, color: Colors.teal),
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
  );
}
