import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';

// ── Provider ──────────────────────────────────────────────────────────────────
final _buscaQueryProvider = StateProvider<String>((ref) => '');

final buscaResultsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, query) async {
  if (query.trim().length < 2) return {};
  final api = ref.read(apiClientProvider);
  final res = await api.dio.get('/api/busca', queryParameters: {'q': query});
  return res.data as Map<String, dynamic>;
});

// ── Widget ────────────────────────────────────────────────────────────────────
class BuscaGlobalWidget extends ConsumerStatefulWidget {
  const BuscaGlobalWidget({super.key});

  @override
  ConsumerState<BuscaGlobalWidget> createState() => _BuscaGlobalWidgetState();
}

class _BuscaGlobalWidgetState extends ConsumerState<BuscaGlobalWidget> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(buscaResultsProvider(_query));

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar alunos, treinos, cobranças...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
          ),
          onChanged: (v) {
            Future.delayed(const Duration(milliseconds: 350), () {
              if (v == _ctrl.text) setState(() => _query = v.trim());
            });
          },
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.length < 2
          ? _buildEmptyState()
          : resultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (data) => _buildResults(context, data),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 72, color: const Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text('Digite pelo menos 2 caracteres', style: TextStyle(color: EagleTokens.inkMute)),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context, Map<String, dynamic> data) {
    final alunos = (data['alunos'] as List? ?? []);
    final treinos = (data['treinos'] as List? ?? []);
    final cobrancas = (data['cobrancas'] as List? ?? []);

    final total = alunos.length + treinos.length + cobrancas.length;
    if (total == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.find_in_page_outlined, size: 72, color: const Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text('Nenhum resultado para "$_query"', style: TextStyle(color: EagleTokens.inkMute)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (alunos.isNotEmpty) ...[
          _sectionHeader('Alunos', Icons.person_outline),
          ...alunos.map((a) => _resultTile(context, a, EagleTokens.brand)),
          const SizedBox(height: 16),
        ],
        if (treinos.isNotEmpty) ...[
          _sectionHeader('Treinos', Icons.fitness_center),
          ...treinos.map((t) => _resultTile(context, t, EagleTokens.good)),
          const SizedBox(height: 16),
        ],
        if (cobrancas.isNotEmpty) ...[
          _sectionHeader('Cobranças', Icons.receipt_long_outlined),
          ...cobrancas.map((c) => _resultTile(context, c, EagleTokens.warn)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4B5563)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF374151), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _resultTile(BuildContext context, dynamic item, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(Icons.arrow_forward_ios, size: 14, color: color),
        ),
        title: Text(item['titulo'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(item['subtitulo'] ?? '', overflow: TextOverflow.ellipsis),
        onTap: () {
          Navigator.of(context).pop();
          final link = item['link'] as String? ?? '';
          if (link.isNotEmpty) context.push(link);
        },
      ),
    );
  }
}
