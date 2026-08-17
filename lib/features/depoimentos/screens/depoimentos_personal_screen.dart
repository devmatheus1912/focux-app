import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/depoimento_repository.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/skeleton_loader.dart';

class DepoimentosPersonalScreen extends ConsumerStatefulWidget {
  const DepoimentosPersonalScreen({super.key});
  @override
  ConsumerState<DepoimentosPersonalScreen> createState() => _State();
}

class _State extends ConsumerState<DepoimentosPersonalScreen> {
  List<DepoimentoModel>? _items;
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
          await DepoimentoRepository(
            ref.read(apiClientProvider),
          ).listarParaPersonal();
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _action(int id, bool aprovado) async {
    try {
      await DepoimentoRepository(
        ref.read(apiClientProvider),
      ).aprovar(id, aprovado: aprovado);
      await _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return fxScreenA11yScope(
      label: 'Depoimentos',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Depoimentos',
          subtitle: 'Prova social dos seus alunos',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar depoimentos',
              onPressed: _load,
            ),
          ],
        ),
        body:
            _loading
                ? const SkeletonList(count: 5)
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: _erro!,
                  onRetry: _load,
                  title: 'Não conseguimos carregar os depoimentos',
                )
                : (_items == null || _items!.isEmpty)
                ? const FxEmptyState(
                  icon: 'star',
                  title: 'Nenhum depoimento ainda',
                  subtitle:
                      'Quando seus alunos enviarem depoimentos, eles aparecem aqui para aprovação.',
                )
                : ListView.separated(
                  padding: const EdgeInsets.all(TokensStrip.s4),
                  itemCount: _items!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final d = _items![i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: chrome.listCard(primary: primary),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: primary.withValues(
                                  alpha: 0.12,
                                ),
                                backgroundImage:
                                    d.fotoAluno != null
                                        ? NetworkImage(d.fotoAluno!)
                                        : null,
                                child:
                                    d.fotoAluno == null
                                        ? Text(
                                          d.nomeAluno.isNotEmpty
                                              ? d.nomeAluno[0].toUpperCase()
                                              : 'A',
                                          style: TextStyle(
                                            color: primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                        : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.nomeAluno,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: chrome.ink,
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (si) => Icon(
                                          si < d.nota
                                              ? Icons.star
                                              : Icons.star_border,
                                          size: 13,
                                          color: EagleTokens.goldStar,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      d.aprovado
                                          ? EagleTokens.good.withValues(
                                            alpha: 0.15,
                                          )
                                          : const Color(
                                            0xFFF59E0B,
                                          ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  d.aprovado ? 'Aprovado' : 'Pendente',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        d.aprovado
                                            ? EagleTokens.good
                                            : EagleTokens.goldStar,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            d.texto,
                            style: TextStyle(
                              color: chrome.mute,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (!d.aprovado)
                                Expanded(
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.check, size: 16),
                                    label: const Text('Aprovar'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: EagleTokens.good,
                                    ),
                                    onPressed: () => _action(d.id, true),
                                  ),
                                ),
                              if (!d.aprovado) const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: Icon(
                                    d.aprovado ? Icons.close : Icons.close,
                                    size: 16,
                                  ),
                                  label: Text(
                                    d.aprovado ? 'Remover' : 'Rejeitar',
                                  ),
                                  onPressed: () => _action(d.id, false),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
