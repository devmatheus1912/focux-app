import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/depoimento_repository.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

class DepoimentosPersonalScreen extends ConsumerStatefulWidget {
  const DepoimentosPersonalScreen({super.key});
  @override
  ConsumerState<DepoimentosPersonalScreen> createState() => _State();
}

class _State extends ConsumerState<DepoimentosPersonalScreen> {
  List<DepoimentoModel>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
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
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _action(int id, bool aprovado) async {
    try {
      await DepoimentoRepository(
        ref.read(apiClientProvider),
      ).aprovar(id, aprovado: aprovado);
      await _load();
    } catch (e) {
      if (mounted) FeedbackHelper.showSuccess(context, 'Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return FxShellScaffold(
      useMesh: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Depoimentos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body:
          _loading
              ? const FxLoading()
              : (_items == null || _items!.isEmpty)
              ? Center(
                child: Text(
                  'Nenhum depoimento ainda.',
                  style: TextStyle(
                    color:
                        isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
                  ),
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(TokensStrip.s4),
                itemCount: _items!.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final d = _items![i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? EagleTokens.darkCard : TokensStrip.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? EagleTokens.darkLine : TokensStrip.borderDefault,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: primary.withValues(alpha: 0.12),
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
                                      color:
                                          isDark
                                              ? EagleTokens.darkInk
                                              : TokensStrip.textPrimary,
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
                                        color: const Color(0xFFF59E0B),
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
                                          : const Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          d.texto,
                          style: TextStyle(
                            color:
                                isDark
                                    ? EagleTokens.darkInkMute
                                    : TokensStrip.textSecondary,
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
    );
  }
}
