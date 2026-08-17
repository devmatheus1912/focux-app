import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/upsell_repository.dart';

final upsellRepositoryProvider = Provider(
  (ref) => UpsellRepository(ref.read(apiClientProvider)),
);

class OfertasUpsellScreen extends ConsumerStatefulWidget {
  const OfertasUpsellScreen({super.key});

  @override
  ConsumerState<OfertasUpsellScreen> createState() =>
      _OfertasUpsellScreenState();
}

class _OfertasUpsellScreenState extends ConsumerState<OfertasUpsellScreen> {
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _valor = TextEditingController();
  List<OfertaUpsell> _ofertas = [];
  bool _loading = true;
  bool _saving = false;
  String? _erro;
  String _tipoGatilho = 'MANUAL';

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _valor.dispose();
    super.dispose();
  }

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
      final list = await ref.read(upsellRepositoryProvider).listarOfertas();
      if (mounted) {
        setState(() {
          _ofertas = list;
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
    final valor = double.tryParse(_valor.text.replaceAll(',', '.'));
    if (_titulo.text.trim().isEmpty || valor == null || valor <= 0) {
      FeedbackHelper.showError(context, 'Preencha título e valor válido');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(upsellRepositoryProvider)
          .criar(
            titulo: _titulo.text.trim(),
            descricao: _descricao.text.trim(),
            valor: valor,
            tipoGatilho: _tipoGatilho,
          );
      _titulo.clear();
      _descricao.clear();
      _valor.clear();
      await _load();
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Oferta criada');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(
          context,
          friendlyError(e, fallback: 'Erro ao criar oferta'),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Ofertas para alunos',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(title: 'Ofertas para alunos'),
        body:
            _loading
                ? const SkeletonList(count: 5)
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: _erro!,
                  onRetry: _load,
                  title: 'Não carregamos as ofertas',
                )
                : ListView(
                  padding: const EdgeInsets.all(TokensStrip.s4),
                  children: [
                    Text(
                      'Ofertas disparam automaticamente quando o aluno conclui uma trilha.',
                      style: TextStyle(color: chrome.mute, height: 1.4),
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    TextField(
                      controller: _titulo,
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                    const SizedBox(height: TokensStrip.s2),
                    TextField(
                      controller: _descricao,
                      decoration: const InputDecoration(labelText: 'Descrição'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: TokensStrip.s2),
                    TextField(
                      controller: _valor,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Valor (R\$)',
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s2),
                    DropdownButtonFormField<String>(
                      initialValue: _tipoGatilho,
                      decoration: const InputDecoration(labelText: 'Gatilho'),
                      items: const [
                        DropdownMenuItem(
                          value: 'MANUAL',
                          child: Text('Manual'),
                        ),
                        DropdownMenuItem(
                          value: 'CHECKIN',
                          child: Text('Check-in'),
                        ),
                        DropdownMenuItem(
                          value: 'TRILHA',
                          child: Text('Trilha'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _tipoGatilho = v);
                      },
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    FilledButton(
                      onPressed: _saving ? null : _criar,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: Text(_saving ? 'Salvando…' : 'Criar oferta'),
                    ),
                    const SizedBox(height: TokensStrip.s5),
                    Text(
                      'Ativas (${_ofertas.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: chrome.ink,
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s2),
                    if (_ofertas.isEmpty)
                      const FxEmptyState(
                        icon: 'spark',
                        title: 'Nenhuma oferta ativa',
                        subtitle:
                            'Crie a primeira oferta acima. Ela aparece para o aluno no gatilho escolhido.',
                      )
                    else
                      ..._ofertas.map(
                        (o) => FxSatelliteListTile(
                          title: o.titulo,
                          subtitle: Text(
                            'R\$ ${o.valor.toStringAsFixed(2)} · ${o.tipoGatilho}',
                          ),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}
