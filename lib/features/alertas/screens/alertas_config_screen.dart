import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/alertas_repository.dart';

class AlertasConfigScreen extends ConsumerStatefulWidget {
  const AlertasConfigScreen({super.key});

  @override
  ConsumerState<AlertasConfigScreen> createState() => _AlertasConfigScreenState();
}

class _AlertasConfigScreenState extends ConsumerState<AlertasConfigScreen> {
  bool _loading = true;
  bool _salvando = false;
  String? _erro;

  int _diasSemTreino = 7;
  int _aderenciaMinima = 50;

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
      final repo = AlertasRepository(ref.read(apiClientProvider));
      final config = await repo.getConfiguracao();
      if (mounted) {
        setState(() {
          _diasSemTreino = config.diasSemTreino;
          _aderenciaMinima = config.aderenciaMinima;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      final repo = AlertasRepository(ref.read(apiClientProvider));
      await repo.atualizarConfiguracao(_diasSemTreino, _aderenciaMinima);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso!'),
            backgroundColor: EagleTokens.good,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Configurar Alertas'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: theme.colorScheme.error),
                        const SizedBox(height: 12),
                        Text('Erro ao carregar: $_erro',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _load,
                            child: const Text('Tentar novamente')),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_month_outlined,
                                      color: primary),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Dias sem treino',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$_diasSemTreino dias',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Alerta quando o aluno não treina por X dias consecutivos',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: EagleTokens.inkMute),
                              ),
                              Slider(
                                value: _diasSemTreino.toDouble(),
                                min: 1,
                                max: 30,
                                divisions: 29,
                                label: '$_diasSemTreino dias',
                                onChanged: (v) =>
                                    setState(() => _diasSemTreino = v.toInt()),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('1 dia',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: EagleTokens.inkMute)),
                                  Text('30 dias',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: EagleTokens.inkMute)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.trending_down_outlined,
                                      color: EagleTokens.warn),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Aderência mínima (%)',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: EagleTokens.warn
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$_aderenciaMinima%',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: EagleTokens.warn,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Alerta quando a taxa de aderência cair abaixo deste valor',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: EagleTokens.inkMute),
                              ),
                              Slider(
                                value: _aderenciaMinima.toDouble(),
                                min: 10,
                                max: 90,
                                divisions: 16,
                                label: '$_aderenciaMinima%',
                                activeColor: EagleTokens.warn,
                                onChanged: (v) =>
                                    setState(() => _aderenciaMinima = v.toInt()),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('10%',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: EagleTokens.inkMute)),
                                  Text('90%',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: EagleTokens.inkMute)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: _salvando ? null : _salvar,
                        child: _salvando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Salvar'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
