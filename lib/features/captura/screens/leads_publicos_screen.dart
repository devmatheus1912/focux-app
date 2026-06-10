import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/captura_repository.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

final _repoProvider = Provider(
  (ref) => CapturaRepository(ref.read(apiClientProvider)),
);

class LeadsPublicosScreen extends ConsumerStatefulWidget {
  const LeadsPublicosScreen({super.key});

  @override
  ConsumerState<LeadsPublicosScreen> createState() =>
      _LeadsPublicosScreenState();
}

class _LeadsPublicosScreenState extends ConsumerState<LeadsPublicosScreen> {
  List<SubmissaoCaptura> _leads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final lista = await ref.read(_repoProvider).meus();
      if (!mounted) return;
      setState(() {
        _leads = lista;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return fxScreenA11yScope(
      label: 'Leads do link público',
      child: FxShellScaffold(
        useMesh: true,
        appBar: const FxShellAppBar(
          title: 'Leads do link público',
          subtitle: 'Contatos captados pela sua página',
        ),
        floatingActionButton:
            _leads.isEmpty || _loading
                ? null
                : FloatingActionButton.extended(
                  onPressed: () => context.push('/alunos/novo'),
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Criar aluno'),
                ),
        body:
            _loading
                ? const Center(child: FxLoading())
                : RefreshIndicator(
                  onRefresh: _carregar,
                  child:
                      _leads.isEmpty
                          ? ListView(
                            children: const [
                              SizedBox(height: 48),
                              FxEmptyState(
                                icon: 'users',
                                title: 'Nenhum lead ainda',
                                subtitle:
                                    'Compartilhe o link do seu storefront para começar a captar contatos.',
                              ),
                            ],
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.all(TokensStrip.s4),
                            itemCount: _leads.length,
                            itemBuilder: (_, i) {
                              final l = _leads[i];
                              final primary =
                                  Theme.of(context).colorScheme.primary;
                              final nome = fxTitleCaseName(l.nome);
                              return FxSatelliteListTile(
                                title: nome,
                                accent:
                                    l.convertido ? EagleTokens.good : primary,
                                leading: CircleAvatar(
                                  backgroundColor:
                                      l.convertido
                                          ? EagleTokens.goodSoft
                                          : primary.withValues(alpha: 0.14),
                                  foregroundColor:
                                      l.convertido ? EagleTokens.good : primary,
                                  child: Text(
                                    l.nome.isEmpty ? '?' : fxInitials(nome),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (l.telefone != null &&
                                        l.telefone!.isNotEmpty)
                                      Text('Tel: ${l.telefone}'),
                                    if (l.email != null && l.email!.isNotEmpty)
                                      Text('E-mail: ${l.email}'),
                                    if (l.objetivo != null &&
                                        l.objetivo!.isNotEmpty)
                                      Text('Objetivo: ${l.objetivo}'),
                                  ],
                                ),
                                trailing:
                                    l.convertido
                                        ? const Icon(
                                          Icons.check_circle_rounded,
                                          color: EagleTokens.good,
                                        )
                                        : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (l.email != null &&
                                                l.email!.isNotEmpty)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.person_add_outlined,
                                                ),
                                                tooltip: 'Criar aluno',
                                                onPressed: () {
                                                  final q = <String, String>{
                                                    if (l.email != null)
                                                      'email': l.email!,
                                                    if (l.nome.isNotEmpty)
                                                      'nome': l.nome,
                                                  };
                                                  context.push(
                                                    Uri(
                                                      path: '/alunos/novo',
                                                      queryParameters: q,
                                                    ).toString(),
                                                  );
                                                },
                                              ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.thumb_up_alt_outlined,
                                              ),
                                              tooltip: 'Marcar como convertido',
                                              onPressed: () async {
                                                await ref
                                                    .read(_repoProvider)
                                                    .marcarConvertido(l.id);
                                                await _carregar();
                                              },
                                            ),
                                          ],
                                        ),
                              );
                            },
                          ),
                ),
      ),
    );
  }
}
