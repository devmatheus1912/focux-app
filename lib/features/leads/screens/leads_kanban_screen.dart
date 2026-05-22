import 'package:flutter/material.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/lead_repository.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

const _kCols = ['LEAD', 'TESTE', 'ATIVO', 'INADIMPLENTE', 'CANCELADO'];
const _kLabels = {
  'LEAD': 'Lead',
  'TESTE': 'Teste',
  'ATIVO': 'Ativo',
  'INADIMPLENTE': 'Inadimplente',
  'CANCELADO': 'Cancelado',
};
const _kHints = {
  'LEAD': 'Contato novo que ainda precisa de abordagem.',
  'TESTE': 'Pessoa em aula experimental ou periodo de teste.',
  'ATIVO': 'Aluno convertido e em acompanhamento.',
  'INADIMPLENTE': 'Aluno com pendencia financeira para recuperar.',
  'CANCELADO': 'Lead ou aluno perdido, sem acao ativa.',
};

class LeadsKanbanScreen extends ConsumerStatefulWidget {
  const LeadsKanbanScreen({super.key});
  @override
  ConsumerState<LeadsKanbanScreen> createState() => _LeadsKanbanScreenState();
}

class _LeadsKanbanScreenState extends ConsumerState<LeadsKanbanScreen> {
  Map<String, List<Lead>> _cols = {for (final c in _kCols) c: []};
  bool _loading = true;
  bool _showIntro = false;

  @override
  void initState() {
    super.initState();
    _loadIntro();
    _load();
  }

  Future<void> _loadIntro() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => _showIntro = !(prefs.getBool('leads_kanban_intro_seen') ?? false),
      );
    }
  }

  Future<void> _dismissIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('leads_kanban_intro_seen', true);
    if (mounted) setState(() => _showIntro = false);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final leads = await LeadRepository(ref.read(apiClientProvider)).listar();
      final Map<String, List<Lead>> cols = {for (final c in _kCols) c: []};
      for (final l in leads) {
        final col = _kCols.contains(l.status) ? l.status : 'LEAD';
        cols[col]!.add(l);
      }
      if (mounted) {
        setState(() {
          _cols = cols;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _moverPara(Lead lead, String novoStatus) async {
    if (lead.status == novoStatus) return;
    try {
      await LeadRepository(
        ref.read(apiClientProvider),
      ).atualizar(lead.id, {'status': novoStatus});
      setState(() {
        _cols[lead.status]?.remove(lead);
        _cols[novoStatus]?.add(lead);
      });
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    }
  }

  Color _colColor(String status, bool isDark, Color fallback) {
    if (status == 'TESTE') {
      return isDark ? const Color(0xFFE2B46F) : EagleTokens.warn;
    }
    if (status == 'ATIVO') {
      return isDark ? const Color(0xFF6FE296) : EagleTokens.good;
    }
    if (status == 'INADIMPLENTE') return EagleTokens.bad;
    if (status == 'CANCELADO') {
      return isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    }
    return fallback; // LEAD
  }

  Future<void> _novoLeadRapido() async {
    final nomeCtrl = TextEditingController();
    final telefoneCtrl = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Novo lead'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: telefoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () async {
                  if (nomeCtrl.text.trim().isEmpty) return;
                  try {
                    await LeadRepository(ref.read(apiClientProvider)).criar(
                      nome: nomeCtrl.text.trim(),
                      telefone: telefoneCtrl.text.trim(),
                      origem: 'Kanban',
                    );
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (ctx.mounted) {
                      FeedbackHelper.showSnackBar(
                        ctx,
                        SnackBar(content: Text('Erro: $e')),
                      );
                    }
                  }
                },
                child: const Text('Criar'),
              ),
            ],
          ),
    );
    nomeCtrl.dispose();
    telefoneCtrl.dispose();
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final brand = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: FxShellAppBar(
        title: 'Funil de Leads',
        subtitle: 'CRM',
        onBack: () => safePopOrGo(context, '/leads'),
        actions: [
          TextButton.icon(
            onPressed: _novoLeadRapido,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Lead'),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showIntro)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: brand.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: brand.withValues(alpha: 0.20)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.swipe, color: brand, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Funil de Vendas: arraste cards entre colunas conforme cada contato avanca.',
                          style: TextStyle(
                            color: ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _dismissIntro,
                        icon: Icon(Icons.close, color: mute, size: 18),
                      ),
                    ],
                  ),
                ),
              ),

            if (_loading)
              const Expanded(child: FxLoading())
            else ...[
              // Summary row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children:
                      _kCols
                          .where((c) => c != 'CANCELADO' && c != 'INADIMPLENTE')
                          .map((col) {
                            final cColor = _colColor(col, isDark, brand);
                            return Expanded(
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: col == 'ATIVO' ? 0 : 8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                decoration: fxListCardDecoration(
                                  context,
                                  accent: cColor,
                                  radius: 14,
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(bottom: 6),
                                      decoration: BoxDecoration(
                                        color: cColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Text(
                                      '${_cols[col]?.length ?? 0}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: ink,
                                      ),
                                    ),
                                    Text(
                                      _kLabels[col]!,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: mute,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          })
                          .toList(),
                ),
              ),

              // Kanban columns horizontally scrollable
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        _kCols.map((col) {
                          final cColor = _colColor(col, isDark, brand);
                          final leads = _cols[col] ?? [];

                          return DragTarget<Lead>(
                            onAcceptWithDetails:
                                (details) => _moverPara(details.data, col),
                            builder: (context, candidates, rejected) {
                              return Container(
                                width: 260,
                                margin: const EdgeInsets.only(right: 12),
                                decoration:
                                    candidates.isNotEmpty
                                        ? BoxDecoration(
                                          color: cColor.withValues(alpha: 0.05),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        )
                                        : null,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: cColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Tooltip(
                                            message: _kHints[col]!,
                                            child: Text(
                                              _kLabels[col]!,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: ink,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Tooltip(
                                            message: _kHints[col]!,
                                            child: Icon(
                                              Icons.info_outline,
                                              size: 13,
                                              color: mute,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '(${leads.length})',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: mute,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        padding: const EdgeInsets.only(
                                          bottom: 100,
                                        ),
                                        itemCount: leads.length + 1,
                                        itemBuilder: (ctx, i) {
                                          if (i == leads.length) {
                                            return Container(
                                              height: 40,
                                              margin: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: mute.withValues(
                                                    alpha: 0.3,
                                                  ),
                                                  width: 1.5,
                                                  style: BorderStyle.solid,
                                                ), // dashed conceptually
                                              ),
                                              alignment: Alignment.center,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.add,
                                                    size: 14,
                                                    color: mute,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Adicionar',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: mute,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }

                                          final l = leads[i];
                                          return Draggable<Lead>(
                                            data: l,
                                            feedback: Material(
                                              color: Colors.transparent,
                                              child: SizedBox(
                                                width: 260,
                                                child: _LeadCard(
                                                  lead: l,
                                                  cColor: cColor,
                                                  isDark: isDark,
                                                ),
                                              ),
                                            ),
                                            childWhenDragging: Opacity(
                                              opacity: 0.3,
                                              child: _LeadCard(
                                                lead: l,
                                                cColor: cColor,
                                                isDark: isDark,
                                              ),
                                            ),
                                            child: _LeadCard(
                                              lead: l,
                                              cColor: cColor,
                                              isDark: isDark,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final Lead lead;
  final Color cColor;
  final bool isDark;

  const _LeadCard({
    required this.lead,
    required this.cColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = Theme.of(context).colorScheme.primary;
    final brandSoft = BrandPalette.soft(brand, dark: isDark);
    final brandDeep = BrandPalette.deep(brand);

    // Simulate tag/origem/tempo since the API model doesn't strictly have them all
    final tag =
        lead.status == 'LEAD'
            ? 'novo'
            : (lead.status == 'TESTE' ? 'urgente' : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: fxListCardDecoration(
        context,
        accent: cColor,
        radius: 16,
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
                  color: isDark ? brandDeep : brand,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  lead.nome.isNotEmpty ? lead.nome[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lead.nome,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: cColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lead.telefone?.isNotEmpty == true ? lead.telefone! : 'Orgânico',
                style: TextStyle(fontSize: 11, color: mute),
              ),
              Text('2d', style: TextStyle(fontSize: 10.5, color: mute)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : brandSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 12, color: brand),
                      const SizedBox(width: 4),
                      Text(
                        'WhatsApp',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : line.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.chevron_right, size: 16, color: mute),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
