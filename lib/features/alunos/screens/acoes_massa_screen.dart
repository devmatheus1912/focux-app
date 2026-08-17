import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/aluno_contact_utils.dart';
import '../data/aluno_repository.dart';
import '../providers/alunos_provider.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

class AcoesMassaScreen extends ConsumerStatefulWidget {
  const AcoesMassaScreen({super.key});

  @override
  ConsumerState<AcoesMassaScreen> createState() => _AcoesMassaScreenState();
}

class _AcoesMassaScreenState extends ConsumerState<AcoesMassaScreen> {
  final Set<int> _selecionados = {};
  bool _processando = false;

  void _toggleSelecionado(int id) {
    setState(() {
      if (_selecionados.contains(id)) {
        _selecionados.remove(id);
      } else {
        _selecionados.add(id);
      }
    });
  }

  void _toggleTodos(List<Aluno> alunos) {
    setState(() {
      if (_selecionados.length == alunos.length) {
        _selecionados.clear();
      } else {
        _selecionados.addAll(alunos.map((a) => a.id));
      }
    });
  }

  void _mostrarAcoes(BuildContext context) {
    if (_selecionados.isEmpty) {
      FeedbackHelper.showError(context, 'Selecione pelo menos um aluno');
      return;
    }
    showModalBottomSheet(
      context: context,
      builder:
          (sheetContext) => _BottomSheetAcoes(
            qtd: _selecionados.length,
            onMarcarPagos: () {
              Navigator.pop(sheetContext);
              _marcarPagos();
            },
            onAtualizarStatus: (status) {
              Navigator.pop(sheetContext);
              _atualizarStatus(status);
            },
            onExcluir: () {
              Navigator.pop(sheetContext);
              _confirmarExclusao(context);
            },
          ),
    );
  }

  Future<void> _confirmarExclusao(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excluir alunos?'),
            content: Text(
              '${_selecionados.length} aluno(s) serão excluídos permanentemente. Esta ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: EagleTokens.bad),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );
    if (confirmar == true) _excluirSelecionados();
  }

  Future<void> _excluirSelecionados() async {
    setState(() => _processando = true);
    final repo = AlunoRepository(ref.read(apiClientProvider));
    int sucesso = 0;
    int falha = 0;
    for (final id in _selecionados) {
      try {
        await repo.excluirAluno(id);
        sucesso++;
      } catch (_) {
        falha++;
      }
    }
    if (mounted) {
      invalidateAlunosCaches(ref);
      if (falha > 0) {
        FeedbackHelper.showError(
          context,
          '$sucesso excluído(s), $falha não puderam ser removidos.',
        );
      } else {
        FeedbackHelper.showSuccess(context, '$sucesso aluno(s) excluído(s).');
      }
      setState(() => _selecionados.clear());
    }
    if (mounted) setState(() => _processando = false);
  }

  Future<void> _marcarPagos() async {
    setState(() => _processando = true);
    try {
      await ref
          .read(apiClientProvider)
          .dio
          .post(
            '/api/financeiro/mensalidades/lote-pago',
            data: {'alunoIds': _selecionados.toList()},
          );
      if (mounted) {
        FeedbackHelper.showSuccess(
          context,
          '${_selecionados.length} aluno(s) marcado(s) como pagos',
        );
        setState(() => _selecionados.clear());
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
    if (mounted) setState(() => _processando = false);
  }

  Future<void> _atualizarStatus(String novoStatus) async {
    setState(() => _processando = true);
    final repo = AlunoRepository(ref.read(apiClientProvider));
    int sucesso = 0;
    int falha = 0;
    for (final id in _selecionados) {
      try {
        await repo.atualizarAluno(id, {'status': novoStatus});
        sucesso++;
      } catch (_) {
        falha++;
      }
    }
    if (mounted) {
      invalidateAlunosCaches(ref);
      if (falha > 0) {
        FeedbackHelper.showError(
          context,
          '$sucesso atualizado(s), $falha não puderam ser alterados.',
        );
      } else {
        FeedbackHelper.showSuccess(context, '$sucesso aluno(s) atualizado(s).');
      }
      setState(() => _selecionados.clear());
    }
    if (mounted) setState(() => _processando = false);
  }

  @override
  Widget build(BuildContext context) {
    final alunosAsync = ref.watch(alunosProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forDark(isDark);

    return fxScreenA11yScope(
      label: 'Ações em Massa',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Ações em Massa',
          subtitle: 'Aplique mudanças a vários alunos de uma vez',
          onBack: () => safePopOrGo(context, '/alunos'),
          actions: [
            alunosAsync.whenOrNull(
                  data:
                      (alunos) => TextButton(
                        onPressed: () => _toggleTodos(alunos),
                        child: Text(
                          _selecionados.length == alunos.length
                              ? 'Desmarcar todos'
                              : 'Selecionar todos',
                          style: TextStyle(color: chrome.ink),
                        ),
                      ),
                ) ??
                const SizedBox(),
          ],
        ),
        body: alunosAsync.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.all(TokensStrip.s4),
                child: SkeletonList(count: 6),
              ),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: friendlyError(e),
                onRetry: () => ref.invalidate(alunosProvider),
                title: 'Não conseguimos carregar os alunos',
              ),
          data:
              (alunos) =>
                  alunos.isEmpty
                      ? const FxEmptyState(
                        icon: 'users',
                        title: 'Nenhum aluno cadastrado',
                        subtitle:
                            'Cadastre alunos na lista principal para usar ações em massa.',
                      )
                      : Stack(
                        children: [
                          ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: alunos.length,
                            itemBuilder: (_, i) {
                              final a = alunos[i];
                              final sel = _selecionados.contains(a.id);
                              return CheckboxListTile(
                                value: sel,
                                onChanged: (_) => _toggleSelecionado(a.id),
                                title: Text(a.nome),
                                subtitle: Text(
                                  '${maskEmailForList(a.email)} · ${a.status}',
                                  style: TextStyle(color: chrome.mute),
                                ),
                                secondary: CircleAvatar(
                                  child: Text(a.nome[0].toUpperCase()),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              );
                            },
                          ),
                          if (_processando)
                            Positioned.fill(
                              child: ColoredBox(
                                color: Colors.black.withValues(alpha: 0.27),
                                child: const FxLoading(),
                              ),
                            ),
                        ],
                      ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _processando ? null : () => _mostrarAcoes(context),
          icon: const Icon(Icons.bolt),
          label: Text(
            _selecionados.isEmpty
                ? 'Aplicar ação'
                : 'Aplicar (${_selecionados.length})',
          ),
        ),
      ),
    );
  }
}

class _BottomSheetAcoes extends StatefulWidget {
  final int qtd;
  final VoidCallback onMarcarPagos;
  final void Function(String) onAtualizarStatus;
  final VoidCallback onExcluir;

  const _BottomSheetAcoes({
    required this.qtd,
    required this.onMarcarPagos,
    required this.onAtualizarStatus,
    required this.onExcluir,
  });

  @override
  State<_BottomSheetAcoes> createState() => _BottomSheetAcoesState();
}

class _BottomSheetAcoesState extends State<_BottomSheetAcoes> {
  String _statusSelecionado = 'ATIVO';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.qtd} aluno(s) selecionado(s)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          FxLiquidPrimaryButton(
            icon: Icons.attach_money,
            label: 'Marcar mensalidade como paga',
            onPressed: widget.onMarcarPagos,
          ),
          const SizedBox(height: TokensStrip.s4),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Atualizar status',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _statusSelecionado,
            decoration: FxInputDeco.build(context, 'Novo status'),
            items:
                ['ATIVO', 'INATIVO', 'BLOQUEADO']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
            onChanged: (v) => setState(() => _statusSelecionado = v!),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => widget.onAtualizarStatus(_statusSelecionado),
            icon: const Icon(Icons.update),
            label: const Text('Aplicar status'),
          ),
          const SizedBox(height: TokensStrip.s4),
          const Divider(),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: widget.onExcluir,
            icon: const Icon(Icons.delete_outline, color: EagleTokens.bad),
            label: const Text(
              'Excluir selecionados',
              style: TextStyle(color: EagleTokens.bad),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: EagleTokens.bad),
            ),
          ),
        ],
      ),
    );
  }
}
