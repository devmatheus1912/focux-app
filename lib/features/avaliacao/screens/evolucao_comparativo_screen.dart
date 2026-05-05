import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/fx_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/avaliacao_repository.dart';
import '../../evolucao/data/evolucao_repository.dart';

String _fmtData(String? iso) {
  if (iso == null || iso.isEmpty) return '—';
  try {
    return fxDateShort(DateTime.parse(iso));
  } catch (e) {
    debugPrint('[Focux] Error: $e');
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
      setState(() {
        _comparativo = c;
        _loading = false;
      });
    } catch (e) {
      final msg = e.toString();
      final eh404 = msg.contains('404') || msg.contains('Not Found');
      setState(() {
        _erro =
            eh404
                ? 'Nenhuma avaliação encontrada para comparativo.'
                : 'Erro ao carregar comparativo: $msg';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? EagleTokens.darkBg
              : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Evolução de ${widget.alunoNome}'),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _erro != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 48,
                        color: EagleTokens.inkMute,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _erro!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: EagleTokens.inkMute),
                      ),
                      const SizedBox(height: 16),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho com datas
          Card(
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
                            fontWeight: FontWeight.bold,
                            color: EagleTokens.inkMute,
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
                  const Icon(Icons.arrow_forward, color: EagleTokens.inkMute),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Atual',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: EagleTokens.inkMute,
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
          const SizedBox(height: 16),

          // Tabela de comparativo
          Card(
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
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.circle, size: 10, color: EagleTokens.good),
              SizedBox(width: 4),
              Text(
                'Melhora',
                style: TextStyle(fontSize: 12, color: EagleTokens.inkMute),
              ),
              SizedBox(width: 12),
              Icon(Icons.circle, size: 10, color: EagleTokens.bad),
              SizedBox(width: 4),
              Text(
                'Piora',
                style: TextStyle(fontSize: 12, color: EagleTokens.inkMute),
              ),
              SizedBox(width: 12),
              Icon(Icons.circle, size: 10, color: EagleTokens.inkMute),
              SizedBox(width: 4),
              Text(
                'Sem alteração',
                style: TextStyle(fontSize: 12, color: EagleTokens.inkMute),
              ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final repo = EvolucaoRepository(ref.read(apiClientProvider));
                await repo.compartilharEvolucao(widget.alunoId);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Evolução compartilhada via chat com sucesso!',
                      ),
                    ),
                  );
                }
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Erro: $e')));
              }
            },
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar com o aluno via Chat'),
          ),
        ],
      ),
    );
  }

  Widget _headerRow() {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 13,
      color: EagleTokens.inkMute,
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
    Color deltaColor = EagleTokens.inkMute;
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
