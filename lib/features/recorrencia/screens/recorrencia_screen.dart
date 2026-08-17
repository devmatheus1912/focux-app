import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../../alunos/data/aluno_repository.dart';
import '../data/recorrencia_repository.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

class RecorrenciaScreen extends ConsumerStatefulWidget {
  const RecorrenciaScreen({super.key});

  @override
  ConsumerState<RecorrenciaScreen> createState() => _RecorrenciaScreenState();
}

class _RecorrenciaScreenState extends ConsumerState<RecorrenciaScreen> {
  List<RecorrenciaAssinatura> _items = [];
  bool _loading = true;
  String? _erro;

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
      final items =
          await RecorrenciaRepository(ref.read(apiClientProvider)).listar();
      if (mounted) {
        setState(() {
          _items = items;
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

  Future<void> _criar() async {
    final alunos = await AlunoRepository(ref.read(apiClientProvider)).listar();
    if (alunos.isEmpty) {
      if (!mounted) return;
      FeedbackHelper.showWarn(context, 'Cadastre um aluno primeiro.');
      return;
    }
    int? alunoId = alunos.first.id;
    final valorCtrl = TextEditingController(text: '199');

    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Nova recorrência'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: alunoId,
                  items:
                      alunos
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.nome),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => alunoId = v,
                  decoration: const InputDecoration(labelText: 'Aluno'),
                ),
                TextField(
                  controller: valorCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Valor mensal (R\$)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Criar'),
              ),
            ],
          ),
    );
    if (ok != true || alunoId == null) return;

    try {
      final r = await RecorrenciaRepository(ref.read(apiClientProvider)).criar(
        alunoId: alunoId!,
        valor: double.tryParse(valorCtrl.text.replaceAll(',', '.')) ?? 199,
      );
      if (r.initPoint != null && r.initPoint!.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: r.initPoint!));
        if (!mounted) return;
        FeedbackHelper.showSuccess(
          context,
          'Link de assinatura copiado — envie ao aluno.',
        );
      }
      _load();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return fxScreenA11yScope(
      label: 'Recorrência MP',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Recorrência MP',
          subtitle: 'Assinaturas Mercado Pago',
          onBack: () => context.pop(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _criar,
          icon: const Icon(Icons.add),
          label: const Text('Nova'),
        ),
        body:
            _loading
                ? const Center(child: FxLoading())
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
                      _items.isEmpty
                          ? ListView(
                            children: const [
                              SizedBox(height: 48),
                              FxEmptyState(
                                icon: 'coin',
                                title: 'Nenhuma assinatura ainda',
                                subtitle:
                                    'Crie a primeira recorrência para cobrar seus alunos via Mercado Pago.',
                              ),
                            ],
                          )
                          : ListView.separated(
                            padding: const EdgeInsets.all(TokensStrip.s4),
                            itemCount: _items.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 2),
                            itemBuilder: (_, i) {
                              final item = _items[i];
                              final pendente = item.status == 'PENDENTE';
                              return FxSatelliteListTile(
                                title:
                                    item.alunoNome ?? 'Aluno #${item.alunoId}',
                                accent: pendente ? EagleTokens.warn : null,
                                subtitle: Text(
                                  'R\$ ${item.valor.toStringAsFixed(0)} · ${item.status}'
                                  '${item.proximaCobranca != null ? ' · Próx: ${item.proximaCobranca}' : ''}',
                                ),
                                trailing:
                                    item.initPoint != null && pendente
                                        ? IconButton(
                                          icon: Icon(
                                            Icons.link_rounded,
                                            color: primary,
                                          ),
                                          onPressed: () async {
                                            final uri = Uri.parse(
                                              item.initPoint!,
                                            );
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(
                                                uri,
                                                mode:
                                                    LaunchMode
                                                        .externalApplication,
                                              );
                                            }
                                          },
                                        )
                                        : null,
                              );
                            },
                          ),
                ),
      ),
    );
  }
}
