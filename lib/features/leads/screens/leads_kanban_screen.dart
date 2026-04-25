import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/lead_repository.dart';

const _kCols = ['LEAD', 'TESTE', 'ATIVO', 'CANCELADO'];
const _kLabels = {
  'LEAD': 'Lead',
  'TESTE': 'Teste',
  'ATIVO': 'Ativo',
  'CANCELADO': 'Cancelado',
};

class LeadsKanbanScreen extends ConsumerStatefulWidget {
  const LeadsKanbanScreen({super.key});
  @override
  ConsumerState<LeadsKanbanScreen> createState() => _LeadsKanbanScreenState();
}

class _LeadsKanbanScreenState extends ConsumerState<LeadsKanbanScreen> {
  Map<String, List<Lead>> _cols = {for (final c in _kCols) c: []};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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
      if (mounted) setState(() { _cols = cols; _loading = false; });
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _moverPara(Lead lead, String novoStatus) async {
    if (lead.status == novoStatus) return;
    try {
      await LeadRepository(ref.read(apiClientProvider))
          .atualizar(lead.id, {'status': novoStatus});
      setState(() {
        _cols[lead.status]?.remove(lead);
        _cols[novoStatus]?.add(lead);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao mover: $e')));
      }
    }
  }

  Color _colColor(String status, bool isDark) {
    if (status == 'TESTE') return isDark ? const Color(0xFFE2B46F) : EagleTokens.warn;
    if (status == 'ATIVO') return isDark ? const Color(0xFF6FE296) : EagleTokens.good;
    if (status == 'CANCELADO') return isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return isDark ? EagleTokens.brandAccent : EagleTokens.brand; // LEAD
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = isDark ? EagleTokens.brandAccent : EagleTokens.brand;

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
                      if (Navigator.canPop(context)) ...[
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Icon(Icons.arrow_back_ios_new, size: 24, color: ink),
                          ),
                        ),
                      ],
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CRM', style: TextStyle(fontSize: 12, color: brand, fontWeight: 700, letterSpacing: 0.6)),
                          const SizedBox(height: 2),
                          Text('Funil de Leads', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: ink, letterSpacing: -0.5)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: brand,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (!isDark) BoxShadow(color: brand.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ],
              ),
            ),

            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else ...[
              // Summary row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: _kCols.where((c) => c != 'CANCELADO').map((col) {
                    final cColor = _colColor(col, isDark);
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: col == 'ATIVO' ? 0 : 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: isDark ? null : Border.all(color: line),
                        ),
                        child: Column(
                          children: [
                            Container(width: 8, height: 8, margin: const EdgeInsets.only(bottom: 6), decoration: BoxDecoration(color: cColor, shape: BoxShape.circle)),
                            Text('${_cols[col]?.length ?? 0}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ink)),
                            Text(_kLabels[col]!, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: mute)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Kanban columns horizontally scrollable
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _kCols.map((col) {
                      final cColor = _colColor(col, isDark);
                      final leads = _cols[col] ?? [];
                      
                      return DragTarget<Lead>(
                        onAcceptWithDetails: (details) => _moverPara(details.data, col),
                        builder: (context, candidates, rejected) {
                          return Container(
                            width: 260,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: candidates.isNotEmpty
                                ? BoxDecoration(color: cColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16))
                                : null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    children: [
                                      Container(width: 8, height: 8, decoration: BoxDecoration(color: cColor, shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Text(_kLabels[col]!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
                                      const SizedBox(width: 4),
                                      Text('(${leads.length})', style: TextStyle(fontSize: 11, color: mute, fontFamily: 'monospace')),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 100),
                                    itemCount: leads.length + 1,
                                    itemBuilder: (ctx, i) {
                                      if (i == leads.length) {
                                        return Container(
                                          height: 40,
                                          margin: const EdgeInsets.only(top: 8),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: mute.withValues(alpha: 0.3), width: 1.5, style: BorderStyle.solid), // dashed conceptually
                                          ),
                                          alignment: Alignment.center,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.add, size: 14, color: mute),
                                              const SizedBox(width: 6),
                                              Text('Adicionar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: mute)),
                                            ],
                                          ),
                                        );
                                      }
                                      
                                      final l = leads[i];
                                      return Draggable<Lead>(
                                        data: l,
                                        feedback: Material(
                                          color: Colors.transparent,
                                          child: SizedBox(width: 260, child: _LeadCard(lead: l, cColor: cColor, isDark: isDark)),
                                        ),
                                        childWhenDragging: Opacity(opacity: 0.3, child: _LeadCard(lead: l, cColor: cColor, isDark: isDark)),
                                        child: _LeadCard(lead: l, cColor: cColor, isDark: isDark),
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

  const _LeadCard({required this.lead, required this.cColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final brand = isDark ? EagleTokens.brandAccent : EagleTokens.brand;

    // Simulate tag/origem/tempo since the API model doesn't strictly have them all
    final tag = lead.status == 'LEAD' ? 'novo' : (lead.status == 'TESTE' ? 'urgente' : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border(left: BorderSide(color: cColor, width: 3)) : Border.all(color: line).copyWith(left: BorderSide(color: cColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: isDark ? EagleTokens.brandDeep : EagleTokens.brand, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(lead.nome.isNotEmpty ? lead.nome[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(lead.nome, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ink), overflow: TextOverflow.ellipsis)),
              if (tag != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: cColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(tag, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: cColor)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lead.telefone?.isNotEmpty == true ? lead.telefone! : 'Orgânico', style: TextStyle(fontSize: 11, color: mute)),
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
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : EagleTokens.brandSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 12, color: brand),
                      const SizedBox(width: 4),
                      Text('WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: brand)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : line.withValues(alpha: 0.5),
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
