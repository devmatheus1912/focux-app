import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/ia_repository.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final resumoSemanalProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return IaRepository(ref.read(apiClientProvider)).resumoSemanal();
});

final insightsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return IaRepository(ref.read(apiClientProvider)).insights();
});

final proximaAcaoProvider = FutureProvider.family<Map<String, dynamic>, int>((ref, alunoId) async {
  return IaRepository(ref.read(apiClientProvider)).proximaAcao(alunoId);
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class IaCopilotoScreen extends ConsumerStatefulWidget {
  const IaCopilotoScreen({super.key});
  @override
  ConsumerState<IaCopilotoScreen> createState() => _IaCopilotoScreenState();
}

class _IaCopilotoScreenState extends ConsumerState<IaCopilotoScreen> with SingleTickerProviderStateMixin {
  int _modeIdx = 0;
  bool _gerando = false;
  bool _gerado = false;
  Object? _erro;
  int? _selectedAlunoId;
  String? _selectedAlunoNome;
  // BUG-21: tempo real de geração
  int _geracaoMs = 0;
  Map<String, dynamic>? _proximaAcao;
  final _modes = ['Treino', 'Dieta', 'Progressão'];

  Future<void> _selecionarAluno() async {
    final alunos = await ref.read(alunosProvider.future);
    if (!mounted) return;
    if (alunos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você ainda não possui alunos cadastrados.')),
      );
      return;
    }
    final escolhido = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: alunos
              .map(
                (a) => ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(a.nome),
                  subtitle: Text(a.objetivo ?? 'Sem objetivo definido'),
                  trailing: _selectedAlunoId == a.id
                      ? const Icon(Icons.check_circle, color: Color(0xFF2BB673))
                      : null,
                  onTap: () => Navigator.of(ctx).pop(a.id),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (escolhido == null) return;
    final aluno = alunos.firstWhere((a) => a.id == escolhido);
    setState(() {
      _selectedAlunoId = aluno.id;
      _selectedAlunoNome = aluno.nome;
      _gerado = false;
      _erro = null;
      _proximaAcao = null;
    });
  }

  Future<void> _gerar() async {
    if (_selectedAlunoId == null) {
      await _selecionarAluno();
      if (_selectedAlunoId == null) return;
    }
    setState(() { _gerando = true; _gerado = false; _erro = null; _geracaoMs = 0; });
    final stopwatch = Stopwatch()..start();
    try {
      ref.invalidate(insightsProvider);
      ref.invalidate(resumoSemanalProvider);
      await ref.read(insightsProvider.future);
      _proximaAcao = await ref.read(proximaAcaoProvider(_selectedAlunoId!).future);
      stopwatch.stop();
      if (mounted) setState(() { _gerando = false; _gerado = true; _geracaoMs = stopwatch.elapsedMilliseconds; });
    } catch (e) {
      stopwatch.stop();
      if (mounted) setState(() { _gerando = false; _erro = e; });
    }
  }

  Future<void> _atribuir() async {
    if (_selectedAlunoId == null) {
      await _selecionarAluno();
      if (_selectedAlunoId == null) return;
    }
    try {
      final repo = IaRepository(ref.read(apiClientProvider));
      final acao = await repo.proximaAcao(_selectedAlunoId!);
      if (!mounted) return;
      setState(() => _proximaAcao = acao);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ação atribuída para ${_selectedAlunoNome ?? "aluno"}: ${(acao['acao'] ?? acao['titulo'] ?? 'Próxima ação').toString()}',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível atribuir agora.')),
      );
    }
  }

  Future<void> _abrirMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_search),
              title: const Text('Trocar aluno'),
              onTap: () => Navigator.of(ctx).pop('trocar'),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Atualizar insights'),
              onTap: () => Navigator.of(ctx).pop('atualizar'),
            ),
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('Limpar resultado'),
              onTap: () => Navigator.of(ctx).pop('limpar'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'trocar':
        await _selecionarAluno();
        break;
      case 'atualizar':
        await _gerar();
        break;
      case 'limpar':
        setState(() {
          _gerado = false;
          _proximaAcao = null;
          _erro = null;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? EagleTokens.darkBg : EagleTokens.paper;
    final cardBg = dark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = dark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = dark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = dark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = dark ? EagleTokens.brandAccent : EagleTokens.brand;

    return Scaffold(
      backgroundColor: bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 54),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: Icon(Icons.arrow_back_ios_new, color: ink, size: 18),
                ),
                const SizedBox(width: 6),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: dark ? const Color(0x268DA4E2) : EagleTokens.brandSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.auto_awesome, color: brand, size: 15),
                  ),
                  const SizedBox(width: 6),
                  Text('IA FOCUX', style: TextStyle(color: brand, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                ]),
                const SizedBox(height: 6),
                Text('Copiloto', style: TextStyle(color: ink, fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -1.2, height: 1)),
                ]),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: dark ? const Color(0x0FFFFFFF) : EagleTokens.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: line),
                ),
                child: Row(children: [
                  Icon(Icons.bolt, color: brand, size: 14),
                  const SizedBox(width: 6),
                  Text('Copiloto', style: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: GestureDetector(
              onTap: _selecionarAluno,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: line),
                ),
                child: Row(
                  children: [
                    Icon(Icons.group_outlined, color: brand, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedAlunoNome == null
                            ? 'Selecionar aluno'
                            : 'Aluno selecionado: $_selectedAlunoNome',
                        style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.keyboard_arrow_down, color: mute),
                  ],
                ),
              ),
            ),
          ),

          // Mode selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: line)),
              child: Row(children: _modes.asMap().entries.map((e) {
                final sel = e.key == _modeIdx;
                return Expanded(child: GestureDetector(
                  onTap: () => setState(() => _modeIdx = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? brand : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(e.value, style: TextStyle(color: sel ? Colors.white : mute, fontSize: 13, fontWeight: FontWeight.w600))),
                  ),
                ));
              }).toList()),
            ),
          ),

          // Context chips (modo selecionado)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              {'label': _modes[_modeIdx], 'icon': '⚡'},
              {'label': 'Análise IA', 'icon': '🤖'},
              {'label': 'Personalizado', 'icon': '🎯'},
            ].map((c) => Container(
              padding: const EdgeInsets.fromLTRB(8, 7, 11, 7),
              decoration: BoxDecoration(
                color: dark ? const Color(0x208DA4E2) : EagleTokens.brandSoft,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: dark ? const Color(0x338DA4E2) : const Color(0x263B5FE2)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(c['icon']!, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 5),
                Text(c['label']!, style: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            )).toList()),
          ),

          // Generate button / progress
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: !_gerado && !_gerando
              ? GestureDetector(
                  onTap: _gerar,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [brand, EagleTokens.brandDeep]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: brand.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text('Gerar ${_modes[_modeIdx]}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF2BB673), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(_gerando ? 'Gerando...' : 'Geração concluída', style: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                      if (!_gerando && _geracaoMs > 0)
                        Text(
                          _geracaoMs >= 1000
                              ? '${(_geracaoMs / 1000).toStringAsFixed(1)}s'
                              : '${_geracaoMs}ms',
                          style: TextStyle(color: mute, fontSize: 11, fontFamily: 'monospace'),
                        ),
                    ]),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: _gerado ? 1.0 : null,
                        minHeight: 5,
                        backgroundColor: dark ? const Color(0x128DA4E2) : EagleTokens.brandSoft,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF2BB673)),
                      ),
                    ),
                    if (_gerado) ...[
                      const SizedBox(height: 12),
                      Wrap(spacing: 14, children: ['Analisando histórico…', 'Calibrando carga…', 'Gerando ${_modes[_modeIdx].toLowerCase()}…'].map((s) =>
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.check, color: Color(0xFF2BB673), size: 12),
                          const SizedBox(width: 4),
                          Text(s, style: const TextStyle(color: Color(0xFF2BB673), fontSize: 10.5, fontWeight: FontWeight.w500)),
                        ]),
                      ).toList()),
                    ],
                  ]),
                ),
          ),

          // Result card — vinculado ao backend (/api/ia/copiloto/insights)
          if (_erro != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: dark ? const Color(0x331F1212) : const Color(0x14E25656),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x33E25656)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Color(0xFFE25656), size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Não foi possível gerar agora. Tente novamente.', style: TextStyle(color: ink, fontSize: 13))),
                  TextButton(onPressed: _gerar, child: const Text('Tentar')),
                ]),
              ),
            ),
          ] else if (_gerado) ...[
            Consumer(builder: (context, ref, _) {
              final insightsAsync = ref.watch(insightsProvider);
              return insightsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0x331F1212) : const Color(0x14E25656),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x33E25656)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Color(0xFFE25656), size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Erro ao carregar insights.', style: TextStyle(color: ink, fontSize: 13))),
                      TextButton(onPressed: () => ref.invalidate(insightsProvider), child: const Text('Recarregar')),
                    ]),
                  ),
                ),
                data: (insights) {
                  if (insights.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(18), border: Border.all(color: line)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Sem insights no momento', style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text('Adicione mais treinos e check-ins para que a IA gere recomendações personalizadas.', style: TextStyle(color: mute, fontSize: 12)),
                        ]),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Container(
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(22), border: Border.all(color: line)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: dark ? const [Color(0xFF1A2852), Color(0xFF0F1A3C)] : [EagleTokens.brand, EagleTokens.brandDeep],
                            ),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('INSIGHTS · ${_modes[_modeIdx].toUpperCase()}', style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                            const SizedBox(height: 6),
                            Text('${insights.length} recomendações geradas', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, height: 1.2)),
                          ]),
                        ),
                        ...insights.asMap().entries.map((e) {
                          final ins = e.value;
                          final titulo = (ins['titulo'] ?? ins['title'] ?? 'Insight ${e.key + 1}').toString();
                          final detalhe = (ins['detalhe'] ?? ins['descricao'] ?? ins['descrição'] ?? ins['mensagem'] ?? '').toString();
                          final tipo = (ins['tipo'] ?? ins['categoria'] ?? '').toString();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(border: Border(bottom: e.key < insights.length - 1 ? BorderSide(color: line, width: 0.5) : BorderSide.none)),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: dark ? const Color(0x208DA4E2) : EagleTokens.brandSoft,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: Center(child: Text('${e.key + 1}', style: TextStyle(color: brand, fontSize: 12, fontWeight: FontWeight.w700))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(titulo, style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),
                                if (detalhe.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(detalhe, style: TextStyle(color: mute, fontSize: 11.5, height: 1.4)),
                                ],
                              ])),
                              if (tipo.isNotEmpty) Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: dark ? const Color(0x0FFFFFFF) : EagleTokens.lineSoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(tipo, style: TextStyle(color: mute, fontSize: 10)),
                              ),
                            ]),
                          );
                        }),
                      ]),
                    ),
                  );
                },
              );
            }),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(children: [
                Expanded(child: GestureDetector(
                  onTap: _atribuir,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: brand,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: brand.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                      Icon(Icons.assignment_turned_in_outlined, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text('Atribuir ação', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                )),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _abrirMenu,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: line),
                    ),
                    child: Icon(Icons.more_vert, color: ink),
                  ),
                ),
              ]),
            ),
            if (_proximaAcao != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: line),
                  ),
                  child: Text(
                    'Próxima ação: ${(_proximaAcao!['acao'] ?? _proximaAcao!['titulo'] ?? _proximaAcao!['mensagem'] ?? 'Sem detalhe').toString()}',
                    style: TextStyle(color: ink, fontSize: 12.5),
                  ),
                ),
              ),
          ],
        ]),
      ),
    );
  }
}
