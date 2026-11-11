import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/theme/fx_icons.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/winback_repository.dart';
import '../utils/winback_display.dart';

/// Configuração do aviso para quem parou (lida pela linha de Automações).
final retomadaConfigProvider = FutureProvider.autoDispose<RetomadaConfig>((
  ref,
) {
  return WinbackRepository(ref.read(apiClientProvider)).config();
});

/// Liga ou desliga o aviso (desligar pede confirmação). Devolve se mudou.
Future<bool> alternarRetomada(
  BuildContext context,
  WidgetRef ref,
  RetomadaConfig atual,
) async {
  if (atual.ativo) {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Desligar o aviso?',
      message:
          'Os alunos parados deixam de receber o aviso. Você pode ligar de novo quando quiser.',
      confirmLabel: 'Desligar',
    );
    if (!ok) return false;
  }
  await WinbackRepository(ref.read(apiClientProvider)).salvarConfig(
    ativo: !atual.ativo,
    mensagem30: atual.mensagem30,
    mensagem60: atual.mensagem60,
  );
  ref.invalidate(retomadaConfigProvider);
  return true;
}

/// Folha do item fixo de Automações: o que o aluno recebe, editar e os envios.
Future<void> showRetomadaFolha(BuildContext context) {
  return showFxHomeSheet<void>(context, builder: (_) => const _RetomadaFolha());
}

class _RetomadaFolha extends ConsumerStatefulWidget {
  const _RetomadaFolha();

  @override
  ConsumerState<_RetomadaFolha> createState() => _RetomadaFolhaState();
}

class _RetomadaFolhaState extends ConsumerState<_RetomadaFolha> {
  final _envios = <WinbackLogEntry>[];
  var _pagina = 0;
  var _temMais = false;
  var _carregando = true;
  String? _erro;

  WinbackRepository get _repo => WinbackRepository(ref.read(apiClientProvider));

  @override
  void initState() {
    super.initState();
    _carregarEnvios();
  }

  Future<void> _carregarEnvios() async {
    try {
      final pagina = await _repo.log(page: _pagina);
      if (!mounted) return;
      setState(() {
        _envios.addAll(pagina.itens);
        _temMais = pagina.hasNext;
        _pagina += 1;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _carregando = false;
      });
    }
  }

  Future<void> _editar(RetomadaConfig config) async {
    final c30 = TextEditingController(text: config.texto30);
    final c60 = TextEditingController(text: config.texto60);
    var voltarAoPadrao = false;
    try {
      final ok = await showFxFormSheet(
        context,
        title: 'Texto do aviso',
        subtitle: 'Use {nome} para o primeiro nome do aluno.',
        confirmLabel: 'Salvar',
        aoConfirmar: () async {
          try {
            await _repo.salvarConfig(
              ativo: config.ativo,
              mensagem30:
                  voltarAoPadrao ? null : _proprio(c30, config.padrao30),
              mensagem60:
                  voltarAoPadrao ? null : _proprio(c60, config.padrao60),
            );
            return null;
          } catch (e) {
            return friendlyError(e);
          }
        },
        child: StatefulBuilder(
          builder:
              (context, setLocal) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AlunoInsetFormField(
                    controller: c30,
                    label: '30 dias sem treino',
                    maxLines: 4,
                    rotuloVisivel: true,
                    mostrarOpcional: false,
                    showDivider: false,
                  ),
                  AlunoInsetFormField(
                    controller: c60,
                    label: '60 dias sem treino',
                    maxLines: 4,
                    rotuloVisivel: true,
                    mostrarOpcional: false,
                    showDivider: false,
                  ),
                  if (config.textoProprio)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FxTonalButton(
                        label: 'Voltar ao texto do Focux',
                        compact: true,
                        onPressed: () {
                          voltarAoPadrao = true;
                          c30.text = config.padrao30;
                          c60.text = config.padrao60;
                          setLocal(() {});
                        },
                      ),
                    ),
                ],
              ),
        ),
      );
      if (ok) ref.invalidate(retomadaConfigProvider);
    } finally {
      c30.dispose();
      c60.dispose();
    }
  }

  /// Igual ao padrão = sem texto próprio (fica acompanhando o do Focux).
  static String? _proprio(TextEditingController c, String padrao) {
    final t = c.text.trim();
    return t.isEmpty || t == padrao ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final configAsync = ref.watch(retomadaConfigProvider);
    final config = configAsync.value;
    return FxHomeSheetSurface(
      isDark: chrome.isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      expand: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: chrome.isDark),
          const SizedBox(height: TokensStrip.s4),
          FxHomeSheetHeader(
            isDark: chrome.isDark,
            title: retomadaTitulo,
            subtitle: retomadaSubtituloDaLinha(config),
          ),
          const SizedBox(height: TokensStrip.s3),
          Expanded(
            child: ListView(
              children: [
                if (config != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          config.ativo ? 'Ligado' : 'Desligado',
                          style: FxSettingsLayout.rowLabel(color: chrome.ink),
                        ),
                      ),
                      Switch.adaptive(
                        value: config.ativo,
                        onChanged: (_) async {
                          try {
                            await alternarRetomada(context, ref, config);
                          } catch (e) {
                            if (context.mounted) {
                              FeedbackHelper.showError(
                                context,
                                friendlyError(e),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s3),
                  Text(
                    'O que o aluno recebe',
                    style: FxSettingsLayout.sectionHeader(color: chrome.mute),
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  _Mensagem(
                    rotulo: '30 dias sem treino',
                    texto: config.texto30,
                  ),
                  const SizedBox(height: TokensStrip.s2),
                  _Mensagem(
                    rotulo: '60 dias sem treino',
                    texto: config.texto60,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FxTonalButton(
                      label: 'Editar',
                      icon: FxIcons.editar,
                      compact: true,
                      onPressed: () => _editar(config),
                    ),
                  ),
                  const SizedBox(height: TokensStrip.s4),
                ],
                Text(
                  'Envios',
                  style: FxSettingsLayout.sectionHeader(color: chrome.mute),
                ),
                const SizedBox(height: TokensStrip.s2),
                if (_carregando)
                  const Padding(
                    padding: EdgeInsets.all(TokensStrip.s3),
                    child: Center(child: FxLoading()),
                  )
                else if (_erro != null)
                  Text(
                    _erro!,
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  )
                else if (_envios.isEmpty)
                  Text(
                    retomadaVazio,
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  )
                else ...[
                  for (final e in _envios)
                    FxSatelliteListTile(
                      titleCase: false,
                      title: winbackAlunoLabel(e.alunoNome),
                      subtitle: Text(
                        winbackSubtitle(
                          tipo: e.tipo,
                          mensagem: '',
                          status: e.status,
                        ),
                      ),
                      trailing: Text(
                        winbackWhenLabel(e.enviadoEm),
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                    ),
                  if (_temMais)
                    FxSatelliteListTile(
                      title: 'Carregar mais',
                      onTap: _carregarEnvios,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  const _Mensagem({required this.rotulo, required this.texto});

  final String rotulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: FocuxHubTypography.chip(chrome.mute)),
        const SizedBox(height: 2),
        Text(texto, style: FocuxHubTypography.body(color: chrome.ink)),
      ],
    );
  }
}
