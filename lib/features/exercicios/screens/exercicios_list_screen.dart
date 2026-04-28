import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../data/exercicio_repository.dart';
import '../providers/exercicios_provider.dart';

// ---------------------------------------------------------------------------
// Seed import provider (simple FutureProvider for one-shot call)
// ---------------------------------------------------------------------------

const _categoriasFiltro = [
  'Todos',
  'Musculacao',
  'Mobilidade',
  'Lutas',
  'Yoga',
  'Funcional',
];

const _gruposFiltro = [
  'PEITO',
  'COSTAS',
  'OMBROS',
  'BICEPS',
  'TRICEPS',
  'PERNAS',
  'ABDOMEN',
  'CARDIO',
];

const _equipamentosFiltro = [
  'Peso corporal',
  'Halteres',
  'Barra',
  'Maquina',
  'Cabo',
  'Elastico',
  'Kettlebell',
  'Cardio',
];

const _niveisFiltro = ['Iniciante', 'Intermediario', 'Avancado'];
const _mecanicasFiltro = ['Composto', 'Isolado', 'Mobilidade', 'Cardio'];
const _objetivosFiltro = [
  'Forca',
  'Hipertrofia',
  'Emagrecimento',
  'Condicionamento',
  'Mobilidade',
];
const _fontesVideoFiltro = [
  'CURATION_REQUIRED',
  'FOCUX_LIBRARY',
  'PERSONAL_UPLOAD',
];
const _licencasFiltro = ['LICENSED', 'PERSONAL_OWNED', 'PENDING_REVIEW'];

class ExerciciosListScreen extends ConsumerStatefulWidget {
  const ExerciciosListScreen({super.key});

  @override
  ConsumerState<ExerciciosListScreen> createState() =>
      _ExerciciosListScreenState();
}

class _ExerciciosListScreenState extends ConsumerState<ExerciciosListScreen> {
  String _categoriaFiltro = 'Todos';
  bool _apenasFavoritos = false;
  final _tagCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  String _tagFiltro = '';
  String _nomeFiltro = '';
  String? _musculoFiltro;
  String? _equipamentoFiltro;
  String? _nivelFiltro;
  String? _mecanicaFiltro;
  String? _objetivoFiltro;
  bool _comVideoFiltro = false;
  String? _fonteVideoFiltro;
  String? _licencaFiltro;

  @override
  void dispose() {
    _tagCtrl.dispose();
    _nomeCtrl.dispose();
    super.dispose();
  }

  String? get _categoriaParam =>
      _categoriaFiltro == 'Todos' ? null : _categoriaFiltro;

  bool get _hasAdvancedFilters =>
      _musculoFiltro != null ||
      _equipamentoFiltro != null ||
      _nivelFiltro != null ||
      _mecanicaFiltro != null ||
      _objetivoFiltro != null ||
      _comVideoFiltro ||
      _fonteVideoFiltro != null ||
      _licencaFiltro != null;

  @override
  Widget build(BuildContext context) {
    final exerciciosAsync = ref.watch(
      exerciciosFilteredProvider(
        ExercicioFilter(
          nome: _nomeFiltro.isEmpty ? null : _nomeFiltro,
          categoria: _categoriaParam,
          tag: _tagFiltro.isEmpty ? null : _tagFiltro,
          musculoAlvo: _musculoFiltro,
          equipamento: _equipamentoFiltro,
          nivel: _nivelFiltro,
          mecanica: _mecanicaFiltro,
          objetivo: _objetivoFiltro,
          hasVideo: _comVideoFiltro ? true : null,
          videoSource: _fonteVideoFiltro,
          licenseStatus: _licencaFiltro,
          favoritos: _apenasFavoritos ? true : null,
        ),
      ),
    );
    final curadoriaAsync = ref.watch(exerciciosCuradoriaProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [EagleTokens.brand, EagleTokens.brandInk],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: EagleTokens.brand.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final criado = await context.push<bool>('/exercicios/novo');
            if (criado == true) ref.invalidate(exerciciosFilteredProvider);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CATALOGO',
                          style: TextStyle(
                            fontSize: 12,
                            color: mute,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Exercicios',
                          style: TextStyle(
                            fontSize: 32,
                            color: ink,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _apenasFavoritos ? Icons.star : Icons.star_border,
                      color: _apenasFavoritos ? EagleTokens.warn : mute,
                    ),
                    tooltip: 'Apenas favoritos',
                    onPressed:
                        () => setState(
                          () => _apenasFavoritos = !_apenasFavoritos,
                        ),
                  ),
                  IconButton(
                    icon: Badge(
                      isLabelVisible: _hasAdvancedFilters,
                      smallSize: 8,
                      child: Icon(
                        Icons.tune_rounded,
                        color:
                            _hasAdvancedFilters
                                ? Theme.of(context).colorScheme.primary
                                : mute,
                      ),
                    ),
                    tooltip: 'Filtros avancados',
                    onPressed: () => _openFilters(context),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: mute),
                    tooltip: 'Mais opcoes',
                    onSelected: (value) {
                      if (value == 'seed_v1') _importarSeedV1(context, ref);
                      if (value == 'seed_premium_v1') {
                        _importarSeedPremiumV1(context, ref);
                      }
                      if (value == 'curadoria_lote') {
                        _openCuradoriaLote(context, ref);
                      }
                      if (value == 'importar_midias') {
                        _openImportarMidias(context, ref);
                      }
                    },
                    itemBuilder:
                        (_) => const [
                          PopupMenuItem(
                            value: 'seed_v1',
                            child: Row(
                              children: [
                                Icon(Icons.download_rounded, size: 20),
                                SizedBox(width: 10),
                                Text('Importar biblioteca Focux v1'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'seed_premium_v1',
                            child: Row(
                              children: [
                                Icon(Icons.workspace_premium_rounded, size: 20),
                                SizedBox(width: 10),
                                Text('Importar seed premium 1500'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'curadoria_lote',
                            child: Row(
                              children: [
                                Icon(Icons.fact_check_rounded, size: 20),
                                SizedBox(width: 10),
                                Text('Curadoria em lote'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'importar_midias',
                            child: Row(
                              children: [
                                Icon(Icons.video_file_rounded, size: 20),
                                SizedBox(width: 10),
                                Text('Importar midias CSV/JSON'),
                              ],
                            ),
                          ),
                        ],
                  ),
                  if (context.canPop())
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: mute),
                      onPressed: () => context.pop(),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: TextField(
                controller: _nomeCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por nome',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _nomeFiltro.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _nomeCtrl.clear();
                              setState(() => _nomeFiltro = '');
                            },
                          )
                          : null,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _nomeFiltro = v.trim()),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: TextField(
                controller: _tagCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por tag (ex: #EmCasa)',
                  prefixIcon: const Icon(Icons.tag),
                  suffixIcon:
                      _tagFiltro.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _tagCtrl.clear();
                              setState(() => _tagFiltro = '');
                            },
                          )
                          : null,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _tagFiltro = v.trim()),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: _categoriasFiltro.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = _categoriasFiltro[i];
                  final selecionado = cat == _categoriaFiltro;
                  return FilterChip(
                    label: Text(cat),
                    selected: selecionado,
                    onSelected: (_) => setState(() => _categoriaFiltro = cat),
                  );
                },
              ),
            ),
            if (_hasAdvancedFilters)
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  children: [
                    _ActiveFilterChip(
                      label: _musculoFiltro,
                      onDeleted: () => setState(() => _musculoFiltro = null),
                    ),
                    _ActiveFilterChip(
                      label: _equipamentoFiltro,
                      onDeleted:
                          () => setState(() => _equipamentoFiltro = null),
                    ),
                    _ActiveFilterChip(
                      label: _nivelFiltro,
                      onDeleted: () => setState(() => _nivelFiltro = null),
                    ),
                    _ActiveFilterChip(
                      label: _mecanicaFiltro,
                      onDeleted: () => setState(() => _mecanicaFiltro = null),
                    ),
                    _ActiveFilterChip(
                      label: _objetivoFiltro,
                      onDeleted: () => setState(() => _objetivoFiltro = null),
                    ),
                    _ActiveFilterChip(
                      label: _comVideoFiltro ? 'Com video' : null,
                      onDeleted: () => setState(() => _comVideoFiltro = false),
                    ),
                    _ActiveFilterChip(
                      label: _formatSourceLabel(_fonteVideoFiltro),
                      onDeleted: () => setState(() => _fonteVideoFiltro = null),
                    ),
                    _ActiveFilterChip(
                      label: _formatLicenseLabel(_licencaFiltro),
                      onDeleted: () => setState(() => _licencaFiltro = null),
                    ),
                  ],
                ),
              ),
            curadoriaAsync.when(
              loading: () => const _CuradoriaSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
              data:
                  (resumo) => _CuradoriaCard(
                    resumo: resumo,
                    onImportSeed: () => _importarSeedV1(context, ref),
                  ),
            ),
            Expanded(
              child: exerciciosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
                data: (exercicios) {
                  if (exercicios.isEmpty) {
                    return const Center(
                      child: Text('Nenhum exercicio encontrado.'),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh:
                        () async => ref.invalidate(exerciciosFilteredProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 96),
                      itemCount: exercicios.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder:
                          (context, i) => _ExercicioTile(
                            exercicio: exercicios[i],
                            onFavoritoToggle:
                                () =>
                                    ref.invalidate(exerciciosFilteredProvider),
                          ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importarSeedV1(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Importar biblioteca Focux v1'),
            content: const Text(
              'Isso vai importar 26 exercicios iniciais da biblioteca Focux com videos, thumbnails e orientacoes profissionais.\n\nSe o exercicio ja existir, sera atualizado. A operacao e segura e pode ser repetida.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Importar'),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Importando biblioteca...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final count =
          await ref.read(exercicioRepositoryProvider).importarSeedV1();
      ref.invalidate(exerciciosFilteredProvider);
      ref.invalidate(exerciciosCuradoriaProvider);
      messenger.clearSnackBars();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${count > 0 ? count : 26} exercicios importados com sucesso.',
            ),
            backgroundColor: EagleTokens.good,
          ),
        );
      }
    } catch (e) {
      messenger.clearSnackBars();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erro ao importar: $e'),
            backgroundColor: EagleTokens.bad,
          ),
        );
      }
    }
  }

  Future<void> _importarSeedPremiumV1(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Importar seed premium 1500'),
            content: const Text(
              'Isso vai importar 1500 exercicios com taxonomia completa e cobertura muscular balanceada.\n\nVideos oficiais nao serao falsificados. Os itens entram como PENDING_REVIEW/CURATION_REQUIRED ate a curadoria anexar videos licenciados ou videos proprios.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Importar 1500'),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Importando seed premium...'),
          ],
        ),
        duration: Duration(seconds: 45),
      ),
    );

    try {
      final count =
          await ref.read(exercicioRepositoryProvider).importarSeedPremiumV1();
      ref.invalidate(exerciciosFilteredProvider);
      ref.invalidate(exerciciosCuradoriaProvider);
      messenger.clearSnackBars();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '$count exercicios premium importados para curadoria.',
            ),
            backgroundColor: EagleTokens.good,
          ),
        );
      }
    } catch (e) {
      messenger.clearSnackBars();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erro ao importar seed premium: $e'),
            backgroundColor: EagleTokens.bad,
          ),
        );
      }
    }
  }

  Future<void> _openCuradoriaLote(BuildContext context, WidgetRef ref) async {
    var novaFonte = _fonteVideoFiltro ?? 'PERSONAL_UPLOAD';
    var novaLicenca =
        _licencaFiltro == 'LICENSED' ? 'LICENSED' : 'PERSONAL_OWNED';
    final videoCtrl = TextEditingController();
    final thumbCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, modalSetState) => AlertDialog(
                  title: const Text('Curadoria em lote'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aplica nos exercicios que batem com os filtros atuais. Use filtros antes para evitar alterar a biblioteca inteira.',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? EagleTokens.darkInkMute
                                    : EagleTokens.inkMute,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _FilterDropdown(
                          label: 'Nova fonte',
                          value: novaFonte,
                          values: _fontesVideoFiltro,
                          formatter: _formatSourceLabel,
                          onChanged:
                              (v) => modalSetState(
                                () => novaFonte = v ?? 'PERSONAL_UPLOAD',
                              ),
                        ),
                        const SizedBox(height: 10),
                        _FilterDropdown(
                          label: 'Nova licenca',
                          value: novaLicenca,
                          values: _licencasFiltro,
                          formatter: _formatLicenseLabel,
                          onChanged:
                              (v) => modalSetState(
                                () => novaLicenca = v ?? 'PERSONAL_OWNED',
                              ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: videoCtrl,
                          decoration: const InputDecoration(
                            labelText: 'URL de video para aplicar',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: thumbCtrl,
                          decoration: const InputDecoration(
                            labelText: 'URL de thumbnail para aplicar',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Aplicar lote'),
                    ),
                  ],
                ),
          ),
    );
    if (confirm != true) {
      videoCtrl.dispose();
      thumbCtrl.dispose();
      return;
    }

    final videoUrl = videoCtrl.text.trim();
    final thumbnailUrl = thumbCtrl.text.trim();
    videoCtrl.dispose();
    thumbCtrl.dispose();
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Aplicando curadoria em lote...')),
    );

    try {
      final result = await ref
          .read(exercicioRepositoryProvider)
          .curarLote(
            nome: _nomeFiltro.isEmpty ? null : _nomeFiltro,
            categoria: _categoriaParam,
            tag: _tagFiltro.isEmpty ? null : _tagFiltro,
            musculoAlvo: _musculoFiltro,
            equipamento: _equipamentoFiltro,
            nivel: _nivelFiltro,
            mecanica: _mecanicaFiltro,
            objetivo: _objetivoFiltro,
            hasVideo: _comVideoFiltro ? true : null,
            videoSource: _fonteVideoFiltro,
            licenseStatus: _licencaFiltro,
            novoVideoSource: novaFonte,
            novoLicenseStatus: novaLicenca,
            novoVideoUrl: videoUrl.isEmpty ? null : videoUrl,
            novoThumbnailUrl: thumbnailUrl.isEmpty ? null : thumbnailUrl,
          );
      ref.invalidate(exerciciosFilteredProvider);
      ref.invalidate(exerciciosCuradoriaProvider);
      messenger.clearSnackBars();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${result.afetados} exercicios atualizados · ${result.prontosParaAluno} prontos para aluno.',
            ),
            backgroundColor: EagleTokens.good,
          ),
        );
      }
    } catch (e) {
      messenger.clearSnackBars();
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erro na curadoria em lote: $e'),
            backgroundColor: EagleTokens.bad,
          ),
        );
      }
    }
  }

  Future<void> _openImportarMidias(BuildContext context, WidgetRef ref) async {
    final payloadCtrl = TextEditingController(
      text:
          'importKey,videoUrl,thumbnailUrl,videoSource,licenseStatus\n'
          'supino-reto-peso-corporal-iniciante-hipertrofia|peito|peso-corporal,https://cdn.exemplo/supino.mp4,https://cdn.exemplo/supino.jpg,FOCUX_LIBRARY,LICENSED',
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Importar midias CSV/JSON'),
            content: SizedBox(
              width: 560,
              child: TextField(
                controller: payloadCtrl,
                minLines: 8,
                maxLines: 14,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Importar'),
              ),
            ],
          ),
    );
    if (confirm != true) {
      payloadCtrl.dispose();
      return;
    }

    final raw = payloadCtrl.text.trim();
    payloadCtrl.dispose();
    if (!context.mounted) return;

    try {
      final midias = _parseMidiasPayload(raw);
      final result = await ref
          .read(exercicioRepositoryProvider)
          .importarMidias(midias);
      ref.invalidate(exerciciosFilteredProvider);
      ref.invalidate(exerciciosCuradoriaProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.atualizados}/${result.total} midias importadas · ${result.naoEncontrados} nao encontradas.',
            ),
            backgroundColor:
                result.naoEncontrados == 0
                    ? EagleTokens.good
                    : EagleTokens.warn,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao importar midias: $e'),
            backgroundColor: EagleTokens.bad,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _parseMidiasPayload(String raw) {
    if (raw.isEmpty) {
      throw Exception('conteudo vazio');
    }
    if (raw.startsWith('{') || raw.startsWith('[')) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      if (decoded is Map && decoded['midias'] is List) {
        return (decoded['midias'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      throw Exception('JSON precisa ser lista ou objeto com midias');
    }
    return _parseMidiasCsv(raw);
  }

  List<Map<String, dynamic>> _parseMidiasCsv(String raw) {
    final lines =
        raw
            .split(RegExp(r'\r?\n'))
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList();
    if (lines.length < 2) {
      throw Exception('CSV precisa de cabecalho e ao menos uma linha');
    }
    final headers = lines.first.split(',').map((e) => e.trim()).toList();
    return [
      for (final line in lines.skip(1))
        {
          for (var i = 0; i < headers.length; i++)
            if (i < line.split(',').length &&
                line.split(',')[i].trim().isNotEmpty)
              headers[i]: line.split(',')[i].trim(),
        },
    ];
  }

  Future<void> _openFilters(BuildContext context) async {
    var musculo = _musculoFiltro;
    var equipamento = _equipamentoFiltro;
    var nivel = _nivelFiltro;
    var mecanica = _mecanicaFiltro;
    var objetivo = _objetivoFiltro;
    var comVideo = _comVideoFiltro;
    var fonteVideo = _fonteVideoFiltro;
    var licenca = _licencaFiltro;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Filtros da biblioteca',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  _FilterDropdown(
                    label: 'Grupo muscular',
                    value: musculo,
                    values: _gruposFiltro,
                    onChanged: (v) => modalSetState(() => musculo = v),
                  ),
                  const SizedBox(height: 10),
                  _FilterDropdown(
                    label: 'Equipamento',
                    value: equipamento,
                    values: _equipamentosFiltro,
                    onChanged: (v) => modalSetState(() => equipamento = v),
                  ),
                  const SizedBox(height: 10),
                  _FilterDropdown(
                    label: 'Nivel',
                    value: nivel,
                    values: _niveisFiltro,
                    onChanged: (v) => modalSetState(() => nivel = v),
                  ),
                  const SizedBox(height: 10),
                  _FilterDropdown(
                    label: 'Mecanica',
                    value: mecanica,
                    values: _mecanicasFiltro,
                    onChanged: (v) => modalSetState(() => mecanica = v),
                  ),
                  const SizedBox(height: 10),
                  _FilterDropdown(
                    label: 'Objetivo',
                    value: objetivo,
                    values: _objetivosFiltro,
                    onChanged: (v) => modalSetState(() => objetivo = v),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    value: comVideo,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Somente com video'),
                    secondary: const Icon(Icons.play_circle_fill_rounded),
                    onChanged: (value) => modalSetState(() => comVideo = value),
                  ),
                  const SizedBox(height: 10),
                  _FilterDropdown(
                    label: 'Fonte do video',
                    value: fonteVideo,
                    values: _fontesVideoFiltro,
                    formatter: _formatSourceLabel,
                    onChanged: (v) => modalSetState(() => fonteVideo = v),
                  ),
                  const SizedBox(height: 10),
                  _FilterDropdown(
                    label: 'Licenca',
                    value: licenca,
                    values: _licencasFiltro,
                    formatter: _formatLicenseLabel,
                    onChanged: (v) => modalSetState(() => licenca = v),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            modalSetState(() {
                              musculo = null;
                              equipamento = null;
                              nivel = null;
                              mecanica = null;
                              objetivo = null;
                              comVideo = false;
                              fonteVideo = null;
                              licenca = null;
                            });
                          },
                          child: const Text('Limpar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _musculoFiltro = musculo;
                              _equipamentoFiltro = equipamento;
                              _nivelFiltro = nivel;
                              _mecanicaFiltro = mecanica;
                              _objetivoFiltro = objetivo;
                              _comVideoFiltro = comVideo;
                              _fonteVideoFiltro = fonteVideo;
                              _licencaFiltro = licenca;
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String? _formatSourceLabel(String? value) {
    return switch (value) {
      'CURATION_REQUIRED' => 'Curadoria pendente',
      'FOCUX_LIBRARY' => 'Biblioteca Focux',
      'PERSONAL_UPLOAD' => 'Video do personal',
      null || '' => null,
      _ => value.replaceAll('_', ' '),
    };
  }

  String? _formatLicenseLabel(String? value) {
    return switch (value) {
      'LICENSED' => 'Licenciado',
      'PERSONAL_OWNED' => 'Proprio',
      'PENDING_REVIEW' => 'Pendente',
      null || '' => null,
      _ => value.replaceAll('_', ' '),
    };
  }
}

class _CuradoriaCard extends StatelessWidget {
  final ExercicioCuradoriaResumo resumo;
  final VoidCallback onImportSeed;

  const _CuradoriaCard({required this.resumo, required this.onImportSeed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? EagleTokens.darkCardHi : EagleTokens.card;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primary = Theme.of(context).colorScheme.primary;
    final topGroups = resumo.porGrupoMuscular.take(3).toList();
    final alert =
        resumo.alertas.isNotEmpty
            ? resumo.alertas.first
            : 'Biblioteca pronta para curadoria fina.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${resumo.scoreProntidao}',
                    style: TextStyle(
                      color: primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Curadoria premium',
                        style: TextStyle(
                          color: ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${resumo.total}/${resumo.metaPremium} exercicios · ${resumo.prontosParaAluno} prontos para aluno',
                        style: TextStyle(
                          color: mute,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Importar seed',
                  onPressed: onImportSeed,
                  icon: Icon(Icons.download_rounded, color: primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: (resumo.scoreProntidao / 100).clamp(0.0, 1.0),
                backgroundColor: primary.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation(primary),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CuradoriaMetric(
                  label: 'Com video',
                  value: '${resumo.comVideo}',
                  color: EagleTokens.good,
                ),
                _CuradoriaMetric(
                  label: 'Licencas ok',
                  value: '${resumo.licenciados + resumo.videosProprios}',
                  color: primary,
                ),
                _CuradoriaMetric(
                  label: 'Pendentes',
                  value: '${resumo.pendentesLicenca}',
                  color: EagleTokens.warn,
                ),
                _CuradoriaMetric(
                  label: 'Faltam',
                  value: '${resumo.faltamParaMeta}',
                  color: EagleTokens.bad,
                ),
              ],
            ),
            if (topGroups.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final group in topGroups)
                    Chip(
                      label: Text(
                        '${_prettyGroup(group.label)} ${group.total}',
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: mute),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alert,
                    style: TextStyle(color: mute, fontSize: 12.5, height: 1.25),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _prettyGroup(String value) {
    if (value == 'NAO_INFORMADO') return 'Sem grupo';
    return value;
  }
}

class _CuradoriaMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _CuradoriaMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CuradoriaSkeleton extends StatelessWidget {
  const _CuradoriaSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
          ),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> values;
  final String? Function(String?)? formatter;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    this.formatter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items:
          values
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(formatter?.call(v) ?? v),
                ),
              )
              .toList(),
      onChanged: onChanged,
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String? label;
  final VoidCallback onDeleted;

  const _ActiveFilterChip({required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    if (label == null || label!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(
        label: Text(label!),
        onDeleted: onDeleted,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ExercicioTile extends ConsumerWidget {
  final Exercicio exercicio;
  final VoidCallback onFavoritoToggle;
  const _ExercicioTile({
    required this.exercicio,
    required this.onFavoritoToggle,
  });

  Future<void> _toggleFavorito(WidgetRef ref, BuildContext context) async {
    final repo = ref.read(exercicioRepositoryProvider);
    try {
      if (exercicio.favoritado) {
        await repo.desfavoritarExercicio(exercicio.id);
      } else {
        await repo.favoritarExercicio(exercicio.id);
      }
      onFavoritoToggle();
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao atualizar favorito.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final card = isDark ? EagleTokens.darkCardHi : EagleTokens.card;
    final subtitle = [
      exercicio.musculoAlvo,
      exercicio.categoria,
      exercicio.equipamento,
      exercicio.nivel,
    ].where((s) => s != null && s.isNotEmpty).join(' | ');
    final mediaThumb =
        exercicio.thumbnailUrl?.isNotEmpty == true
            ? exercicio.thumbnailUrl
            : exercicio.gifUrl?.isNotEmpty == true
            ? exercicio.gifUrl
            : null;
    final licensed = exercicio.licenseStatus == 'LICENSED';

    return Material(
      color: card,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: line),
        ),
        leading:
            mediaThumb != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Image.network(
                      mediaThumb,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => const Icon(Icons.fitness_center),
                    ),
                  ),
                )
                : const CircleAvatar(child: Icon(Icons.fitness_center)),
        title: Text(
          exercicio.nome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (licensed || exercicio.videoSource?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (licensed)
                    const _MiniMediaBadge(
                      icon: Icons.verified_rounded,
                      label: 'Licenciado',
                      color: EagleTokens.good,
                    ),
                  if (exercicio.videoSource?.isNotEmpty == true)
                    _MiniMediaBadge(
                      icon: Icons.video_library_rounded,
                      label: _formatSource(exercicio.videoSource!),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (exercicio.videoUrl?.isNotEmpty == true)
              const Icon(
                Icons.play_circle_fill_rounded,
                color: EagleTokens.good,
              ),
            IconButton(
              icon: Icon(
                exercicio.favoritado ? Icons.star : Icons.star_border,
                color: exercicio.favoritado ? EagleTokens.warn : null,
              ),
              tooltip:
                  exercicio.favoritado
                      ? 'Remover dos favoritos'
                      : 'Adicionar aos favoritos',
              onPressed: () => _toggleFavorito(ref, context),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.push('/exercicios/${exercicio.id}'),
      ),
    );
  }

  String _formatSource(String value) {
    return switch (value) {
      'FOCUX_LIBRARY' => 'Focux',
      'PERSONAL_UPLOAD' => 'Personal',
      _ => value.replaceAll('_', ' '),
    };
  }
}

class _MiniMediaBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniMediaBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
