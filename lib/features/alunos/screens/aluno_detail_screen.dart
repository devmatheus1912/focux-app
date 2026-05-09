import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/aluno_repository.dart';
import '../providers/alunos_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../dashboard/data/command_center_data.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../ia/data/ia_repository.dart';

final alunoCopilotoActionProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, alunoId) async {
      return IaRepository(ref.read(apiClientProvider)).proximaAcao(alunoId);
    });

final alunoScoreSnapshotsProvider = FutureProvider.family<
  List<FocuxScoreSnapshotResumo>,
  int
>((ref, alunoId) async {
  return ref.read(dashboardRepositoryProvider).getFocuxScoreSnapshots(alunoId);
});

final alunoEvolucaoInteligenteProvider =
    FutureProvider.family<EvolucaoInteligente, int>((ref, alunoId) async {
      return AlunoRepository(
        ref.read(apiClientProvider),
      ).buscarEvolucaoInteligente(alunoId);
    });

final alunoTimeline360ApiProvider =
    FutureProvider.family<List<Timeline360Event>, int>((ref, alunoId) async {
      return AlunoRepository(
        ref.read(apiClientProvider),
      ).buscarTimeline360(alunoId);
    });

class AlunoDetailScreen extends ConsumerWidget {
  final int alunoId;
  const AlunoDetailScreen({super.key, required this.alunoId});

  Future<void> _confirmarExclusao(
    BuildContext context,
    WidgetRef ref,
    Aluno aluno,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excluir aluno'),
            content: Text(
              'Tem certeza que deseja excluir ${aluno.nome}? Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: EagleTokens.bad),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await AlunoRepository(ref.read(apiClientProvider)).excluirAluno(aluno.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Aluno excluído.')));
        safePopOrGo(context, '/alunos');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  Future<void> _confirmarGerarSenha(
    BuildContext context,
    WidgetRef ref,
    Aluno aluno,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Gerar nova senha?'),
            content: Text(
              'A senha atual de ${aluno.nome} deixará de funcionar. Gere apenas se o aluno esqueceu a senha ou precisa recuperar acesso.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(Icons.key_rounded, size: 18),
                label: const Text('Gerar senha'),
              ),
            ],
          ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      final senha = await AlunoRepository(
        ref.read(apiClientProvider),
      ).gerarSenhaProvisoria(aluno.id);
      ref.invalidate(alunoProvider(aluno.id));
      if (context.mounted) {
        _showNovaSenhaSheet(context, aluno, senha);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível gerar senha: $e')),
        );
      }
    }
  }

  void _showNovaSenhaSheet(BuildContext context, Aluno aluno, String senha) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final whatsappNumber = (aluno.whatsapp ?? '').replaceAll(RegExp(r'\D'), '');
    final hasWhatsapp = whatsappNumber.isNotEmpty;
    final mensagem = _senhaProvisoriaMessage(aluno, senha);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? EagleTokens.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24 + MediaQuery.of(ctx).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.key_rounded, color: primary, size: 28),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nova senha provisória',
                  style: TextStyle(
                    color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'A senha anterior não funciona mais. ${aluno.nome} deve trocar no primeiro acesso.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                    fontSize: 13.4,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Senha provisória',
                        style: TextStyle(
                          color:
                              isDark
                                  ? EagleTokens.darkInkMute
                                  : EagleTokens.inkMute,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        senha,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white : EagleTokens.ink,
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5.5,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        'Compartilhe apenas com o aluno.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              isDark
                                  ? EagleTokens.darkInkMute
                                  : EagleTokens.inkMute,
                          fontSize: 11.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      if (hasWhatsapp) {
                        final uri = Uri.parse(
                          'https://wa.me/55$whatsappNumber?text=${Uri.encodeComponent(mensagem)}',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          return;
                        }
                      }
                      await Clipboard.setData(ClipboardData(text: mensagem));
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              hasWhatsapp
                                  ? 'Mensagem copiada. Abra o WhatsApp e envie ao aluno.'
                                  : 'Convite copiado.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      hasWhatsapp ? Icons.send_rounded : Icons.copy_rounded,
                      size: 18,
                    ),
                    label: Text(
                      hasWhatsapp ? 'Enviar nova senha' : 'Copiar nova senha',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                if (hasWhatsapp) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: mensagem));
                        HapticFeedback.mediumImpact();
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Convite copiado.')),
                          );
                        }
                      },
                      icon: Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                      ),
                      label: Text(
                        'Copiar nova senha',
                        style: TextStyle(
                          color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color:
                              isDark ? EagleTokens.darkLine : EagleTokens.line,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      'Fechar',
                      style: TextStyle(
                        color:
                            isDark
                                ? EagleTokens.darkInkMute
                                : EagleTokens.inkMute,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  String _senhaProvisoriaMessage(Aluno aluno, String senha) {
    final primeiroNome =
        aluno.nome.trim().isEmpty
            ? 'tudo bem'
            : aluno.nome.trim().split(RegExp(r'\s+')).first;
    return 'Olá $primeiroNome! Sua senha do Focux foi redefinida.\n\n'
        'Acesse com seu e-mail: ${aluno.email}\n'
        'Senha provisória: $senha\n\n'
        'Troque a senha no primeiro acesso.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alunoAsync = ref.watch(alunoProvider(alunoId));
    final autonomiaAsync = ref.watch(alunoAutonomiaEventosProvider(alunoId));
    final autonomiaResumoAsync = ref.watch(
      alunoAutonomiaResumoProvider(alunoId),
    );
    final scoreSnapshotsAsync = ref.watch(alunoScoreSnapshotsProvider(alunoId));
    final evolucaoAsync = ref.watch(alunoEvolucaoInteligenteProvider(alunoId));
    final timeline360ApiAsync = ref.watch(alunoTimeline360ApiProvider(alunoId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;

    return Scaffold(
      backgroundColor: bg,
      body: alunoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (aluno) {
          // Fake mock data for UI parity until we get these from backend
          final aderencia = "85%";
          final streak = "12d";
          final prs = "3";
          final treinos = "45";

          return CustomScrollView(
            slivers: [
              // Hero App Bar that stays when scrolling
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primary, BrandPalette.deep(primary)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 20,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    fxInitials(aluno.nome),
                                    style: TextStyle(
                                      color: primary,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        aluno.nome,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        aluno.objetivo ?? 'Emagrecimento',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.75,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Stats Strip
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _HeroStat(label: 'Aderência', value: aderencia),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                _HeroStat(
                                  label: 'Streak',
                                  value: streak,
                                  icon: Icons.local_fire_department,
                                  iconColor: const Color(0xFFFFD37A),
                                ),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                _HeroStat(label: 'PRs · mês', value: prs),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                _HeroStat(label: 'Treinos', value: treinos),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded),
                    tooltip: 'Ações do aluno',
                    onSelected: (value) async {
                      if (value == 'senha') {
                        await _confirmarGerarSenha(context, ref, aluno);
                        return;
                      }
                      if (value == 'editar') {
                        final updated = await context.push<bool>(
                          '/alunos/$alunoId/editar',
                          extra: aluno,
                        );
                        if (updated == true) {
                          ref.invalidate(alunoProvider(alunoId));
                        }
                        return;
                      }
                      if (value == 'excluir') {
                        await _confirmarExclusao(context, ref, aluno);
                      }
                    },
                    itemBuilder:
                        (ctx) => const [
                          PopupMenuItem(
                            value: 'senha',
                            child: ListTile(
                              leading: Icon(Icons.key_outlined),
                              title: Text('Gerar nova senha'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'editar',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Editar aluno'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'excluir',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                color: EagleTokens.bad,
                              ),
                              title: Text(
                                'Excluir aluno',
                                style: TextStyle(color: EagleTokens.bad),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                  ),
                ],
              ),

              // Body Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 24,
                    left: 16,
                    right: 16,
                    bottom: 80,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StudentQuickActions(
                        aluno: aluno,
                        isDark: isDark,
                        primary: primary,
                        onPassword:
                            () => _confirmarGerarSenha(context, ref, aluno),
                        onEdit: () async {
                          final updated = await context.push<bool>(
                            '/alunos/$alunoId/editar',
                            extra: aluno,
                          );
                          if (updated == true) {
                            ref.invalidate(alunoProvider(alunoId));
                          }
                        },
                        onMessage:
                            () => context.push(
                              '/alunos/${aluno.id}/chat',
                              extra: aluno.nome,
                            ),
                        onEvolve:
                            () => context.push(
                              '/alunos/${aluno.id}/ia/progressao',
                              extra: aluno.nome,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _Aluno360CopilotCard(
                        aluno: aluno,
                        resumoAsync: autonomiaResumoAsync,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _EvolucaoInteligenteCard(
                        evolucaoAsync: evolucaoAsync,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _Aluno360TimelineCard(
                        aluno: aluno,
                        eventosAsync: autonomiaAsync,
                        snapshotsAsync: scoreSnapshotsAsync,
                        timelineApiAsync: timeline360ApiAsync,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // Weight evolution card
                      Container(
                        decoration: BoxDecoration(
                          color:
                              isDark ? EagleTokens.darkCard : EagleTokens.card,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color:
                                isDark
                                    ? EagleTokens.darkLine
                                    : EagleTokens.line,
                          ),
                        ),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PESO · ÚLTIMAS 7 SEMANAS',
                                      style: TextStyle(
                                        color:
                                            isDark
                                                ? EagleTokens.darkInkMute
                                                : EagleTokens.inkMute,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          aluno.peso?.toStringAsFixed(1) ??
                                              '0.0',
                                          style: TextStyle(
                                            color: ink,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'kg',
                                          style: TextStyle(
                                            color:
                                                isDark
                                                    ? EagleTokens.darkInkMute
                                                    : EagleTokens.inkMute,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isDark
                                                    ? const Color(0x1F6FE296)
                                                    : EagleTokens.goodSoft,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.arrow_downward,
                                                size: 10,
                                                color:
                                                    isDark
                                                        ? const Color(
                                                          0xFF6FE296,
                                                        )
                                                        : EagleTokens.good,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                '3.9 kg',
                                                style: TextStyle(
                                                  color:
                                                      isDark
                                                          ? const Color(
                                                            0xFF6FE296,
                                                          )
                                                          : EagleTokens.good,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  'Meta · 62 kg',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? EagleTokens.darkInkMute
                                            : EagleTokens.inkMute,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 72,
                              child: FxSparkline(
                                data: const [
                                  68,
                                  67.5,
                                  66.8,
                                  66.0,
                                  65.2,
                                  64.8,
                                  64.1,
                                ],
                                color: primary,
                                fill: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Measurements Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.1,
                        children: [
                          _MeasurementCard(
                            label: 'Idade',
                            value: (aluno.idade ?? '--').toString(),
                            unit: 'anos',
                            isDark: isDark,
                          ),
                          _MeasurementCard(
                            label: 'Altura',
                            value: aluno.altura?.toStringAsFixed(2) ?? '--',
                            unit: 'm',
                            isDark: isDark,
                          ),
                          _MeasurementCard(
                            label: 'BF',
                            value: '--',
                            unit: '%',
                            isDark: isDark,
                          ),
                          _MeasurementCard(
                            label: 'M. Magra',
                            value: '--',
                            unit: 'kg',
                            isDark: isDark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Módulos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Grid Ferramentas (SaaS Handoff style)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.35,
                        children: [
                          _ModuleTile(
                            icon: Icons.fitness_center,
                            label: 'Treinos',
                            sub: 'Treinos vinculados',
                            isDark: isDark,
                            onTap:
                                () => context.push(
                                  '/alunos/$alunoId/treinos-list',
                                  extra: aluno.nome,
                                ),
                          ),
                          _ModuleTile(
                            icon: Icons.tune_rounded,
                            label: 'Equipamentos',
                            sub:
                                aluno.equipamentosDisponiveis.isEmpty
                                    ? 'Sem restricao'
                                    : '${aluno.equipamentosDisponiveis.length} marcados',
                            isDark: isDark,
                            onTap:
                                () => context.push(
                                  '/alunos/$alunoId/equipamentos',
                                ),
                          ),
                          _ModuleTile(
                            icon: Icons.auto_awesome,
                            label: 'IA · Progressão',
                            sub: 'Sugerir cargas',
                            highlight: true,
                            isDark: isDark,
                            onTap:
                                () => context.push(
                                  '/alunos/$alunoId/ia/progressao',
                                  extra: aluno.nome,
                                ),
                          ),
                          _ModuleTile(
                            icon: Icons.show_chart,
                            label: 'Evolução · Medidas',
                            sub: 'Medidas corporais e PRs',
                            isDark: isDark,
                            onTap:
                                () => context.push(
                                  '/alunos/$alunoId/evolucao',
                                  extra: aluno.nome,
                                ),
                          ),
                          _ModuleTile(
                            icon: Icons.assessment_outlined,
                            label: 'Relatório de Aderência',
                            sub: 'Check-ins, faltas e PDF',
                            isDark: isDark,
                            onTap:
                                () => context.push(
                                  '/alunos/$alunoId/relatorio',
                                  extra: aluno.nome,
                                ),
                          ),
                          _ModuleTile(
                            icon: Icons.flag_outlined,
                            label: 'Plano de Sucesso',
                            sub: 'Onboarding e etapas',
                            isDark: isDark,
                            onTap:
                                () => context.push(
                                  '/alunos/$alunoId/plano-sucesso',
                                  extra: aluno.nome,
                                ),
                          ),
                          _ModuleTile(
                            icon: Icons.people,
                            label: 'Anamnese',
                            sub: 'Completa ✓',
                            isDark: isDark,
                            onTap:
                                () => context.push('/alunos/$alunoId/anamnese'),
                          ),
                          _ModuleTile(
                            icon: Icons.attach_money,
                            label: 'Mensalidades',
                            sub:
                                aluno.statusFinanceiro == 'INADIMPLENTE'
                                    ? 'Em atraso'
                                    : 'Em dia',
                            isDark: isDark,
                            onTap: () => context.push('/financeiro'),
                          ),
                          _ModuleTile(
                            icon: Icons.chat,
                            label: 'Chat',
                            sub: 'Comunicação',
                            isDark: isDark,
                            onTap:
                                () => context.push(
                                  '/alunos/$alunoId/chat',
                                  extra: aluno.nome,
                                ),
                          ),
                          _ModuleTile(
                            icon: Icons.restaurant_menu,
                            label: 'Dieta',
                            sub: 'Plano atual',
                            isDark: isDark,
                            onTap:
                                () =>
                                    context.push('/alunos/$alunoId/alimentar'),
                          ),
                          _ModuleTile(
                            icon: Icons.video_camera_back,
                            label: 'Feedback',
                            sub: 'Análise de vídeo',
                            isDark: isDark,
                            onTap:
                                () => context.push(
                                  '/alunos/$alunoId/feedback-video',
                                  extra: aluno.nome,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StudentQuickActions extends StatelessWidget {
  const _StudentQuickActions({
    required this.aluno,
    required this.isDark,
    required this.primary,
    required this.onMessage,
    required this.onPassword,
    required this.onEdit,
    required this.onEvolve,
  });

  final Aluno aluno;
  final bool isDark;
  final Color primary;
  final VoidCallback onMessage;
  final VoidCallback onPassword;
  final VoidCallback onEdit;
  final VoidCallback onEvolve;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.flash_on_rounded, color: primary, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ações rápidas',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Contato, acesso e evolução de ${aluno.nome.split(' ').first}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mute,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.25,
            children: [
              _QuickActionPill(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Mensagem',
                primary: primary,
                onTap: onMessage,
              ),
              _QuickActionPill(
                icon: Icons.key_outlined,
                label: 'Nova senha',
                primary: primary,
                onTap: onPassword,
              ),
              _QuickActionPill(
                icon: Icons.trending_up_rounded,
                label: 'Evoluir',
                primary: primary,
                onTap: onEvolve,
              ),
              _QuickActionPill(
                icon: Icons.edit_outlined,
                label: 'Editar',
                primary: primary,
                onTap: onEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionPill extends StatelessWidget {
  const _QuickActionPill({
    required this.icon,
    required this.label,
    required this.primary,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: primary),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Aluno360CopilotCard extends ConsumerWidget {
  final Aluno aluno;
  final AsyncValue<AlunoAutonomiaResumo> resumoAsync;
  final bool isDark;

  const _Aluno360CopilotCard({
    required this.aluno,
    required this.resumoAsync,
    required this.isDark,
  });

  int _perfilCompletion(Aluno aluno) {
    final fields = [
      aluno.telefone,
      aluno.whatsapp,
      aluno.objetivo,
      aluno.genero,
      aluno.fotoUrl,
      aluno.dataNascimento,
      aluno.peso,
      aluno.altura,
    ];
    final filled =
        fields.where((value) {
          if (value == null) return false;
          if (value is String) return value.trim().isNotEmpty;
          return true;
        }).length;
    return ((filled / fields.length) * 100).round().clamp(0, 100);
  }

  List<_Aluno360Signal> _signals(
    BuildContext context,
    Aluno aluno,
    AlunoAutonomiaResumo? resumo,
  ) {
    final profile = _perfilCompletion(aluno);
    final financeiroOk = aluno.statusFinanceiro != 'INADIMPLENTE';
    final hasAutonomyFriction =
        resumo != null && resumo.cliques > resumo.concluidos;
    final hasEquipment = aluno.equipamentosDisponiveis.isNotEmpty;
    return [
      _Aluno360Signal(
        label: 'Perfil',
        value: '$profile%',
        detail:
            profile >= 80
                ? 'dados bons para prescrição'
                : 'faltam dados que melhoram decisão',
        color:
            profile >= 80
                ? EagleTokens.good
                : Theme.of(context).colorScheme.primary,
      ),
      _Aluno360Signal(
        label: 'Financeiro',
        value: financeiroOk ? 'OK' : 'Atenção',
        detail: financeiroOk ? 'sem bloqueio operacional' : 'pendência ativa',
        color: financeiroOk ? EagleTokens.good : EagleTokens.bad,
      ),
      _Aluno360Signal(
        label: 'Autonomia',
        value:
            resumo == null
                ? '--'
                : '${(resumo.concluidos / (resumo.cliques == 0 ? 1 : resumo.cliques) * 100).clamp(0, 100).round()}%',
        detail:
            hasAutonomyFriction
                ? 'clicou e ainda não fechou'
                : 'sem gargalo aberto forte',
        color:
            hasAutonomyFriction
                ? EagleTokens.warn
                : Theme.of(context).colorScheme.primary,
      ),
      _Aluno360Signal(
        label: 'Contexto',
        value: hasEquipment ? 'Rico' : 'Base',
        detail:
            hasEquipment
                ? '${aluno.equipamentosDisponiveis.length} equipamentos'
                : 'equipamentos não definidos',
        color: Theme.of(context).colorScheme.primary,
      ),
    ];
  }

  String _fallbackAction(Aluno aluno, AlunoAutonomiaResumo? resumo) {
    if (aluno.statusFinanceiro == 'INADIMPLENTE') {
      return 'Regularizar financeiro antes que isso vire atrito de acesso.';
    }
    if (_perfilCompletion(aluno) < 80) {
      return 'Completar perfil do aluno e remover lacunas de prescrição.';
    }
    if (resumo != null && resumo.cliques > resumo.concluidos) {
      return 'Resolver o gargalo de autonomia: ${resumo.gargaloTitulo ?? "tarefa aberta"}.';
    }
    return 'Revisar treino e propor a próxima evolução de ${aluno.objetivo ?? "objetivo"}.';
  }

  Future<void> _atribuir(
    BuildContext context,
    WidgetRef ref,
    String acao,
  ) async {
    try {
      await IaRepository(ref.read(apiClientProvider)).salvarAcaoCopiloto(
        alunoId: aluno.id,
        acao: acao,
        motivo:
            'Aluno 360: ação prescrita a partir de perfil, autonomia e risco.',
      );
      ref.invalidate(commandCenterProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ação enviada para ${aluno.nome}.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível atribuir: $e')),
        );
      }
    }
  }

  Future<void> _copiarMensagem(BuildContext context, String acao) async {
    final mensagem = _mensagemPronta(aluno, acao);
    await Clipboard.setData(ClipboardData(text: mensagem));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mensagem pronta copiada para ${aluno.nome}.'),
          action: SnackBarAction(
            label: 'Abrir chat',
            onPressed:
                () =>
                    context.push('/alunos/${aluno.id}/chat', extra: aluno.nome),
          ),
        ),
      );
    }
  }

  String _mensagemPronta(Aluno aluno, String acao) {
    final primeiroNome =
        aluno.nome.trim().isEmpty
            ? 'tudo bem'
            : aluno.nome.trim().split(' ').first;
    final objetivo =
        aluno.objetivo == null || aluno.objetivo!.trim().isEmpty
            ? 'seu objetivo'
            : aluno.objetivo!.trim();
    return 'Oi, $primeiroNome! Passei pelo seu acompanhamento agora e o próximo passo para $objetivo é: $acao Me responde aqui com um ok quando fizer, combinado?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final actionAsync = ref.watch(alunoCopilotoActionProvider(aluno.id));
    final resumo = resumoAsync.valueOrNull;
    final signals = _signals(context, aluno, resumo);
    final fallback = _fallbackAction(aluno, resumo);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: primary.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: isDark),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.hub_outlined, color: primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próxima melhor ação',
                      style: TextStyle(
                        color: ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Decisão sugerida com perfil, autonomia e financeiro.',
                      style: TextStyle(
                        color: mute,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed:
                    () => ref.invalidate(alunoCopilotoActionProvider(aluno.id)),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                tooltip: 'Atualizar Copiloto',
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.85,
            children:
                signals
                    .map((signal) => _Aluno360SignalTile(signal: signal))
                    .toList(),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : BrandPalette.softer(primary),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: line),
            ),
            child: actionAsync.when(
              loading:
                  () => const SizedBox(
                    height: 52,
                    child: Center(child: LinearProgressIndicator(minHeight: 2)),
                  ),
              error:
                  (_, __) => _CopilotPrescription(
                    title: 'Prescrição local',
                    action: fallback,
                    reason:
                        'IA indisponível agora; usando sinais do Aluno 360.',
                    color: primary,
                  ),
              data:
                  (action) => _CopilotPrescription(
                    title:
                        (action['titulo'] ??
                                action['tipo'] ??
                                'Próxima melhor ação')
                            .toString(),
                    action:
                        (action['acao'] ??
                                action['mensagem'] ??
                                action['descricao'] ??
                                fallback)
                            .toString(),
                    reason:
                        (action['motivo'] ?? 'Baseado nos sinais atuais.')
                            .toString(),
                    color: primary,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          actionAsync.maybeWhen(
            data:
                (action) => _Aluno360ActionRow(
                  aluno: aluno,
                  primary: primary,
                  acao:
                      (action['acao'] ??
                              action['mensagem'] ??
                              action['descricao'] ??
                              fallback)
                          .toString(),
                  onAssign: (acao) => _atribuir(context, ref, acao),
                  onCopyMessage: (acao) => _copiarMensagem(context, acao),
                ),
            orElse:
                () => _Aluno360ActionRow(
                  aluno: aluno,
                  primary: primary,
                  acao: fallback,
                  onAssign: (acao) => _atribuir(context, ref, acao),
                  onCopyMessage: (acao) => _copiarMensagem(context, acao),
                ),
          ),
        ],
      ),
    );
  }
}

class _EvolucaoInteligenteCard extends StatelessWidget {
  final AsyncValue<EvolucaoInteligente> evolucaoAsync;
  final bool isDark;

  const _EvolucaoInteligenteCard({
    required this.evolucaoAsync,
    required this.isDark,
  });

  static String _sinalLabel(String s) {
    switch (s) {
      case 'SUBINDO':
        return 'Em alta';
      case 'ESTÁVEL':
        return 'Estável';
      case 'PLATÔ':
        return 'Platô';
      case 'QUEDA':
        return 'Atenção';
      case 'SEM_DADOS':
      default:
        return 'Sem dados';
    }
  }

  static Color _sinalColor(String s) {
    switch (s) {
      case 'SUBINDO':
        return EagleTokens.good;
      case 'QUEDA':
        return EagleTokens.bad;
      case 'PLATÔ':
        return EagleTokens.warn;
      default:
        return EagleTokens.inkMute;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
      ),
      child: evolucaoAsync.when(
        loading: () => const LinearProgressIndicator(minHeight: 2),
        error:
            (e, _) => Text(
              'Evolução inteligente indisponível: $e',
              style: TextStyle(color: mute, fontSize: 12.5),
            ),
        data: (ev) {
          final sigColor = _sinalColor(ev.sinal);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: BrandPalette.soft(primary, dark: isDark),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.show_chart_rounded,
                      color: primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evolução inteligente',
                          style: TextStyle(
                            color: ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Sinais a partir de check-ins concluídos e volume.',
                          style: TextStyle(color: mute, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  _MiniAutonomyChip(
                    label: _sinalLabel(ev.sinal),
                    color: sigColor,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                ev.resumo,
                style: TextStyle(color: ink, fontSize: 13.2, height: 1.35),
              ),
              if (ev.sinal != 'SEM_DADOS') ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniAutonomyChip(
                      label:
                          'Vol. semanal ${ev.volumeSemanal.toStringAsFixed(0)}',
                      color: primary,
                    ),
                    _MiniAutonomyChip(
                      label:
                          'Vol. mensal ${ev.volumeMensal.toStringAsFixed(0)}',
                      color: primary,
                    ),
                    if (ev.tendenciaVolumePct != null)
                      _MiniAutonomyChip(
                        label:
                            'Tendência volume ${ev.tendenciaVolumePct! > 0 ? '+' : ''}${ev.tendenciaVolumePct}%',
                        color:
                            ev.tendenciaVolumePct! >= 0
                                ? EagleTokens.good
                                : EagleTokens.bad,
                      ),
                    if (ev.ultimoPrExercicio != null &&
                        ev.ultimoPrExercicio!.isNotEmpty)
                      _MiniAutonomyChip(
                        label:
                            ev.ultimoPrLabel != null &&
                                    ev.ultimoPrLabel!.isNotEmpty
                                ? '${ev.ultimoPrLabel} · ${ev.ultimoPrExercicio}'
                                : 'PR · ${ev.ultimoPrExercicio}',
                        color: EagleTokens.good,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Próxima ação',
                style: TextStyle(
                  color: mute,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ev.proximaAcao,
                style: TextStyle(color: ink, fontSize: 13, height: 1.3),
              ),
              if (ev.sugerirCopiloto) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Copiloto pode ajudar a transformar isso em mensagem ou tarefa.',
                        style: TextStyle(color: mute, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Aluno360TimelineCard extends StatelessWidget {
  final Aluno aluno;
  final AsyncValue<List<AlunoAutonomiaEvento>> eventosAsync;
  final AsyncValue<List<FocuxScoreSnapshotResumo>> snapshotsAsync;
  final AsyncValue<List<Timeline360Event>> timelineApiAsync;
  final bool isDark;

  const _Aluno360TimelineCard({
    required this.aluno,
    required this.eventosAsync,
    required this.snapshotsAsync,
    required this.timelineApiAsync,
    required this.isDark,
  });

  static _Timeline360Item _itemFromApi(Timeline360Event e) {
    final at = DateTime.tryParse(e.ocorridoEm);
    final tipo = e.tipo;
    IconData icon;
    Color color;
    String kind;
    switch (tipo) {
      case 'RADAR':
        icon = Icons.radar_outlined;
        color = EagleTokens.warn;
        kind = 'Radar';
        break;
      case 'CHECKIN':
        icon = Icons.fitness_center_outlined;
        color = EagleTokens.good;
        kind = 'Check-in';
        break;
      case 'MEDIDA':
        icon = Icons.straighten_outlined;
        color = EagleTokens.purple;
        kind = 'Medida';
        break;
      case 'AUTONOMIA':
        icon = Icons.touch_app_outlined;
        color = EagleTokens.warn;
        kind = 'Autonomia';
        break;
      case 'FINANCEIRO':
        icon = Icons.payments_outlined;
        color = EagleTokens.bad;
        kind = 'Financeiro';
        break;
      default:
        if (tipo.startsWith('CHAT_')) {
          icon = Icons.chat_bubble_outline;
          color = EagleTokens.brand;
          kind = 'Chat';
        } else {
          icon = Icons.bolt_outlined;
          color = EagleTokens.inkMute;
          kind = tipo;
        }
    }
    final deep = e.deepLink.trim().isEmpty ? null : e.deepLink.trim();
    return _Timeline360Item(
      at: at,
      kind: kind,
      title: e.titulo,
      body: e.corpo.isEmpty ? e.meta : e.corpo,
      meta: e.meta,
      priority: e.prioridade,
      icon: icon,
      color: color,
      deepLink: deep,
    );
  }

  List<_Timeline360Item> _items() {
    final api = timelineApiAsync.valueOrNull;
    if (api != null && api.isNotEmpty) {
      return api.take(7).map(_itemFromApi).toList();
    }
    final items = <_Timeline360Item>[];
    for (final snapshot in snapshotsAsync.valueOrNull ?? const []) {
      final date = DateTime.tryParse(snapshot.dataReferencia);
      items.add(
        _Timeline360Item(
          at: date,
          kind: 'Radar',
          title: '${snapshot.score} pts · ${snapshot.ritmo}',
          body: snapshot.narrativa,
          meta: snapshot.proximaAcao,
          priority: snapshot.prioridade,
          icon: Icons.radar_outlined,
          color: snapshot.score >= 80 ? EagleTokens.good : EagleTokens.warn,
        ),
      );
    }
    for (final evento in eventosAsync.valueOrNull ?? const []) {
      items.add(
        _Timeline360Item(
          at: evento.criadoEm,
          kind: 'Autonomia',
          title: evento.taskTitle,
          body: _autonomyBody(evento),
          meta: evento.priority ?? 'Sinal do aluno',
          priority: evento.action,
          icon: _autonomyIcon(evento.action),
          color: _autonomyColor(evento.action),
        ),
      );
    }
    items.sort((a, b) {
      final left = a.at ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.at ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    return items.take(7).toList();
  }

  static String _autonomyBody(AlunoAutonomiaEvento evento) {
    final action = switch (evento.action.toUpperCase()) {
      'VIEWED' => 'O aluno viu esta tarefa.',
      'CLICKED' => 'O aluno tentou avançar e clicou nesta tarefa.',
      'COMPLETED' => 'O aluno concluiu esta etapa.',
      _ => 'Sinal registrado no percurso do aluno.',
    };
    if (evento.profileCompletion != null) {
      return '$action Perfil em ${evento.profileCompletion}%.';
    }
    return action;
  }

  static IconData _autonomyIcon(String action) {
    return switch (action.toUpperCase()) {
      'VIEWED' => Icons.visibility_outlined,
      'CLICKED' => Icons.touch_app_outlined,
      'COMPLETED' => Icons.check_circle_outline,
      _ => Icons.bolt_outlined,
    };
  }

  static Color _autonomyColor(String action) {
    return switch (action.toUpperCase()) {
      'CLICKED' => EagleTokens.warn,
      'COMPLETED' => EagleTokens.good,
      _ => EagleTokens.inkMute,
    };
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final loading =
        eventosAsync.isLoading ||
        snapshotsAsync.isLoading ||
        timelineApiAsync.isLoading;
    final items = _items();
    final visibleItems = items.take(3).toList();
    final hasMore = items.length > visibleItems.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: isDark),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.timeline_rounded, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Linha do tempo 360',
                      style: TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Últimos sinais consolidados do aluno.',
                      style: TextStyle(color: mute, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (loading) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(minHeight: 2),
          ] else if (items.isEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '${aluno.nome} ainda não tem sinais suficientes para formar uma linha do tempo.',
              style: TextStyle(color: mute, fontSize: 12.5, height: 1.35),
            ),
          ] else ...[
            const SizedBox(height: 14),
            for (final item in visibleItems) ...[
              _Timeline360Tile(item: item, isDark: isDark),
              if (item != visibleItems.last) Divider(height: 18, color: line),
            ],
            if (hasMore) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showFullTimeline(context, items),
                  child: Text('Ver histórico completo · ${items.length}'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showFullTimeline(BuildContext context, List<_Timeline360Item> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? EagleTokens.darkCard : EagleTokens.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.78,
            minChildSize: 0.45,
            maxChildSize: 0.92,
            builder:
                (context, controller) => ListView.separated(
                  controller: controller,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    18,
                    16,
                    24 + MediaQuery.of(ctx).padding.bottom,
                  ),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, index) {
                    if (index == 0) return const SizedBox(height: 12);
                    return Divider(
                      height: 18,
                      color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                    );
                  },
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Text(
                        'Histórico 360',
                        style: TextStyle(
                          color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    }
                    return _Timeline360Tile(
                      item: items[index - 1],
                      isDark: isDark,
                    );
                  },
                ),
          ),
    );
  }
}

class _Timeline360Item {
  final DateTime? at;
  final String kind;
  final String title;
  final String body;
  final String meta;
  final String priority;
  final IconData icon;
  final Color color;
  final String? deepLink;

  const _Timeline360Item({
    required this.at,
    required this.kind,
    required this.title,
    required this.body,
    required this.meta,
    required this.priority,
    required this.icon,
    required this.color,
    this.deepLink,
  });
}

class _Timeline360Tile extends StatelessWidget {
  final _Timeline360Item item;
  final bool isDark;

  const _Timeline360Tile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final link = item.deepLink;
    final child = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: isDark ? 0.16 : 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(item.icon, color: item.color, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    item.kind,
                    style: TextStyle(
                      color: item.color,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _timelineDate(item.at),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mute,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: mute, fontSize: 12.2, height: 1.25),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _MiniAutonomyChip(label: item.priority, color: item.color),
                  _MiniAutonomyChip(label: item.meta, color: mute),
                ],
              ),
            ],
          ),
        ),
      ],
    );
    if (link != null && link.isNotEmpty) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(link),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: child,
        ),
      );
    }
    return child;
  }
}

String _timelineDate(DateTime? value) {
  if (value == null) return 'sem data';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month às $hour:$minute';
}

class _Aluno360Signal {
  final String label;
  final String value;
  final String detail;
  final Color color;

  const _Aluno360Signal({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });
}

class _Aluno360SignalTile extends StatelessWidget {
  final _Aluno360Signal signal;

  const _Aluno360SignalTile({required this.signal});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: signal.color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 32,
            decoration: BoxDecoration(
              color: signal.color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  signal.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mute,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        signal.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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

class _CopilotPrescription extends StatelessWidget {
  final String title;
  final String action;
  final String reason;
  final Color color;

  const _CopilotPrescription({
    required this.title,
    required this.action,
    required this.reason,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, color: color, size: 17),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          action,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.28,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          reason,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: mute, fontSize: 12, height: 1.25),
        ),
      ],
    );
  }
}

class _Aluno360ActionRow extends StatelessWidget {
  final Aluno aluno;
  final Color primary;
  final String acao;
  final Future<void> Function(String acao) onAssign;
  final Future<void> Function(String acao) onCopyMessage;

  const _Aluno360ActionRow({
    required this.aluno,
    required this.primary,
    required this.acao,
    required this.onAssign,
    required this.onCopyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton.icon(
            onPressed: () => onAssign(acao),
            icon: const Icon(Icons.task_alt_rounded, size: 17),
            label: const Text('Resolver agora'),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _ActionMiniChip(
                icon: Icons.content_copy_rounded,
                label: 'Copiar',
                onTap: () => onCopyMessage(acao),
              ),
              _ActionMiniChip(
                icon: Icons.chat_bubble_outline,
                label: 'Mensagem',
                onTap:
                    () => context.push(
                      '/alunos/${aluno.id}/chat',
                      extra: aluno.nome,
                    ),
              ),
              _ActionMiniChip(
                icon: Icons.trending_up_rounded,
                label: 'Evoluir',
                onTap:
                    () => context.push(
                      '/alunos/${aluno.id}/ia/progressao',
                      extra: aluno.nome,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionMiniChip extends StatelessWidget {
  const _ActionMiniChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        onPressed: onTap,
        avatar: Icon(icon, size: 15, color: primary),
        label: Text(label),
        labelStyle: TextStyle(color: primary, fontWeight: FontWeight.w800),
        side: BorderSide(color: primary.withValues(alpha: 0.22)),
        backgroundColor: primary.withValues(alpha: 0.06),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ignore: unused_element
class _AutonomiaMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _AutonomiaMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg =
        isDark
            ? Colors.white.withValues(alpha: 0.04)
            : color.withValues(alpha: 0.08);
    final border =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : color.withValues(alpha: 0.14);
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mute,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _AutonomiaBottleneck extends StatelessWidget {
  final AlunoAutonomiaResumo resumo;
  final bool isDark;
  final String actionLabel;
  final String dateLabel;

  const _AutonomiaBottleneck({
    required this.resumo,
    required this.isDark,
    required this.actionLabel,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final bg =
        isDark
            ? Colors.white.withValues(alpha: 0.04)
            : BrandPalette.softer(primary);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flag_outlined, color: primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gargalo principal',
                  style: TextStyle(
                    color: mute,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  resumo.gargaloTitulo ?? 'Tarefa do aluno',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _bottleneckHint(resumo.gargaloTaskId),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mute,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _MiniAutonomyChip(label: actionLabel, color: primary),
                    if (resumo.gargaloPrioridade?.isNotEmpty == true)
                      _MiniAutonomyChip(
                        label: resumo.gargaloPrioridade!,
                        color: mute,
                      ),
                    _MiniAutonomyChip(label: dateLabel, color: mute),
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

String _bottleneckHint(String? taskId) {
  return switch (taskId) {
    'perfil-base' || 'foto-dados' =>
      'Bom ponto para pedir foto, contato ou dados corporais que estao faltando.',
    'medida-recente' =>
      'Vale pedir uma medida recente para manter comparativos confiaveis.',
    'treino-semana' =>
      'Verifique se existe treino ativo ou se o aluno precisa de ajuste.',
    'chat-contexto' =>
      'Abra conversa com uma pergunta simples para reduzir dependencia.',
    'agenda-semana' => 'Confirme agenda e proximos compromissos com o aluno.',
    'financeiro' =>
      'Resolva pendencia financeira antes que vire bloqueio de acesso.',
    _ => 'Abra a ficha e remova a barreira principal desse aluno.',
  };
}

// ignore: unused_element
class _AutonomiaEventoTile extends StatelessWidget {
  final AlunoAutonomiaEvento evento;
  final bool isDark;
  final String actionLabel;
  final Color actionColor;
  final String dateLabel;

  const _AutonomiaEventoTile({
    required this.evento,
    required this.isDark,
    required this.actionLabel,
    required this.actionColor,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 9),
          decoration: BoxDecoration(color: actionColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                evento.taskTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _MiniAutonomyChip(label: actionLabel, color: actionColor),
                  if (evento.priority?.isNotEmpty == true)
                    _MiniAutonomyChip(label: evento.priority!, color: mute),
                  if (evento.profileCompletion != null)
                    _MiniAutonomyChip(
                      label: 'Perfil ${evento.profileCompletion}%',
                      color: mute,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(dateLabel, style: TextStyle(color: mute, fontSize: 11.5)),
      ],
    );
  }
}

class _MiniAutonomyChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniAutonomyChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  const _HeroStat({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool isDark;

  const _MeasurementCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: mute,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: ink,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: TextStyle(
                  color: mute,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final bool isDark;
  final bool highlight;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.isDark,
    this.highlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    final bg =
        highlight
            ? (isDark ? EagleTokens.darkCardHi : BrandPalette.soft(primary))
            : cardBg;
    final border = Border.all(
      color: highlight ? primary.withValues(alpha: 0.2) : line,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: border,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: highlight ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 17, color: primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: highlight ? primary : ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: highlight ? BrandPalette.deep(primary) : mute,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
