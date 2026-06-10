import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/router/safe_navigation.dart';
import '../../core/theme/brand_palette.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/tokens_strip.dart';
import '../../core/widgets/fx_empty_state.dart';
import '../../core/widgets/feedback_helper.dart';
import '../../core/widgets/fx_shell_scaffold.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../alunos/utils/satellite_screen_utils.dart';
import 'plano_sucesso_model.dart';
import 'plano_sucesso_provider.dart';

class PlanoSucessoScreen extends StatefulWidget {
  final int alunoId;
  final String? alunoNome;
  const PlanoSucessoScreen({
    super.key,
    required this.alunoId,
    this.alunoNome,
  });

  @override
  State<PlanoSucessoScreen> createState() => _PlanoSucessoScreenState();
}

class _PlanoSucessoScreenState extends State<PlanoSucessoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PlanoSucessoProvider>().fetchPlano(widget.alunoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlanoSucessoProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    if (provider.isLoading) {
      return FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Plano de Sucesso',
          subtitle: 'Marcos e metas do aluno',
          onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
        ),
        body: const SafeArea(child: SkeletonList(count: 5)),
      );
    }

    final plano = provider.plano;
    if (plano == null) {
      return FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Plano de Sucesso',
          subtitle: 'Marcos e metas do aluno',
          onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
        ),
        body: SafeArea(
          child: FxEmptyState(
            icon: 'flag',
            title: 'Nenhum plano ativo',
            subtitle:
                widget.alunoNome != null
                    ? '${satelliteFirstName(widget.alunoNome)} ainda não possui marcos de sucesso definidos.'
                    : 'Este aluno ainda não possui plano de sucesso.',
            action: FxEmptyAction(
              label: 'Voltar ao Aluno 360',
              onTap:
                  () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
            ),
          ),
        ),
      );
    }

    final total = plano.marcos.length;
    final done = plano.marcos.where((m) => m.atingido).length;
    final progresso = total == 0 ? 0.0 : done / total;
    final pendentes = plano.marcos.where((m) => !m.atingido).toList();
    final atual = pendentes.isEmpty ? null : pendentes.first.id;

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Plano de Sucesso',
        subtitle:
            widget.alunoNome?.trim().isNotEmpty == true
                ? widget.alunoNome!.trim()
                : 'Aluno #${widget.alunoId}',
        onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(TokensStrip.s4, TokensStrip.s1, TokensStrip.s4, TokensStrip.s7),
          children: [
            Container(
              padding: const EdgeInsets.all(TokensStrip.s5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TokensStrip.r2xl),
                gradient: LinearGradient(
                  colors:
                      isDark
                          ? [
                            BrandPalette.deep(primary),
                            BrandPalette.deep(primary).withValues(alpha: 0.55),
                          ]
                          : [
                            BrandPalette.softened(primary),
                            BrandPalette.deep(primary),
                          ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: isDark ? 0.30 : 0.22),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                    spreadRadius: -8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  _SuccessRing(fraction: progresso),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PROGRESSO DO ONBOARDING',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$done de $total etapas',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pendentes.isEmpty
                              ? 'Plano completo'
                              : 'Próximo: ${pendentes.first.titulo}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TokensStrip.s4),
            Text(
              'Marcos',
              style: TextStyle(
                color: fxScreenInk(context),
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < plano.marcos.length; i++)
              _MarcoTile(
                index: i + 1,
                marco: plano.marcos[i],
                atual: plano.marcos[i].id == atual,
                onChanged:
                    plano.marcos[i].atingido
                        ? null
                        : () async {
                          try {
                            await provider.atingirMarco(plano.marcos[i].id);
                            if (!context.mounted) return;
                            FeedbackHelper.showSuccess(
                              context,
                              'Marco atingido!',
                            );
                          } catch (_) {
                            if (!context.mounted) return;
                            FeedbackHelper.showError(
                              context,
                              'Erro ao atualizar o marco.',
                            );
                          }
                        },
              ),
          ],
        ),
      ),
    );
  }
}

class _SuccessRing extends StatelessWidget {
  final double fraction;
  const _SuccessRing({required this.fraction});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(80, 80),
            painter: _SuccessRingPainter(fraction: fraction),
          ),
          Text(
            '${(fraction * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessRingPainter extends CustomPainter {
  final double fraction;
  const _SuccessRingPainter({required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final track =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    final active =
        Paint()
          ..color = Colors.white
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, 32, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 32),
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(_SuccessRingPainter oldDelegate) =>
      oldDelegate.fraction != fraction;
}

class _MarcoTile extends StatelessWidget {
  final int index;
  final MarcoSucesso marco;
  final bool atual;
  final VoidCallback? onChanged;

  const _MarcoTile({
    required this.index,
    required this.marco,
    required this.atual,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = Theme.of(context).colorScheme.primary;
    final ink = fxScreenInk(context);
    final mute = fxScreenMute(context);
    final doneBg =
        isDark
            ? EagleTokens.good.withValues(alpha: 0.18)
            : EagleTokens.goodSoft;
    final currentBg = brand.withValues(alpha: isDark ? 0.16 : 0.10);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onChanged,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          child: Ink(
            padding: const EdgeInsets.all(TokensStrip.s3),
            decoration:
                atual
                    ? fxListCardDecoration(
                      context,
                      accent: brand,
                      radius: TokensStrip.rCard,
                      selected: true,
                    )
                    : fxListCardDecoration(
                      context,
                      accent: marco.atingido ? EagleTokens.good : null,
                      radius: TokensStrip.rCard,
                    ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color:
                        marco.atingido
                            ? doneBg
                            : (atual
                                ? currentBg
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : TokensStrip.borderDefault)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child:
                        marco.atingido
                            ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: EagleTokens.good,
                            )
                            : Text(
                              '$index',
                              style: TextStyle(
                                color: atual ? brand : mute,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marco.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              marco.atingido
                                  ? EagleTokens.good
                                  : (atual ? brand : ink),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        marco.atingido
                            ? 'Etapa concluída.'
                            : (atual
                                ? 'Etapa atual do onboarding.'
                                : 'Pendente.'),
                        style: TextStyle(color: mute, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
