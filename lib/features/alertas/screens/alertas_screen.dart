import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/alertas_repository.dart';

class AlertasScreen extends ConsumerStatefulWidget {
  const AlertasScreen({super.key});

  @override
  ConsumerState<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends ConsumerState<AlertasScreen> {
  List<AlertaRisco> _alertas = [];
  AlertasConfiguracao? _config;
  bool _loading = true;
  int? _filtroScoreMin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = AlertasRepository(ref.read(apiClientProvider));
      final results = await Future.wait([repo.listarRiscos(), repo.getConfiguracao()]);
      if (mounted) {
        setState(() {
          _alertas = results[0] as List<AlertaRisco>;
          _config = results[1] as AlertasConfiguracao;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editarConfiguracao() async {
    if (_config == null) return;
    int dias = _config!.diasSemTreino;
    int aderencia = _config!.aderenciaMinima;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('Configurar Alertas'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Dias sem treino: $dias'),
            Slider(
              value: dias.toDouble(),
              min: 1, max: 30, divisions: 29,
              label: '$dias dias',
              onChanged: (v) => set(() => dias = v.toInt()),
            ),
            const SizedBox(height: 8),
            Text('Aderência mínima: $aderencia%'),
            Slider(
              value: aderencia.toDouble(),
              min: 10, max: 100, divisions: 18,
              label: '$aderencia%',
              onChanged: (v) => set(() => aderencia = v.toInt()),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (confirm != true) return;
    try {
      await AlertasRepository(ref.read(apiClientProvider))
          .atualizarConfiguracao(dias, aderencia);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _resolverAlerta(AlertaRisco alerta) async {
    try {
      await AlertasRepository(ref.read(apiClientProvider)).resolver(alerta.alunoId);
      setState(() => _alertas.removeWhere((a) => a.alunoId == alerta.alunoId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerta resolvido!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _enviarMensagemChat(AlertaRisco alerta) async {
    final ctrl = TextEditingController(
        text: 'Olá ${alerta.alunoNome.split(' ').first}! Vi que faz um tempo que não treina. Que tal retomarmos hoje? 💪');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enviar mensagem'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send),
            label: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirm != true || ctrl.text.trim().isEmpty) return;

    try {
      await AlertasRepository(ref.read(apiClientProvider))
          .enviarMensagemChat(alerta.alunoId, ctrl.text.trim());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mensagem enviada!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  List<AlertaRisco> get _filtrados {
    if (_filtroScoreMin == null) return _alertas;
    return _alertas.where((a) => a.score >= _filtroScoreMin!).toList();
  }

  Color _scoreColor(int s, bool isDark) => s >= 2
      ? (isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad)
      : (isDark ? const Color(0xFFE2B46F) : EagleTokens.warn);
      
  Color _scoreBg(int s, bool isDark) => s >= 2
      ? (isDark ? const Color(0x1FFF8B8B) : EagleTokens.badSoft)
      : (isDark ? const Color(0x1FE2B46F) : EagleTokens.warnSoft);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = isDark ? EagleTokens.brandAccent : EagleTokens.brand;

    final altos = _alertas.where((a) => a.score >= 2).length;
    final medios = _alertas.where((a) => a.score == 1).length;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (context.canPop()) ...[
                        InkWell(
                          onTap: () => context.pop(),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(Icons.arrow_back_ios_new, size: 24, color: ink),
                          ),
                        ),
                      ],
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MOTOR ANTI-CHURN', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                          const SizedBox(height: 2),
                          Text('Alertas de Risco', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.5)),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(title: const Text('Todos'), onTap: () { setState(() => _filtroScoreMin = null); Navigator.pop(context); }),
                              ListTile(title: const Text('Score ≥ 2 (alto)'), onTap: () { setState(() => _filtroScoreMin = 2); Navigator.pop(context); }),
                              ListTile(title: const Text('Score = 1 (médio)'), onTap: () { setState(() => _filtroScoreMin = 1); Navigator.pop(context); }),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: isDark ? null : Border.all(color: line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.filter_list, size: 14, color: mute),
                          const SizedBox(width: 6),
                          Text('Filtrar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: mute)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else ...[
              // Config strip
              if (_config != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.04) : EagleTokens.brand.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? line : EagleTokens.brand.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: mute),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(TextSpan(children: [
                            TextSpan(text: 'Dispara se: ', style: TextStyle(fontSize: 12, color: mute)),
                            TextSpan(text: 'sem treino > ${_config!.diasSemTreino} dias ', style: TextStyle(fontSize: 12, color: ink, fontWeight: FontWeight.w600)),
                            TextSpan(text: 'ou ', style: TextStyle(fontSize: 12, color: mute)),
                            TextSpan(text: 'aderência < ${_config!.aderenciaMinima}%', style: TextStyle(fontSize: 12, color: ink, fontWeight: FontWeight.w600)),
                          ])),
                        ),
                        InkWell(
                          onTap: _editarConfiguracao,
                          child: Text('Editar', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: brand)),
                        ),
                      ],
                    ),
                  ),
                ),

              // Summary chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0x1AFF8B8B) : EagleTokens.badSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0x33FF8B8B) : const Color(0x269E2B2B)),
                        ),
                        child: Column(
                          children: [
                            Text('$altos', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad)),
                            Text('Score alto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFFF8B8B) : EagleTokens.bad)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0x1AE2B46F) : EagleTokens.warnSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0x33E2B46F) : const Color(0x268A5A12)),
                        ),
                        child: Column(
                          children: [
                            Text('$medios', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFE2B46F) : EagleTokens.warn)),
                            Text('Score médio', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFE2B46F) : EagleTokens.warn)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0x146FE296) : EagleTokens.goodSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0x266FE296) : const Color(0x262B6A3F)),
                        ),
                        child: Column(
                          children: [
                            Text('+', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF6FE296) : EagleTokens.good)),
                            Text('Saudáveis', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF6FE296) : EagleTokens.good)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Alert List
              Expanded(
                child: _filtrados.isEmpty
                    ? const Center(child: Text('Nenhum alerta encontrado', style: TextStyle(fontSize: 16)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: _filtrados.length,
                        itemBuilder: (_, i) {
                          final a = _filtrados[i];
                          final sColor = _scoreColor(a.score, isDark);
                          final sBg = _scoreBg(a.score, isDark);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: a.score >= 2 ? (isDark ? const Color(0x40FF8B8B) : const Color(0x339E2B2B)) : line),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 44, height: 44,
                                        decoration: BoxDecoration(color: isDark ? EagleTokens.brandDeep : EagleTokens.brand, shape: BoxShape.circle),
                                        alignment: Alignment.center,
                                        child: Text(a.alunoNome.isNotEmpty ? a.alunoNome[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(child: Text(a.alunoNome, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ink), overflow: TextOverflow.ellipsis)),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(color: sBg, borderRadius: BorderRadius.circular(999)),
                                                  child: Text('Score ${a.score}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sColor, fontFamily: 'monospace')),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            ...a.motivos.map((m) => Padding(
                                              padding: const EdgeInsets.only(bottom: 2),
                                              child: Row(
                                                children: [
                                                  Container(width: 4, height: 4, decoration: BoxDecoration(color: sColor, shape: BoxShape.circle)),
                                                  const SizedBox(width: 6),
                                                  Flexible(child: Text(m, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: sColor))),
                                                ],
                                              ),
                                            )),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('${a.diasSemTreino ?? a.dias ?? 0}d', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: sColor)),
                                          Text('${a.aderenciaPercent?.toStringAsFixed(0) ?? a.aderencia ?? 0}% ader.', style: TextStyle(fontSize: 10.5, color: mute)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border(top: BorderSide(color: line)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _enviarMensagemChat(a),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            decoration: BoxDecoration(
                                              border: Border(right: BorderSide(color: line)),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text('💬 Mensagem', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: brand)),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _resolverAlerta(a),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                            alignment: Alignment.center,
                                            child: Text('✓ Resolvido', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF6FE296) : EagleTokens.good)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
