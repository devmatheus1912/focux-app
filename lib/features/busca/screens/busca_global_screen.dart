import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/loading_shimmer.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../models/busca_global_models.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final buscaQueryProvider = StateProvider<String>((ref) => '');
final buscaFilterProvider = StateProvider<BuscaTipo>((ref) => BuscaTipo.todos);

final buscaResultadoProvider = FutureProvider.autoDispose<BuscaGlobalResult?>((
  ref,
) async {
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

  Widget _buildFilterChips() {
    final selected = ref.watch(buscaFilterProvider);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: BuscaTipo.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final tipo = BuscaTipo.values[i];
          final isSelected = tipo == selected;
          return FilterChip(
            selected: isSelected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tipo.icon,
                  size: 14,
                  color: isSelected ? Colors.white : TokensStrip.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(tipo.label),
              ],
            ),
            selectedColor: Theme.of(context).colorScheme.primary,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : TokensStrip.textPrimary,
            ),
            backgroundColor:
                Theme.of(context).brightness == Brightness.dark
                    ? EagleTokens.surfaceDark
                    : EagleTokens.surfaceGray,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onSelected: (_) {
              HapticFeedback.selectionClick();
              ref.read(buscaFilterProvider.notifier).state = tipo;
            },
          );
        },
      ),
    );
  }

  Widget _buildSection(String titulo, List<BuscaItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 16, 16, 8),
          child: Row(
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: EagleTokens.iconGray,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(TokensStrip.rInput),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map(
          (item) => _BuscaItemTile(item: item, onTap: () => _abrirItem(item)),
        ),
      ],
    );
  }

  List<BuscaItem> _filterByTipo(BuscaGlobalResult result, BuscaTipo filter) =>
      switch (filter) {
        BuscaTipo.todos => [
          ...result.alunos,
          ...result.treinos,
          ...result.cobrancas,
        ],
        BuscaTipo.aluno => result.alunos,
        BuscaTipo.treino => result.treinos,
        BuscaTipo.cobranca => result.cobrancas,
      };

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

    Uri? uri;
    try {
      uri = Uri.parse(raw);
    } catch (_) {
      uri = null;
    }
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      _showError('Destino não suportado.');
      return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('Abrir link externo?'),
            content: Text(uri.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('Abrir'),
              ),
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
    FeedbackHelper.showInfo(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final resultAsync = ref.watch(buscaResultadoProvider);
    final query = ref.watch(buscaQueryProvider);
    final filter = ref.watch(buscaFilterProvider);

    final chrome = ShellChrome.of(context);
    return fxScreenA11yScope(
      label: 'Busca global',
      child: FxShellScaffold(
        useMesh: true,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Semantics(
            textField: true,
            label: 'Campo de busca global',
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              style: TextStyle(fontSize: 16, color: chrome.ink),
              decoration: InputDecoration(
                hintText: 'Buscar alunos, treinos, cobranças...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: chrome.mute),
              ),
              onChanged: (v) => ref.read(buscaQueryProvider.notifier).state = v,
            ),
          ),
          actions: [
            if (query.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Limpar busca',
                onPressed: () {
                  _ctrl.clear();
                  ref.read(buscaQueryProvider.notifier).state = '';
                },
              ),
          ],
        ),
        body: Column(
          children: [
            _buildFilterChips(),
            const SizedBox(height: 8),
            Expanded(
              child: resultAsync.when(
                loading:
                    () =>
                        const ShimmerListLoading(itemCount: 6, itemHeight: 64),
                error:
                    (e, _) => FxErrorState(
                      chromeOnDark: chrome.isDark,
                      primary: Theme.of(context).colorScheme.primary,
                      message: friendlyError(e),
                      onRetry: () => ref.invalidate(buscaResultadoProvider),
                    ),
                data: (result) {
                  if (query.trim().length < 2) {
                    return const FxEmptyState(
                      icon: 'search',
                      title: 'Digite ao menos 2 caracteres',
                      subtitle: 'Busque por alunos, treinos ou cobranças.',
                    );
                  }
                  if (result == null || result.isEmpty) {
                    return FxEmptyState(
                      icon: 'search',
                      title: 'Nenhum resultado para "$query"',
                      subtitle:
                          'Tente outro nome, apelido ou trecho do treino.',
                    );
                  }
                  if (filter != BuscaTipo.todos) {
                    final items = _filterByTipo(result, filter);
                    if (items.isEmpty) {
                      return FxEmptyState(
                        icon: 'search',
                        title: 'Nenhum resultado em ${filter.label}',
                        subtitle:
                            'Troque o filtro para ver os outros resultados.',
                      );
                    }
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            TokensStrip.s4,
                            12,
                            16,
                            4,
                          ),
                          child: Text(
                            '${items.length} resultado${items.length > 1 ? 's' : ''} em ${filter.label}',
                            style: TextStyle(
                              fontSize: 13,
                              color: TokensStrip.textSecondary,
                            ),
                          ),
                        ),
                        ...items.map(
                          (item) => _BuscaItemTile(
                            item: item,
                            onTap: () => _abrirItem(item),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    );
                  }
                  return ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          8,
                          16,
                          0,
                        ),
                        child: Text(
                          '${result.totalCount} resultado${result.totalCount > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: TokensStrip.textSecondary,
                          ),
                        ),
                      ),
                      _buildSection('ALUNOS', result.alunos),
                      _buildSection('TREINOS', result.treinos),
                      _buildSection('COBRANÇAS', result.cobrancas),
                      const SizedBox(height: 32),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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
    'ALUNO' => EagleTokens.legacyBrandCyan,
    'TREINO' => EagleTokens.buscaTreino,
    'COBRANCA' => EagleTokens.goldStar,
    _ => TokensStrip.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final cor = _colorForTipo(item.tipo);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          onTap: onTap,
          child: Ink(
            decoration: fxListCardDecoration(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cor.withValues(alpha: 0.1),
                    child: Icon(_iconForTipo(item.tipo), color: cor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.titulo,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (item.subtitulo != null)
                          Text(
                            item.subtitulo!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
