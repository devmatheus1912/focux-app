import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/fx_loading.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/captura_repository.dart';

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
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leads do link público')),
      floatingActionButton: _leads.isEmpty || _loading
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/alunos/novo'),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Criar aluno'),
            ),
      body: _loading
          ? const Center(child: FxLoading())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: _leads.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Nenhum lead chegou ainda.\nCompartilhe o link do seu storefront para começar a captar.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _leads.length,
                      itemBuilder: (_, i) {
                        final l = _leads[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: l.convertido
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.primary,
                              child: Text(
                                l.nome.isEmpty
                                    ? '?'
                                    : l.nome[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(l.nome),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (l.telefone != null && l.telefone!.isNotEmpty)
                                  Text('Tel: ${l.telefone}'),
                                if (l.email != null && l.email!.isNotEmpty)
                                  Text('E-mail: ${l.email}'),
                                if (l.objetivo != null &&
                                    l.objetivo!.isNotEmpty)
                                  Text('Objetivo: ${l.objetivo}'),
                              ],
                            ),
                            trailing: l.convertido
                                ? const Icon(Icons.check_circle,
                                    color: Colors.green)
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
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
