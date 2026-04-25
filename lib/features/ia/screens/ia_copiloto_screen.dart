import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/ia_repository.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final resumoSemanalProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return IaRepository(ref.read(apiClientProvider)).resumoSemanal();
});

final insightsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return IaRepository(ref.read(apiClientProvider)).insights();
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class IaCopilotoScreen extends ConsumerStatefulWidget {
  const IaCopilotoScreen({super.key});
  @override
  ConsumerState<IaCopilotoScreen> createState() => _IaCopilotoScreenState();
}

class _IaCopilotoScreenState extends ConsumerStatefulWidget {
  @override
  ConsumerState<IaCopilotoScreen> createState() => _IaCopilotoScreenState();
}

// ignore dup — real state:
class _State extends ConsumerState<IaCopilotoScreen> with SingleTickerProviderStateMixin {
  int _modeIdx = 0; // 0=Treino 1=Dieta 2=Progressão
  bool _gerando = false;
  bool _gerado = false;
  final _modes = ['Treino', 'Dieta', 'Progressão'];

  final _exercicios = [
    {'grupo': 'Peito', 'nome': 'Supino declinado c/ halteres', 'series': 4, 'reps': '10-12', 'progressao': '+2.5kg/sem'},
    {'grupo': 'Ombro', 'nome': 'Arnold press', 'series': 3, 'reps': '8-10', 'progressao': '+1.25kg/sem'},
    {'grupo': 'Ombro', 'nome': 'Face pull no cabo', 'series': 3, 'reps': '15-20', 'progressao': 'manter RPE 7'},
    {'grupo': 'Tríceps', 'nome': 'Tríceps corda supinado', 'series': 3, 'reps': '12-15', 'progressao': '+2kg/sem'},
  ];

  Future<void> _gerar() async {
    setState(() { _gerando = true; _gerado = false; });
    await Future.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() { _gerando = false; _gerado = true; });
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: dark ? const Color(0x0FFFFFFF) : EagleTokens.card,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: line),
                ),
                child: Row(children: [
                  Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(color: brand, shape: BoxShape.circle),
                    child: Center(child: Text('B', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700))),
                  ),
                  const SizedBox(width: 6),
                  Text('Beatriz', style: TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
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
              }).toList(),
            ),
          ),

          // Context chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              {'label': 'Hipertrofia', 'icon': '💪'},
              {'label': 'Push/Pull/Legs', 'icon': '🔄'},
              {'label': '3x semana', 'icon': '📅'},
              {'label': 'Intermediária', 'icon': '⚡'},
              {'label': '58 treinos', 'icon': '📊'},
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
            )).toList(),
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
                      if (!_gerando) Text('1.2s', style: TextStyle(color: mute, fontSize: 11, fontFamily: 'monospace')),
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
                      Wrap(spacing: 14, children: ['Analisando histórico…', 'Calibrando carga…', 'Gerando treino…'].map((s) =>
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

          // Result card
          if (_gerado) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(22), border: Border.all(color: line)),
                clipBehavior: Clip.antiAlias,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // gradient header
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: dark ? const [Color(0xFF1A2852), Color(0xFF0F1A3C)] : [EagleTokens.brand, EagleTokens.brandDeep],
                      ),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('RESULTADO · ${_modes[_modeIdx].toUpperCase()}', style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      const Text('Superior Push B — Ciclo de Hipertrofia', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.5, height: 1.2)),
                      const SizedBox(height: 12),
                      Row(children: [
                        for (final item in [('Duração', '4 sem.'), ('Freq.', '3x/sem'), ('Exerc.', '4')])
                          ...[
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item.$1, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                              Text(item.$2, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                            ]),
                            if (item.$1 != 'Exerc.') Container(width: 1, height: 36, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 16)),
                          ],
                      ]),
                    ]),
                  ),
                  // exercise list
                  ..._exercicios.asMap().entries.map((e) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: e.key < _exercicios.length - 1 ? BorderSide(color: line, width: 0.5) : BorderSide.none)),
                    child: Row(children: [
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
                        Text(e.value['nome'] as String, style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        RichText(text: TextSpan(style: TextStyle(color: mute, fontSize: 11), children: [
                          TextSpan(text: '${e.value['series']}× · ${e.value['reps']} reps · '),
                          TextSpan(text: e.value['progressao'] as String, style: TextStyle(color: dark ? const Color(0xFF6FE296) : EagleTokens.good, fontWeight: FontWeight.w600)),
                        ])),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0x0FFFFFFF) : EagleTokens.lineSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(e.value['grupo'] as String, style: TextStyle(color: mute, fontSize: 10)),
                      ),
                    ]),
                  )),
                  // obs
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: dark ? const Color(0x148DA4E2) : EagleTokens.brandSofter,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: dark ? const Color(0x263B5FE2) : const Color(0x1F3B5FE2)),
                    ),
                    child: RichText(text: TextSpan(style: TextStyle(color: mute, fontSize: 11.5, height: 1.5), children: [
                      TextSpan(text: 'Nota IA: ', style: TextStyle(color: brand, fontWeight: FontWeight.w700)),
                      const TextSpan(text: 'Baseado em 58 treinos históricos e progressão das últimas 12 semanas. RPE alvo: 7-8.'),
                    ])),
                  ),
                ]),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: brand,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: brand.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.fitness_center, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      const Text('Atribuir à Beatriz', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                )),
                const SizedBox(width: 10),
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: line)),
                  child: Icon(Icons.more_horiz, color: mute),
                ),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
