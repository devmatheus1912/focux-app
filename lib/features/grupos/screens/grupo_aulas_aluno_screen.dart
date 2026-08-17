import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/grupo_aula_repository.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

class GrupoAulasAlunoScreen extends ConsumerStatefulWidget {
  const GrupoAulasAlunoScreen({super.key});

  @override
  ConsumerState<GrupoAulasAlunoScreen> createState() =>
      _GrupoAulasAlunoScreenState();
}

class _GrupoAulasAlunoScreenState extends ConsumerState<GrupoAulasAlunoScreen> {
  List<GrupoAula> _aulas = [];
  bool _loading = true;
  String? _erro;

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
          await GrupoAulaRepository(ref.read(apiClientProvider)).disponiveis();
      if (mounted) {
        setState(() {
          _aulas = aulas;
          _loading = false;
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

  Future<void> _inscrever(GrupoAula aula) async {
    try {
      await GrupoAulaRepository(ref.read(apiClientProvider)).inscrever(aula.id);
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Inscrição confirmada!');
        _load();
      }
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return fxScreenA11yScope(
      label: 'Aulas em grupo',
      child: FxShellScaffold(
        appBar: FxShellAppBar(
          title: 'Aulas em grupo',
          onBack: () => context.pop(),
        ),
        body:
            _loading
                ? const SkeletonList(count: 4)
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: isDark,
                  primary: primary,
                  message: _erro!,
                  onRetry: _load,
                )
                : RefreshIndicator(
                  onRefresh: _load,
                  child:
                      _aulas.isEmpty
                          ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 72),
                              FxEmptyState(
                                icon: 'calendar',
                                title: 'Nenhuma aula disponível',
                                subtitle:
                                    'Quando seu personal abrir uma aula em grupo, ela aparece aqui.',
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
                              return FxSatelliteListTile(
                                title: a.titulo,
                                titleCase: false,
                                accent: a.lotada ? EagleTokens.warn : primary,
                                subtitle: Text(
                                  '${_fmt(a.inicio)} · ${a.inscritos}/${a.capacidadeMax}'
                                  '${a.localAula != null ? ' · ${a.localAula}' : ''}',
                                ),
                                trailing:
                                    a.lotada
                                        ? const Text('Lotada')
                                        : FilledButton(
                                          onPressed: () => _inscrever(a),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: primary,
                                          ),
                                          child: const Text('Inscrever'),
                                        ),
                              );
                            },
                          ),
                ),
      ),
    );
  }
}
