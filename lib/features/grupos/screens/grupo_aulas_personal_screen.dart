import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/grupo_aula_repository.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

class GrupoAulasPersonalScreen extends ConsumerStatefulWidget {
  const GrupoAulasPersonalScreen({super.key});

  @override
  ConsumerState<GrupoAulasPersonalScreen> createState() =>
      _GrupoAulasPersonalScreenState();
}

class _GrupoAulasPersonalScreenState
    extends ConsumerState<GrupoAulasPersonalScreen> {
  List<GrupoAula> _aulas = [];
  bool _loading = true;
  String? _erro;
  DateTime? _fetchedAt;

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final aulas =
          await GrupoAulaRepository(
            ref.read(apiClientProvider),
          ).listarPersonal();
      if (mounted) {
        setState(() {
          _aulas = aulas;
          _loading = false;
          _fetchedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
    }
  }

  Future<void> _criar() async {
    final result = await showFxHomeSheet<_NovaAulaResult>(
      context,
      builder: (_) => const _NovaAulaSheet(),
    );
    if (result == null) return;

    if (!result.fim.isAfter(result.inicio)) {
      if (mounted) {
        FeedbackHelper.showWarn(
          context,
          'Horário de fim deve ser depois do início.',
        );
      }
      return;
    }

    try {
      await GrupoAulaRepository(ref.read(apiClientProvider)).criar(
        titulo: result.titulo,
        descricao: result.descricao,
        inicio: result.inicio,
        fim: result.fim,
        capacidadeMax: result.capacidade,
        localAula: result.local,
      );
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Aula criada!');
      }
      _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    return fxScreenA11yScope(
      label: 'Aulas em grupo',
      child: FxShellScaffold(
        appBar: FxShellAppBar(
          title: 'Aulas em grupo',
          subtitle: freshnessLabel,
          onBack: () => context.pop(),
        ),
        floatingActionButton:
            _erro != null
                ? null
                : FloatingActionButton.extended(
                  onPressed: _criar,
                  icon: const Icon(Icons.add),
                  label: const Text('Nova aula'),
                ),
        body:
            _loading
                ? const SkeletonList(count: 4)
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: isDark,
                  primary: Theme.of(context).colorScheme.primary,
                  message: _erro!,
                  onRetry: _load,
                )
                : RefreshIndicator(
                  onRefresh: _load,
                  child:
                      _aulas.isEmpty
                          ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 72),
                              FxEmptyState(
                                icon: 'calendar',
                                title: 'Nenhuma aula criada ainda',
                                subtitle:
                                    'Crie uma aula em grupo para abrir vagas aos seus alunos.',
                                action: FxEmptyAction(
                                  label: 'Nova aula',
                                  onTap: _criar,
                                ),
                              ),
                            ],
                          )
                          : ListView.separated(
                            padding: const EdgeInsets.all(TokensStrip.s4),
                            itemCount: _aulas.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final a = _aulas[i];
                              final lotada = a.inscritos >= a.capacidadeMax;
                              return FxSatelliteListTile(
                                title: a.titulo,
                                titleCase: false,
                                accent: lotada ? EagleTokens.warn : null,
                                subtitle: Text(
                                  '${_fmt(a.inicio)} · ${a.inscritos}/${a.capacidadeMax}'
                                  '${a.localAula != null ? ' · ${a.localAula}' : ''}',
                                ),
                                trailing:
                                    lotada
                                        ? const Chip(label: Text('Lotada'))
                                        : Chip(
                                          label: Text(
                                            '${a.capacidadeMax - a.inscritos} vagas',
                                          ),
                                        ),
                              );
                            },
                          ),
                ),
      ),
    );
  }
}

class _NovaAulaResult {
  final String titulo;
  final String? descricao;
  final DateTime inicio;
  final DateTime fim;
  final int capacidade;
  final String? local;

  _NovaAulaResult({
    required this.titulo,
    required this.inicio,
    required this.fim,
    required this.capacidade,
    this.descricao,
    this.local,
  });
}

class _NovaAulaSheet extends StatefulWidget {
  const _NovaAulaSheet();

  @override
  State<_NovaAulaSheet> createState() => _NovaAulaSheetState();
}

class _NovaAulaSheetState extends State<_NovaAulaSheet> {
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _local = TextEditingController();
  final _capacidade = TextEditingController(text: '20');
  late DateTime _inicio;
  late DateTime _fim;

  @override
  void initState() {
    super.initState();
    final agora = DateTime.now();
    _inicio = DateTime(agora.year, agora.month, agora.day + 1, 7, 0);
    _fim = _inicio.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _local.dispose();
    _capacidade.dispose();
    super.dispose();
  }

  Future<void> _pickInicio() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _inicio,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_inicio),
    );
    if (time == null) return;
    setState(() {
      _inicio = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (!_fim.isAfter(_inicio)) _fim = _inicio.add(const Duration(hours: 1));
    });
  }

  Future<void> _pickFim() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fim,
      firstDate: _inicio,
      lastDate: _inicio.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fim),
    );
    if (time == null) return;
    setState(() {
      _fim = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _salvar() {
    if (_titulo.text.trim().isEmpty) {
      FeedbackHelper.showError(context, 'Título é obrigatório.');
      return;
    }
    Navigator.pop(
      context,
      _NovaAulaResult(
        titulo: _titulo.text.trim(),
        descricao:
            _descricao.text.trim().isEmpty ? null : _descricao.text.trim(),
        local: _local.text.trim().isEmpty ? null : _local.text.trim(),
        capacidade: int.tryParse(_capacidade.text.trim()) ?? 20,
        inicio: _inicio,
        fim: _fim,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return FxHomeSheetSurface(
      isDark: isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            FxHomeSheetHandle(isDark: isDark),
            SizedBox(height: TokensStrip.s4),
            FxHomeSheetHeader(
              isDark: isDark,
              title: 'Nova aula em grupo',
              subtitle: 'Defina horário, capacidade e local.',
              leading: Icon(Icons.groups_outlined, color: primary, size: 18),
            ),
            SizedBox(height: TokensStrip.s3),
            TextField(
              controller: _titulo,
              decoration: const InputDecoration(
                labelText: 'Título *',
                hintText: 'Ex: Funcional ao ar livre',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descricao,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickInicio,
                    icon: const Icon(Icons.event),
                    label: Text('Início ${_fmt(_inicio)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFim,
                    icon: const Icon(Icons.event_available),
                    label: Text('Fim ${_fmt(_fim)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _capacidade,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacidade'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _local,
                    decoration: const InputDecoration(
                      labelText: 'Local (opcional)',
                      hintText: 'Studio, Praia, Online…',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _salvar,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Criar aula'),
            ),
          ],
        ),
      ),
    );
  }
}
