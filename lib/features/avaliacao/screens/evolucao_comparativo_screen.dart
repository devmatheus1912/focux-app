import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/router/safe_navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/avaliacao_repository.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

String _fmtData(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    return fxDateShort(DateTime.parse(iso));
  } catch (_) {
    return iso;
  }
}

String _fmtNum(double? v, {int decimais = 1}) {
  if (v == null) return '—';
  return v.toStringAsFixed(decimais);
}

class EvolucaoComparativoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const EvolucaoComparativoScreen({
    super.key,
    required this.alunoId,
    this.alunoNome = 'Aluno',
  });
  @override
  ConsumerState<EvolucaoComparativoScreen> createState() =>
      _EvolucaoComparativoScreenState();
}

class _EvolucaoComparativoScreenState
    extends ConsumerState<EvolucaoComparativoScreen> {
  ComparativoEvolucao? _comparativo;
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
      final c = await AvaliacaoRepository(
        ref.read(apiClientProvider),
      ).comparativo(widget.alunoId);
      if (!mounted) return;
      setState(() {
        _comparativo = c;
        _loading = false;
      });
    } catch (e) {
      final msg = friendlyError(e);
      final eh404 = msg.contains('404') || msg.contains('Not Found');
      if (!mounted) return;
      setState(() {
        _erro =
            eh404
                ? 'Nenhuma avaliação encontrada para comparativo.'
                : msg;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Evolução de ${widget.alunoNome}',
        subtitle: 'Comparativo de avaliações físicas',
        onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
      ),
      body:
          _loading
              ? const Center(child: FxLoading())
              : _erro != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(TokensStrip.s5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 48,
                        color: TokensStrip.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _erro!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: TokensStrip.textSecondary),
                      ),
                      const SizedBox(height: TokensStrip.s4),
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
              : _buildConteudo(_comparativo!),
    );
  }

  Widget _buildConteudo(ComparativoEvolucao c) {
    final primeira = c.primeira;
    final atual = c.atual;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TokensStrip.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho com datas
          Container(
            decoration: fxListCardDecoration(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Primeira',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: TokensStrip.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fmtData(primeira.avaliadoEm),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: TokensStrip.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Atual',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: TokensStrip.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _fmtData(atual.avaliadoEm),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: TokensStrip.s4),

          // Tabela de comparativo
          Container(
            decoration: fxListCardDecoration(context),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _headerRow(),
                const Divider(height: 1),
                _metricaRow(
                  label: 'Peso',
                  unidade: 'kg',
                  vPrimeira: primeira.pesoKg,
                  vAtual: atual.pesoKg,
                  menorEMelhor: true,
                ),
                _metricaRow(
                  label: 'IMC',
                  unidade: '',
                  vPrimeira: primeira.imc,
                  vAtual: atual.imc,
                  menorEMelhor: true,
                ),
                _metricaRow(
                  label: '% Gordura',
                  unidade: '%',
                  vPrimeira: primeira.percGordura,
                  vAtual: atual.percGordura,
                  menorEMelhor: true,
                ),
                _metricaRow(
                  label: 'Massa Muscular',
                  unidade: 'kg',
                  vPrimeira: primeira.massaMuscular,
                  vAtual: atual.massaMuscular,
                  menorEMelhor: false,
                ),
                _metricaRow(
                  label: 'Circ. Cintura',
                  unidade: 'cm',
                  vPrimeira: primeira.circCintura,
                  vAtual: atual.circCintura,
                  menorEMelhor: true,
                ),
                _metricaRow(
                  label: 'Circ. Quadril',
                  unidade: 'cm',
                  vPrimeira: primeira.circQuadril,
                  vAtual: atual.circQuadril,
                  menorEMelhor: true,
                ),
                _metricaRow(
                  label: 'Circ. Braço',
                  unidade: 'cm',
                  vPrimeira: primeira.circBraco,
                  vAtual: atual.circBraco,
                  menorEMelhor: false,
                ),
                _metricaRow(
                  label: 'Circ. Coxa',
                  unidade: 'cm',
                  vPrimeira: primeira.circCoxa,
                  vAtual: atual.circCoxa,
                  menorEMelhor: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
          const Row(
            children: [
              Icon(Icons.circle, size: 10, color: EagleTokens.good),
              SizedBox(width: 4),
              Text(
                'Melhora',
                style: TextStyle(fontSize: 12, color: TokensStrip.textSecondary),
              ),
              SizedBox(width: 12),
              Icon(Icons.circle, size: 10, color: EagleTokens.bad),
              SizedBox(width: 4),
              Text(
                'Piora',
                style: TextStyle(fontSize: 12, color: TokensStrip.textSecondary),
              ),
              SizedBox(width: 12),
              Icon(Icons.circle, size: 10, color: TokensStrip.textSecondary),
              SizedBox(width: 4),
              Text(
                'Sem alteração',
                style: TextStyle(fontSize: 12, color: TokensStrip.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FxLiquidPrimaryButton(
              label: 'Compartilhar com o aluno via Chat',
              icon: Icons.share_rounded,
              onPressed: () async {
                try {
                  final repo = EvolucaoRepository(ref.read(apiClientProvider));
                  await repo.compartilharEvolucao(widget.alunoId);
                  if (mounted) {
                    FeedbackHelper.showSuccess(
                      context,
                      'Evolução compartilhada via chat com sucesso!',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    FeedbackHelper.showError(context, friendlyError(e));
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow() {
    const style = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: TokensStrip.textSecondary,
    );
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Métrica', style: style)),
          Expanded(
            flex: 2,
            child: Text('Primeira', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('Atual', style: style, textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text('Delta', style: style, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _metricaRow({
    required String label,
    required String unidade,
    required double? vPrimeira,
    required double? vAtual,
    required bool menorEMelhor,
  }) {
    Color deltaColor = TokensStrip.textSecondary;
    String deltaText = '—';
    IconData? deltaIcon;

    if (vPrimeira != null && vAtual != null) {
      final diff = vAtual - vPrimeira;
      deltaText = (diff >= 0 ? '+' : '') + diff.toStringAsFixed(1);
      if (diff != 0) {
        final melhorou = menorEMelhor ? diff < 0 : diff > 0;
        deltaColor = melhorou ? EagleTokens.good : EagleTokens.bad;
        deltaIcon = melhorou ? Icons.trending_up : Icons.trending_down;
      }
    }

    final unidStr = unidade.isNotEmpty ? ' $unidade' : '';

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x1A000000))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              vPrimeira != null ? '${_fmtNum(vPrimeira)}$unidStr' : '—',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              vAtual != null ? '${_fmtNum(vAtual)}$unidStr' : '—',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (deltaIcon != null) ...[
                  Icon(deltaIcon, size: 14, color: deltaColor),
                  const SizedBox(width: 2),
                ],
                Text(
                  deltaText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: deltaColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
