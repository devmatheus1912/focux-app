import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/fcm/fcm_service.dart';
import '../../../core/notificacoes/aviso_fim_descanso.dart';
import '../../../core/notificacoes/notificacoes_locais.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/notificacoes_preferencias_repository.dart';

/// Perfil > Notificações (SPEC-notificacoes, 20/11): estado do aparelho,
/// escolhas por tipo (o push desliga; o sino continua) e som do descanso.
/// Nos dois perfis.
class NotificacoesAjustesScreen extends ConsumerStatefulWidget {
  const NotificacoesAjustesScreen({super.key, this.repositorio});

  /// Trocável em teste.
  final NotificacoesPreferenciasRepository? repositorio;

  @override
  ConsumerState<NotificacoesAjustesScreen> createState() =>
      _NotificacoesAjustesScreenState();
}

class _NotificacoesAjustesScreenState
    extends ConsumerState<NotificacoesAjustesScreen>
    with WidgetsBindingObserver {
  late final NotificacoesPreferenciasRepository _repo =
      widget.repositorio ??
      NotificacoesPreferenciasRepository(ref.read(apiClientProvider).dio);

  List<PreferenciaDeNotificacao>? _itens;
  String? _erro;
  bool _negado = false;
  Set<String> _canaisDesligados = const {};
  bool _som = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _carregar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Voltou dos Ajustes do sistema: a permissão e os canais podem ter mudado.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_lerAparelho());
  }

  Future<void> _lerAparelho() async {
    final negado = await FcmService.permissaoNegada();
    final canais = await NotificacoesLocais.canaisDesligados();
    final som = await PreferenciasDoDescanso.somLigado();
    if (!mounted) return;
    setState(() {
      _negado = negado;
      _canaisDesligados = canais;
      _som = som;
    });
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    unawaited(_lerAparelho());
    try {
      final itens = await _repo.listar();
      if (mounted) setState(() => _itens = itens);
    } catch (e) {
      if (mounted) setState(() => _erro = friendlyError(e));
    }
  }

  Future<void> _mudar(PreferenciaDeNotificacao item, bool ligado) async {
    final antes = _itens;
    setState(() {
      _itens = [
        for (final i in antes ?? const <PreferenciaDeNotificacao>[])
          i.tipo == item.tipo ? i.comLigado(ligado) : i,
      ];
    });
    // O aviso do descanso é agendado no aparelho: vale a escolha local.
    if (item.tipo == 'DESCANSO') {
      await PreferenciasDoDescanso.definirAviso(ligado);
    }
    try {
      final itens = await _repo.salvar(item.comLigado(ligado));
      if (mounted) setState(() => _itens = itens);
    } catch (e) {
      if (!mounted) return;
      setState(() => _itens = antes);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return fxScreenA11yScope(
      label: 'Notificações',
      child: FxShellScaffold(
        comFundo: true,
        appBar: FxShellAppBar(
          title: 'Notificações',
          onBack: () => safePopOrGo(context, '/perfil'),
        ),
        body: SafeArea(
          child: FxContentWidthLimiter(child: _corpo(chrome, primary)),
        ),
      ),
    );
  }

  Widget _corpo(ShellPalette chrome, Color primary) {
    if (_erro != null && _itens == null) {
      return FxErrorState(
        chromeOnDark: chrome.isDark,
        primary: primary,
        message: _erro!,
        onRetry: _carregar,
        title: 'Não deu para abrir as notificações',
      );
    }
    final itens = _itens;
    if (itens == null) return const SkeletonList(count: 6);
    final temDescanso = itens.any((i) => i.tipo == 'DESCANSO');
    return RefreshIndicator(
      color: primary,
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          TokensStrip.s6,
        ),
        children: [
          FxSettingsGroup(
            header: 'Neste celular',
            children: [
              FxSettingsTile(
                icon: _negado ? FxIcons.alerta : FxIcons.notificacao,
                label:
                    _negado
                        ? 'Desativadas no celular'
                        : 'Notificações ativadas',
                subtitle:
                    _negado
                        ? 'Nada chega até você ativar nos ajustes do celular.'
                        : null,
                value: _negado ? 'Abrir ajustes' : '',
                mute: chrome.mute,
                line: chrome.line,
                showDivider: false,
                onTap: _negado ? abrirAjustesDeNotificacao : null,
              ),
            ],
          ),
          const SizedBox(height: FxSettingsLayout.groupGap),
          FxSettingsGroup(
            header: 'O que avisar',
            caption:
                'Desligar para o aviso no celular. O sino do app continua.',
            children: [
              for (final (i, item) in itens.indexed)
                _linha(item, chrome, ultima: i == itens.length - 1),
            ],
          ),
          if (temDescanso) ...[
            const SizedBox(height: FxSettingsLayout.groupGap),
            FxSettingsGroup(
              header: 'Descanso',
              children: [
                FxSettingsTile(
                  icon: FxIcons.audio,
                  label: 'Som no fim do descanso',
                  subtitle: 'Com o app aberto. Desligado, só vibra.',
                  value: '',
                  mute: chrome.mute,
                  line: chrome.line,
                  showDivider: false,
                  onTap: () => _mudarSom(!_som),
                  accessory: Switch.adaptive(value: _som, onChanged: _mudarSom),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _mudarSom(bool v) async {
    setState(() => _som = v);
    await PreferenciasDoDescanso.definirSom(v);
  }

  Widget _linha(
    PreferenciaDeNotificacao item,
    ShellPalette chrome, {
    required bool ultima,
  }) {
    final canalDesligado = _canaisDesligados.contains(item.canal);
    return FxSettingsTile(
      icon: iconeDoTipo(item.tipo),
      label: item.rotulo,
      subtitle:
          canalDesligado
              ? 'Desligado nos ajustes do celular'
              : item.descricao.isEmpty
              ? null
              : item.descricao,
      value: '',
      mute: chrome.mute,
      line: chrome.line,
      showDivider: !ultima,
      onTap:
          canalDesligado
              ? abrirAjustesDeNotificacao
              : () => _mudar(item, !item.ligado),
      accessory: Switch.adaptive(
        value: item.ligado && !canalDesligado,
        onChanged: canalDesligado ? null : (v) => _mudar(item, v),
      ),
    );
  }
}

IconData iconeDoTipo(String tipo) => switch (tipo) {
  'TREINO' => FxIcons.treino,
  'DESCANSO' => FxIcons.cronometro,
  'CHAT' => FxIcons.chat,
  'AGENDA' => FxIcons.calendario,
  'ALUNOS' => FxIcons.grupo,
  'FINANCEIRO' => FxIcons.pagamento,
  'VENDAS' => FxIcons.loja,
  'COMUNIDADE' => FxIcons.feed,
  'NOVIDADES' => FxIcons.atualizar,
  'OFERTAS' => FxIcons.presente,
  _ => FxIcons.notificacao,
};
