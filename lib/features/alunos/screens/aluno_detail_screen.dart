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
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/feedback_helper.dart';

final alunoCopilotoActionProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, alunoId) async {
      return IaRepository(ref.read(apiClientProvider)).proximaAcao(alunoId);
    });

final alunoOpenIaActionsProvider =
    FutureProvider.family<List<FilaAcaoResumo>, int>((ref, alunoId) async {
      return ref
          .read(dashboardRepositoryProvider)
          .getIaCommandActions(status: 'ABERTO', alunoId: alunoId);
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

int _perfilCompletion(Aluno aluno) {
  final fields = [
    aluno.nome,
    aluno.email,
    aluno.telefone,
    aluno.whatsapp,
    aluno.objetivo,
    aluno.genero,
    aluno.tipoConsultoria,
  ];
  final filled =
      fields.where((value) {
        if (value == null) return false;
        return value.trim().isNotEmpty;
      }).length;
  return ((filled / fields.length) * 100).round().clamp(0, 100);
}

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
        FeedbackHelper.showSuccess(context, 'Aluno excluído.');
        safePopOrGo(context, '/alunos');
      }
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showSuccess(context, 'Erro: $e');
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
        loading: () => const FxLoading(),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (aluno) {
          final perfil = '${_perfilCompletion(aluno)}%';
          final financeiro =
              aluno.statusFinanceiro == 'INADIMPLENTE' ? 'Ação' : 'OK';
          final medida =
              aluno.peso == null
                  ? 'Falta'
                  : '${aluno.peso!.toStringAsFixed(1)} kg';
          final contexto =
              aluno.equipamentosDisponiveis.isEmpty
                  ? 'Base'
                  : '${aluno.equipamentosDisponiveis.length} eq.';

          return CustomScrollView(
            slivers: [
              // Hero App Bar that stays when scrolling
              SliverAppBar(
                expandedHeight: 180,
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
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
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
                                      fontSize: 22,
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
                                          fontSize: 22,
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
                            const SizedBox(height: 11),
                            // Stats Strip
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _HeroStat(label: 'Perfil', value: perfil),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                _HeroStat(
                                  label: 'Financeiro',
                                  value: financeiro,
                                ),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                _HeroStat(label: 'Medida', value: medida),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                _HeroStat(label: 'Contexto', value: contexto),
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
                    tooltip: 'Mais opções',
                    onSelected: (value) async {
                      if (value == 'excluir') {
                        await _confirmarExclusao(context, ref, aluno);
                      }
                    },
                    itemBuilder:
                        (ctx) => const [
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
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: 118,
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
                        alunoId: alunoId,
                        alunoNome: aluno.nome,
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
                                              '--',
                                          style: TextStyle(
                                            color: ink,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        if (aluno.peso != null) ...[
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
                                              borderRadius:
                                                  BorderRadius.circular(999),
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
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  aluno.peso == null
                                      ? 'Sem medida'
                                      : 'Meta · 62 kg',
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
                              child:
                                  aluno.peso == null
                                      ? InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap:
                                            () => context.push(
                                              '/alunos/$alunoId/evolucao',
                                              extra: aluno.nome,
                                            ),
                                        child: _EmptyMiniState(
                                          icon: Icons.monitor_weight_outlined,
                                          text: 'Registrar primeira medida',
                                          isDark: isDark,
                                        ),
                                      )
                                      : FxSparkline(
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
                      const SizedBox(height: 20),

                      Text(
                        'Módulos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Grid Ferramentas (SaaS Handoff style)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.55,
                        children: [
                          _ModuleTile(
                            icon: Icons.fitness_center,
                            label: 'Treinos',
                            sub: 'Sem dados recentes',
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
                            label: 'IA Progresso',
                            sub: 'Sugerir carga',
                            badge: 'IA',
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
                            label: 'Medidas',
                            sub: 'Sem medida',
                            badge: 'Pendente',
                            isDark: isDark,
                            onTap:
                                () => context.push(
                                  '/alunos/$alunoId/evolucao',
                                  extra: aluno.nome,
                                ),
                          ),
                          _ModuleTile(
                            icon: Icons.assessment_outlined,
                            label: 'Aderência',
                            sub: 'Sem dados',
                            isDark: isDark,
                            onTap:
                                () => context.push(
                                  '/alunos/$alunoId/relatorio',
                                  extra: aluno.nome,
                                ),
                          ),
                          _ModuleTile(
                            icon: Icons.flag_outlined,
                            label: 'Sucesso',
                            sub: 'Acompanhar',
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
                            badge:
                                aluno.statusFinanceiro == 'INADIMPLENTE'
                                    ? 'Ação'
                                    : null,
                            isDark: isDark,
                            onTap: () => context.push('/financeiro'),
                          ),
                          _ModuleTile(
                            icon: Icons.chat,
                            label: 'Chat',
                            sub: 'Última ação',
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
          Row(
            children: [
              Expanded(
                child: _QuickActionPill(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  primary: primary,
                  onTap: onMessage,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _QuickActionPill(
                  icon: Icons.key_outlined,
                  label: 'Senha',
                  primary: primary,
                  onTap: onPassword,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _QuickActionPill(
                  icon: Icons.trending_up_rounded,
                  label: 'Evoluir',
                  primary: primary,
                  onTap: onEvolve,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _QuickActionPill(
                  icon: Icons.edit_outlined,
                  label: 'Editar',
                  primary: primary,
                  onTap: onEdit,
                ),
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
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: primary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primary,
                  fontSize: 10.5,
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

  List<_ProfileGap> _profileGaps(Aluno aluno) {
    return [
      if ((aluno.telefone ?? '').trim().isEmpty &&
          (aluno.whatsapp ?? '').trim().isEmpty)
        const _ProfileGap(
          icon: Icons.call_outlined,
          title: 'Contato',
          detail: 'Telefone ou WhatsApp para acionar o aluno.',
          route: 'edit',
        ),
      if ((aluno.objetivo ?? '').trim().isEmpty)
        const _ProfileGap(
          icon: Icons.flag_outlined,
          title: 'Objetivo',
          detail: 'Define foco da prescrição e do Copiloto.',
          route: 'edit',
        ),
      if ((aluno.genero ?? '').trim().isEmpty ||
          (aluno.tipoConsultoria ?? '').trim().isEmpty)
        const _ProfileGap(
          icon: Icons.badge_outlined,
          title: 'Perfil do aluno',
          detail: 'Gênero e consultoria usados no atendimento.',
          route: 'edit',
        ),
    ];
  }

  Future<void> _openProfileGap(
    BuildContext context,
    Aluno aluno,
    _ProfileGap gap,
  ) async {
    if (gap.route == 'measures') {
      await context.push('/alunos/${aluno.id}/evolucao', extra: aluno.nome);
      return;
    }
    if (gap.route == 'equipment') {
      await context.push('/alunos/${aluno.id}/equipamentos');
      return;
    }
    await context.push('/alunos/${aluno.id}/editar', extra: aluno);
  }

  Future<void> _completeProfile(BuildContext context, Aluno aluno) async {
    final gaps = _profileGaps(aluno);
    if (gaps.length == 1) {
      await _openProfileGap(context, aluno, gaps.first);
      return;
    }
    await _showProfileGapSheet(context, aluno, gaps);
  }

  Future<void> _showProfileGapSheet(
    BuildContext context,
    Aluno aluno,
    List<_ProfileGap> gaps,
  ) async {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    Future<void> go(_ProfileGap gap, BuildContext sheetContext) async {
      Navigator.of(sheetContext).pop();
      await _openProfileGap(context, aluno, gap);
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: bg,
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                20 + MediaQuery.of(sheetContext).padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.fact_check_outlined,
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
                              'Completar perfil',
                              style: TextStyle(
                                color: ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              gaps.isEmpty
                                  ? 'Perfil pronto para decisões da IA.'
                                  : '${gaps.length} lacuna(s) afetam a prescrição.',
                              style: TextStyle(color: mute, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (gaps.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: EagleTokens.good.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: EagleTokens.good.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Text('Nada pendente no perfil agora.'),
                    )
                  else
                    ...gaps.map(
                      (gap) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => go(gap, sheetContext),
                          child: Container(
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: line),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: BrandPalette.soft(
                                      primary,
                                      dark: isDark,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    gap.icon,
                                    color: primary,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        gap.title,
                                        style: TextStyle(
                                          color: ink,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        gap.detail,
                                        style: TextStyle(
                                          color: mute,
                                          fontSize: 12,
                                          height: 1.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded, color: mute),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (gaps.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Para ajustes gerais, use Editar nas ações rápidas.',
                        style: TextStyle(color: mute, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  void _prepararMensagem(BuildContext context, String acao) {
    final message = _mensagemPronta(aluno, acao);
    final primary = Theme.of(context).colorScheme.primary;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Mensagem sugerida',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BrandPalette.softer(primary),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(message, style: const TextStyle(height: 1.35)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: message));
                            Navigator.pop(sheetContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mensagem copiada.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copiar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            context.push(
                              '/alunos/${aluno.id}/chat',
                              extra: {'nome': aluno.nome},
                            );
                          },
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 16,
                          ),
                          label: const Text('Abrir chat'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  FilaAcaoResumo? _firstOpenCopilotAction(List<FilaAcaoResumo>? actions) {
    for (final item in actions ?? const <FilaAcaoResumo>[]) {
      if (item.status.toUpperCase() != 'ABERTO') continue;
      final source = (item.source ?? '').toUpperCase();
      final mode = (item.sourceMode ?? '').toUpperCase();
      if (item.tipo == 'IA_COPILOTO' ||
          source == 'ALUNO_360' ||
          mode == 'ALUNO_360' ||
          item.createdFromInsight) {
        return item;
      }
    }
    return null;
  }

  Future<bool> _criarTarefaCopiloto(
    BuildContext context,
    WidgetRef ref,
    String acao,
  ) async {
    try {
      final existing = _firstOpenCopilotAction(
        await ref
            .read(dashboardRepositoryProvider)
            .getIaCommandActions(status: 'ABERTO', alunoId: aluno.id),
      );
      if (existing != null) {
        ref.invalidate(alunoOpenIaActionsProvider(aluno.id));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tarefa ja aberta no Command Center.'),
              action: SnackBarAction(
                label: 'Ver',
                onPressed:
                    () => context.push('/dashboard/command-center/copiloto'),
              ),
            ),
          );
        }
        return true;
      }

      final saved = await IaRepository(
        ref.read(apiClientProvider),
      ).salvarAcaoCopiloto(
        alunoId: aluno.id,
        acao: acao,
        motivo:
            'Aluno 360: acao prescrita a partir de perfil, autonomia e risco.',
        modo: 'ALUNO_360',
        source: 'ALUNO_360',
        recommendationId:
            'ALUNO_360_${aluno.id}_${DateTime.now().millisecondsSinceEpoch}',
        createdFromInsight: true,
      );
      final actionKey = (saved['actionKey'] ?? '').toString();
      var persisted = actionKey.isNotEmpty;
      if (persisted) {
        final abertas = await ref
            .read(dashboardRepositoryProvider)
            .getIaCommandActions(status: 'ABERTO', alunoId: aluno.id);
        persisted = abertas.any((item) => item.actionKey == actionKey);
      }
      ref.invalidate(commandCenterProvider);
      ref.invalidate(alunoOpenIaActionsProvider(aluno.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              persisted
                  ? 'Tarefa criada no Command Center.'
                  : 'Servidor aceitou, mas a tarefa ainda nao apareceu.',
            ),
            action:
                persisted
                    ? SnackBarAction(
                      label: 'Ver',
                      onPressed:
                          () => context.push(
                            '/dashboard/command-center/copiloto',
                          ),
                    )
                    : null,
          ),
        );
      }
      return persisted;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nao foi possivel criar tarefa: $e')),
        );
      }
      return false;
    }
  }

  String _mensagemPronta(Aluno aluno, String acao) {
    final primeiroNome =
        aluno.nome.trim().isEmpty
            ? 'tudo bem'
            : aluno.nome.trim().split(' ').first;
    final lower = _cleanCopilotText(acao).toLowerCase();
    if (lower.contains('financeir') || lower.contains('inadimpl')) {
      return 'Oi, $primeiroNome. Preciso alinhar uma pendência rápida para manter seu acesso sem bloqueio. Me responde por aqui?';
    }
    if (lower.contains('perfil') || lower.contains('medida')) {
      return 'Oi, $primeiroNome. Quero completar alguns dados seus para ajustar melhor o plano. Me responde por aqui?';
    }
    if (lower.contains('treino') || lower.contains('carga')) {
      return 'Oi, $primeiroNome. Quero ajustar seu treino para o próximo passo com segurança. Me responde por aqui?';
    }
    return 'Oi, $primeiroNome. Notei que você se afastou um pouco dos treinos. Quer retomar? Me responde por aqui que eu ajusto o plano.';
  }

  String _displayAction(Aluno aluno, String acao) {
    final lower = _cleanCopilotText(acao).toLowerCase();
    if (lower.contains('financeir') || lower.contains('inadimpl')) {
      return 'Alinhar pendência financeira antes de qualquer ajuste.';
    }
    if (lower.contains('perfil') || lower.contains('medida')) {
      return 'Completar dados do perfil para melhorar a prescrição.';
    }
    if (lower.contains('treino') || lower.contains('carga')) {
      return 'Ajustar treino e orientar próximo check-in.';
    }
    return 'Retomar contato e ajustar plano com base na resposta.';
  }

  String _cleanCopilotText(String value) {
    return value
        .replaceAll(RegExp(r'\*\*|__|`'), '')
        .replaceAll(RegExp(r'^\s*[-•]\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final actionAsync = ref.watch(alunoCopilotoActionProvider(aluno.id));
    final openActionsAsync = ref.watch(alunoOpenIaActionsProvider(aluno.id));
    final openTask = _firstOpenCopilotAction(openActionsAsync.valueOrNull);
    final resumo = resumoAsync.valueOrNull;
    final profileCompletion = _perfilCompletion(aluno);
    final signals = _signals(context, aluno, resumo);
    final fallback = _fallbackAction(aluno, resumo);

    return Container(
      padding: const EdgeInsets.all(14),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: BrandPalette.soft(primary, dark: isDark),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.hub_outlined, color: primary, size: 20),
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
                        fontSize: 17,
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
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.4,
            children:
                signals
                    .map((signal) => _Aluno360SignalTile(signal: signal))
                    .toList(),
          ),
          const SizedBox(height: 10),
          if (profileCompletion < 80) ...[
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () => _completeProfile(context, aluno),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: Text(
                  _profileGaps(aluno).length > 1
                      ? 'Resolver lacunas'
                      : 'Completar perfil',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primary,
                  side: BorderSide(color: primary.withValues(alpha: 0.28)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
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
                    action: _displayAction(
                      aluno,
                      (action['acao'] ??
                              action['mensagem'] ??
                              action['descricao'] ??
                              fallback)
                          .toString(),
                    ),
                    reason:
                        (action['motivo'] ?? 'Baseado nos sinais atuais.')
                            .toString(),
                    color: primary,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          openActionsAsync.maybeWhen(
            loading:
                () => const _CopilotTaskStatus(
                  icon: Icons.sync_rounded,
                  title: 'Sincronizando tarefas',
                  subtitle: 'Checando Command Center antes de criar.',
                ),
            data:
                (_) =>
                    openTask == null
                        ? const SizedBox.shrink()
                        : const _CopilotTaskStatus(
                          icon: Icons.task_alt_rounded,
                          title: 'Tarefa aberta',
                          subtitle:
                              'Ja existe no Command Center. Sem duplicar.',
                        ),
            orElse: () => const SizedBox.shrink(),
          ),
          if (openActionsAsync.isLoading || openTask != null)
            const SizedBox(height: 10),
          actionAsync.maybeWhen(
            data:
                (action) => _Aluno360ActionRow(
                  aluno: aluno,
                  primary: primary,
                  existingTask: openTask,
                  acao: _cleanCopilotText(
                    (action['acao'] ??
                            action['mensagem'] ??
                            action['descricao'] ??
                            fallback)
                        .toString(),
                  ),
                  onAssign: (acao) => _criarTarefaCopiloto(context, ref, acao),
                  onPrepareMessage: (acao) => _prepararMensagem(context, acao),
                ),
            orElse:
                () => _Aluno360ActionRow(
                  aluno: aluno,
                  primary: primary,
                  existingTask: openTask,
                  acao: fallback,
                  onAssign: (acao) => _criarTarefaCopiloto(context, ref, acao),
                  onPrepareMessage: (acao) => _prepararMensagem(context, acao),
                ),
          ),
        ],
      ),
    );
  }
}

class _EvolucaoInteligenteCard extends StatelessWidget {
  final int alunoId;
  final String alunoNome;
  final AsyncValue<EvolucaoInteligente> evolucaoAsync;
  final bool isDark;

  const _EvolucaoInteligenteCard({
    required this.alunoId,
    required this.alunoNome,
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

  void _openCheckinMessage(BuildContext context) {
    final firstName =
        alunoNome.trim().isEmpty ? 'aluno' : alunoNome.trim().split(' ').first;
    final message =
        'Oi, $firstName. Como foi seu último treino? Me manda carga, repetições e qualquer sensação fora do normal.';
    final primary = Theme.of(context).colorScheme.primary;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.message_outlined,
                          color: primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mensagem de check-in',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Revise antes de enviar ao aluno.',
                              style: TextStyle(fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Text(message, style: const TextStyle(height: 1.35)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: message),
                            );
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Mensagem copiada.'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copiar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            context.push(
                              '/alunos/$alunoId/chat',
                              extra: alunoNome,
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('Abrir chat'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed:
                      ev.sinal == 'SEM_DADOS'
                          ? () => _openCheckinMessage(context)
                          : () => context.push(
                            '/alunos/$alunoId/treinos-list',
                            extra: alunoNome,
                          ),
                  icon: const Icon(Icons.fitness_center_rounded, size: 16),
                  label: Text(
                    ev.sinal == 'SEM_DADOS'
                        ? 'Pedir check-in'
                        : 'Ajustar treino',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withValues(alpha: 0.32)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
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

class _ProfileGap {
  final IconData icon;
  final String title;
  final String detail;
  final String route;

  const _ProfileGap({
    required this.icon,
    required this.title,
    required this.detail,
    required this.route,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: signal.color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 30,
            decoration: BoxDecoration(
              color: signal.color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mute,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  signal.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
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

class _CopilotTaskStatus extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CopilotTaskStatus({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary, size: 17),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mute,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Aluno360ActionRow extends StatefulWidget {
  final Aluno aluno;
  final Color primary;
  final FilaAcaoResumo? existingTask;
  final String acao;
  final Future<bool> Function(String acao) onAssign;
  final void Function(String acao) onPrepareMessage;

  const _Aluno360ActionRow({
    required this.aluno,
    required this.primary,
    required this.existingTask,
    required this.acao,
    required this.onAssign,
    required this.onPrepareMessage,
  });

  @override
  State<_Aluno360ActionRow> createState() => _Aluno360ActionRowState();
}

class _Aluno360ActionRowState extends State<_Aluno360ActionRow> {
  bool _creating = false;
  bool _created = false;

  Future<void> _handlePrimary() async {
    if (widget.existingTask != null || _created) {
      context.push('/dashboard/command-center/copiloto');
      return;
    }
    setState(() => _creating = true);
    final created = await widget.onAssign(widget.acao);
    if (!mounted) return;
    setState(() {
      _creating = false;
      _created = created;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasTask = widget.existingTask != null || _created;
    final primaryLabel =
        hasTask ? 'Ver tarefa' : (_creating ? 'Criando...' : 'Criar tarefa');
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _creating ? null : _handlePrimary,
            icon:
                _creating
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Icon(
                      hasTask
                          ? Icons.open_in_new_rounded
                          : Icons.task_alt_rounded,
                      size: 17,
                    ),
            label: Text(primaryLabel),
            style: FilledButton.styleFrom(
              backgroundColor: widget.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 112,
          height: 44,
          child: InkWell(
            onTap: () {
              widget.onPrepareMessage(widget.acao);
            },
            borderRadius: BorderRadius.circular(14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.primary.withValues(alpha: 0.28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 15,
                    color: widget.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Abrir chat',
                    style: TextStyle(
                      color: widget.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

  const _HeroStat({required this.label, required this.value});

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
    );
  }
}

class _EmptyMiniState extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _EmptyMiniState({
    required this.icon,
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: mute,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
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
  final String? badge;
  final bool isDark;
  final bool highlight;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.icon,
    required this.label,
    required this.sub,
    this.badge,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: highlight ? primary : ink,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge!,
                            maxLines: 1,
                            style: TextStyle(
                              color: primary,
                              fontSize: 8.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
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
