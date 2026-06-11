import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
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

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
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
      if (mounted) setState(() => _loading = false);
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
    return fxScreenA11yScope(
      label: 'Aulas em grupo',
      child: FxShellScaffold(
        appBar: FxShellAppBar(
          title: 'Aulas em grupo',
          onBack: () => context.pop(),
        ),
        body:
            _loading
                ? const Center(child: FxLoading())
                : RefreshIndicator(
                  onRefresh: _load,
                  child:
                      _aulas.isEmpty
                          ? ListView(
                            children: const [
                              SizedBox(height: 120),
                              Center(
                                child: Text(
                                  'Nenhuma aula disponível no momento.',
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
