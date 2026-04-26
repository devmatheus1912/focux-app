import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/auth/providers/auth_provider.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class BuscaItem {
  final int id;
  final String titulo;
  final String? subtitulo;
  final String tipo;
  final String url;

  BuscaItem({required this.id, required this.titulo, this.subtitulo, required this.tipo, required this.url});

  factory BuscaItem.fromJson(Map<String, dynamic> j) => BuscaItem(
        id: j['id'],
        titulo: j['titulo'] ?? j['nome'] ?? '',
        subtitulo: j['subtitulo'] ?? j['email'] ?? j['objetivo'],
        tipo: j['tipo'],
        url: j['url'],
      );
}

class BuscaGlobalResult {
  final List<BuscaItem> alunos;
  final List<BuscaItem> treinos;
  final List<BuscaItem> cobrancas;

  BuscaGlobalResult({required this.alunos, required this.treinos, required this.cobrancas});

  factory BuscaGlobalResult.fromJson(Map<String, dynamic> j) => BuscaGlobalResult(
        alunos: (j['alunos'] as List? ?? []).map((e) => BuscaItem.fromJson(e as Map<String, dynamic>)).toList(),
        treinos: (j['treinos'] as List? ?? []).map((e) => BuscaItem.fromJson(e as Map<String, dynamic>)).toList(),
        cobrancas: (j['cobrancas'] as List? ?? []).map((e) => BuscaItem.fromJson(e as Map<String, dynamic>)).toList(),
      );

  bool get isEmpty => alunos.isEmpty && treinos.isEmpty && cobrancas.isEmpty;
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final buscaQueryProvider = StateProvider<String>((ref) => '');

final buscaResultadoProvider = FutureProvider.autoDispose<BuscaGlobalResult?>((ref) async {
  final query = ref.watch(buscaQueryProvider);
  if (query.trim().length < 2) return null;
  final api = ref.read(apiClientProvider);
  final res = await api.dio.get('/api/busca?q=${Uri.encodeComponent(query)}');
  return BuscaGlobalResult.fromJson(res.data as Map<String, dynamic>);
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class BuscaGlobalScreen extends ConsumerStatefulWidget {
  const BuscaGlobalScreen({super.key});

  @override
  ConsumerState<BuscaGlobalScreen> createState() => _BuscaGlobalScreenState();
}

class _BuscaGlobalScreenState extends ConsumerState<BuscaGlobalScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildSection(String titulo, List<BuscaItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(titulo,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF717171),
                  letterSpacing: 1)),
        ),
        ...items.map((item) => _BuscaItemTile(item: item, onTap: () => _abrirItem(item))),
      ],
    );
  }

  /// Whitelist of internal route prefixes the app is allowed to deep-link to from
  /// search results. Anything coming from the backend that does NOT match one of
  /// these prefixes is treated as untrusted and routed via [url_launcher] (with
  /// confirmation) instead of being navigated into the app shell.
  static const _allowedInternalPrefixes = <String>[
    '/alunos/',
    '/treinos/',
    '/financeiro/',
    '/agenda/',
    '/checkin/',
    '/chat/',
    '/leads/',
    '/perfil/',
  ];

  Future<void> _abrirItem(BuscaItem item) async {
    final raw = item.url.trim();
    if (raw.isEmpty) {
      _showError('Item sem destino válido.');
      return;
    }

    // Internal deep link: must start with a whitelisted prefix to avoid arbitrary
    // route injection (e.g. backend returning '/admin/system' or 'https://evil/...').
    if (raw.startsWith('/')) {
      final normalized = _normalizePath(raw);
      final isAllowed = _allowedInternalPrefixes.any(normalized.startsWith);
      if (!isAllowed) {
        _showError('Destino não permitido.');
        return;
      }
      if (!mounted) return;
      context.push(normalized);
      return;
    }

    // Absolute URL: only http(s), and only after explicit user confirmation.
    Uri? uri;
    try { uri = Uri.parse(raw); } catch (_) { uri = null; }
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      _showError('Destino não suportado.');
      return;
    }

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Abrir link externo?'),
        content: Text(uri.toString()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Abrir')),
        ],
      ),
    );
    if (ok != true) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) _showError('Não foi possível abrir este link.');
  }

  String _normalizePath(String path) {
    var p = path;
    while (p.contains('//')) {
      p = p.replaceAll('//', '/');
    }
    return p;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final resultAsync = ref.watch(buscaResultadoProvider);
    final query = ref.watch(buscaQueryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? EagleTokens.darkBg
          : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'Buscar alunos, treinos, cobranças...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Color(0xFF717171)),
          ),
          onChanged: (v) {
            ref.read(buscaQueryProvider.notifier).state = v;
          },
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                ref.read(buscaQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: resultAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Erro: $e', style: const TextStyle(color: EagleTokens.bad))),
        data: (result) {
          if (query.trim().length < 2) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, size: 64, color: Color(0xFFD1D5DB)),
                  const SizedBox(height: 16),
                  Text('Digite ao menos 2 caracteres',
                      style: TextStyle(color: EagleTokens.inkMute)),
                ],
              ),
            );
          }
          if (result == null || result.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: Color(0xFFD1D5DB)),
                  const SizedBox(height: 16),
                  Text('Nenhum resultado para "$query"',
                      style: TextStyle(color: EagleTokens.inkMute)),
                ],
              ),
            );
          }
          return ListView(
            children: [
              _buildSection('ALUNOS', result.alunos),
              _buildSection('TREINOS', result.treinos),
              _buildSection('COBRANÇAS', result.cobrancas),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _BuscaItemTile extends StatelessWidget {
  final BuscaItem item;
  final VoidCallback onTap;

  const _BuscaItemTile({required this.item, required this.onTap});

  IconData _iconForTipo(String tipo) => switch (tipo) {
        'ALUNO' => Icons.person,
        'TREINO' => Icons.fitness_center,
        'COBRANCA' => Icons.attach_money,
        _ => Icons.search,
      };

  Color _colorForTipo(String tipo) => switch (tipo) {
        'ALUNO' => const Color(0xFF2B4A9E),
        'TREINO' => const Color(0xFF22C55E),
        'COBRANCA' => const Color(0xFFF59E0B),
        _ => EagleTokens.inkMute,
      };

  @override
  Widget build(BuildContext context) {
    final cor = _colorForTipo(item.tipo);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cor.withValues(alpha: 0.1),
        child: Icon(_iconForTipo(item.tipo), color: cor, size: 20),
      ),
      title: Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: item.subtitulo != null
          ? Text(item.subtitulo!, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
