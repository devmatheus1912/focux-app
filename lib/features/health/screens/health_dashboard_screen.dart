import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/health/health_service.dart';
import '../../../core/health/home_widget_service.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_premium_entrance.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/health_repository.dart';
import '../utils/health_dashboard_display.dart';
import '../utils/health_plausibilidade.dart';
import '../utils/saude_meta_passos.dart';
import '../widgets/prontidao_card.dart';
import '../widgets/saude_cards.dart';
import '../widgets/saude_estados.dart';

typedef HealthDashboardCheckAuthorization = Future<bool> Function();
typedef HealthDashboardLoadTodaySummary = Future<HealthSummary> Function();
typedef HealthDashboardSyncToday =
    Future<RecoverySnapshot> Function(HealthSummary summary);
typedef HealthDashboardUpdateHomeWidget =
    Future<void> Function({
      required int recoveryScore,
      required String recoveryLabel,
      required String recoveryHint,
      required int steps,
    });
typedef HealthDashboardClearHomeWidgetScore =
    Future<void> Function({required int? steps});
typedef HealthDashboardLoadHistorico = Future<List<RecoveryDia>> Function();
typedef HealthDashboardLoadCompartilhamento = Future<bool> Function();
typedef HealthDashboardSetCompartilhamento = Future<bool> Function(bool ativo);

/// Tela Saúde do aluno: prontidão do dia, métricas, tendência e conexão.
class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({
    super.key,
    this.checkAuthorization,
    this.loadTodaySummary,
    this.syncToday,
    this.updateHomeWidgetRecovery,
    this.clearHomeWidgetRecoveryScore,
    this.loadHistorico,
    this.loadCompartilhamento,
    this.setCompartilhamento,
  });

  final HealthDashboardCheckAuthorization? checkAuthorization;
  final HealthDashboardLoadTodaySummary? loadTodaySummary;
  final HealthDashboardSyncToday? syncToday;
  final HealthDashboardUpdateHomeWidget? updateHomeWidgetRecovery;
  final HealthDashboardClearHomeWidgetScore? clearHomeWidgetRecoveryScore;
  final HealthDashboardLoadHistorico? loadHistorico;
  final HealthDashboardLoadCompartilhamento? loadCompartilhamento;
  final HealthDashboardSetCompartilhamento? setCompartilhamento;

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  static const _avisoVistoKey = 'saude_aviso_compartilhamento_visto';
  static const _escolhaFeitaKey = 'saude_escolha_compartilhamento_feita';

  bool _authorized = false;
  bool _loading = true;
  bool _refreshing = false;
  String? _erro;
  String? _syncSoftError;
  HealthSummary? _summary;
  RecoverySnapshot? _recovery;
  DateTime? _fetchedAt;
  List<RecoveryDia> _historico = const [];
  bool? _compartilhando;
  int _metaPassos = SaudeMetaPassos.padrao;
  bool _mostrarAvisoCompartilhando = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  HealthRepository get _repo => HealthRepository.fromClient(ApiClient());

  Future<bool> _resolveCheckAuthorization() =>
      widget.checkAuthorization?.call() ?? HealthService.isAuthorized();

  Future<HealthSummary> _resolveLoadTodaySummary() =>
      widget.loadTodaySummary?.call() ?? HealthService.getTodaySummary();

  Future<RecoverySnapshot> _resolveSyncToday(HealthSummary summary) =>
      widget.syncToday?.call(summary) ?? _repo.syncToday(summary);

  Future<List<RecoveryDia>> _resolveHistorico() =>
      widget.loadHistorico?.call() ?? _repo.historicoDeProntidao();

  Future<bool> _resolveCompartilhamento() =>
      widget.loadCompartilhamento?.call() ?? _repo.compartilhamento();

  Future<bool> _resolveSetCompartilhamento(bool ativo) =>
      widget.setCompartilhamento?.call(ativo) ??
      _repo.definirCompartilhamento(ativo);

  Future<void> _resolveUpdateHomeWidgetRecovery({
    required int recoveryScore,
    required String recoveryLabel,
    required String recoveryHint,
    required int steps,
  }) =>
      widget.updateHomeWidgetRecovery?.call(
        recoveryScore: recoveryScore,
        recoveryLabel: recoveryLabel,
        recoveryHint: recoveryHint,
        steps: steps,
      ) ??
      HomeWidgetService.updateRecovery(
        recoveryScore: recoveryScore,
        recoveryLabel: recoveryLabel,
        recoveryHint: recoveryHint,
        steps: steps,
      );

  Future<void> _resolveClearHomeWidgetRecoveryScore({required int? steps}) =>
      widget.clearHomeWidgetRecoveryScore?.call(steps: steps) ??
      HomeWidgetService.clearRecoveryScore(steps: steps);

  Future<void> _checkAuth() async {
    try {
      final auth = await _resolveCheckAuthorization();
      if (auth) {
        // Só no app de verdade (os testes injetam a autorização).
        if (widget.checkAuthorization == null) await HealthService.pedirTiposNovosSeMudou();
        await _loadData();
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
            _erro = null;
            _syncSoftError = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
          _syncSoftError = null;
        });
      }
    }
  }

  Future<void> _requestAccess() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final granted = await HealthService.requestAuthorization();
      if (granted) {
        await _loadData();
        await _escolherCompartilhamentoSePreciso();
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(
            e,
            fallback: 'Saúde não disponível neste dispositivo.',
          );
        });
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final summary = await _resolveLoadTodaySummary();
      RecoverySnapshot? synced;
      String? soft;
      try {
        synced = await _resolveSyncToday(summary);
        final score = synced.recoveryScore;
        if (score != null) {
          await _resolveUpdateHomeWidgetRecovery(
            recoveryScore: score,
            recoveryLabel: synced.recoveryLabel,
            recoveryHint: synced.recoveryHint,
            steps: synced.steps,
          );
        } else {
          // Não deixa a nota de ontem no widget; o nativo mostra "--".
          await _resolveClearHomeWidgetRecoveryScore(steps: synced.steps);
        }
      } catch (e) {
        soft = saudeSyncSoftError(friendlyError(e));
      }
      final extras = await _carregarExtras();
      if (mounted) {
        setState(() {
          _authorized = true;
          _summary = summary;
          _recovery = recoveryAfterSyncAttempt(
            syncedFromServer: synced,
            previousSnapshot: _recovery,
          );
          _loading = false;
          _erro = null;
          _syncSoftError = soft;
          _fetchedAt = DateTime.now();
          _historico = extras.historico;
          _compartilhando = extras.compartilhando;
          _metaPassos = extras.meta;
          _mostrarAvisoCompartilhando = extras.avisar;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          // Só troca a tela por erro quando ainda não há dados em tela.
          if (_summary == null) {
            _erro = friendlyError(e);
            _syncSoftError = null;
          } else {
            _syncSoftError = friendlyError(e, fallback: saudeSyncSoftError());
          }
        });
      }
    }
  }

  /// Histórico, compartilhamento e meta: melhor esforço, nunca derrubam a tela.
  Future<({List<RecoveryDia> historico, bool? compartilhando, int meta, bool avisar})>
  _carregarExtras() async {
    var historico = _historico;
    bool? compartilhando = _compartilhando;
    try {
      historico = await _resolveHistorico();
    } catch (_) {}
    try {
      compartilhando = await _resolveCompartilhamento();
    } catch (_) {}
    final meta = await SaudeMetaPassos.ler();
    var avisar = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Quem já compartilhava antes do interruptor é avisado uma vez.
      avisar =
          compartilhando == true &&
          !(prefs.getBool(_avisoVistoKey) ?? false) &&
          !(prefs.getBool(_escolhaFeitaKey) ?? false);
    } catch (_) {}
    return (
      historico: historico,
      compartilhando: compartilhando,
      meta: meta,
      avisar: avisar,
    );
  }

  Future<void> _dispensarAviso() async {
    setState(() => _mostrarAvisoCompartilhando = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_avisoVistoKey, true);
  }

  /// Primeira conexão: duas opções iguais, nenhuma pré-marcada.
  Future<void> _escolherCompartilhamentoSePreciso() async {
    if (!mounted || !_authorized) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_escolhaFeitaKey) ?? false) return;
    if (!mounted) return;
    final escolha = await showFxGroupedActionSheet<bool>(
      context,
      titulo: 'Quem vê seus dados de saúde?',
      subtitulo:
          'Você pode mudar isso depois, na seção Conexão desta tela.',
      icone: Icons.favorite_rounded,
      grupos: [
        FxActionGroup<bool>(null, [
          FxActionItem(
            valor: true,
            rotulo: 'Compartilhar com meu personal',
            descricao: 'Ele vê sua nota de prontidão e os dados do dia.',
            icone: Icons.group_outlined,
          ),
          FxActionItem(
            valor: false,
            rotulo: 'Só eu vejo',
            descricao: 'Seu personal não recebe nada de saúde.',
            icone: Icons.lock_outline_rounded,
          ),
        ]),
      ],
    );
    if (escolha == null) return;
    await prefs.setBool(_escolhaFeitaKey, true);
    await _alterarCompartilhamento(escolha);
  }

  Future<void> _alterarCompartilhamento(bool ativo) async {
    final anterior = _compartilhando;
    setState(() {
      _compartilhando = ativo;
      _mostrarAvisoCompartilhando = false;
    });
    try {
      final salvo = await _resolveSetCompartilhamento(ativo);
      if (mounted) setState(() => _compartilhando = salvo);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_escolhaFeitaKey, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _compartilhando = anterior);
      FeedbackHelper.showApiFailure(context, e);
    }
  }

  Future<void> _refreshDashboard() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    AnalyticsService.instance.track(
      ProductEvents.homeRefreshed,
      props: {'surface': 'saude'},
    );
    try {
      await _loadData();
      if (!mounted) return;
      if (_syncSoftError != null) {
        FeedbackHelper.showWarn(context, _syncSoftError!);
        return;
      }
      if (_summary != null) {
        FeedbackHelper.showSuccess(context, 'Prontidão atualizada');
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// HealthKit não pergunta de novo o que já foi respondido: no iOS só resta
  /// mandar o aluno aos Ajustes. Health Connect reabre o pedido.
  Future<void> _comoLiberar() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      await _requestAccess();
      return;
    }
    await showFxHelpSheet(
      context,
      title: saudeSemScoreAcao,
      subtitle: saudeLiberarIosSubtitulo,
      tips: [
        for (final passo in saudeLiberarIosPassos) FxHelpTip(passo.$1, passo.$2),
      ],
    );
  }

  Future<void> _desconectar() async {
    final ok = await showFxConfirmSheet(
      context,
      title: saudeDesconectarConfirmTitle(),
      message: saudeDesconectarConfirmMessage(),
      confirmLabel: saudeDesconectarLabel(),
      destructive: true,
    );
    if (!ok || !mounted) return;
    await HealthService.revokeAccess();
    if (!mounted) return;
    setState(() {
      _authorized = false;
      _summary = null;
      _recovery = null;
      _fetchedAt = null;
      _syncSoftError = null;
      _erro = null;
      _historico = const [];
    });
  }

  /// "FC em repouso × FC média do dia": o número que mais confunde.
  Future<void> _explicarFc({required double fcRepouso, required double media}) {
    return showFxHelpSheet(
      context,
      title: 'Frequência cardíaca',
      subtitle: 'Dois números diferentes, para coisas diferentes.',
      tips: [
        FxHelpTip(
          fcRepouso > 0 ? 'Em repouso: ${fcRepouso.round()} bpm' : 'Em repouso: sem leitura hoje',
          'Medida parado, em geral ao acordar. Entra na sua nota de prontidão e é comparada com a sua própria média.',
        ),
        FxHelpTip(
          media > 0 ? 'Média do dia: ${media.round()} bpm' : 'Média do dia: sem leitura',
          'Todas as leituras de hoje, inclusive treino e caminhada. Sobe quando você se mexe; não entra na nota.',
        ),
      ],
    );
  }

  Future<void> _gerenciarConexao() async {
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: rotuloPlataformaSaude(),
      subtitulo: 'Conexão com os seus dados de saúde',
      icone: Icons.favorite_rounded,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'desconectar',
            rotulo: saudeDesconectarLabel(),
            descricao: saudeDesconectarConfirmMessage(),
            icone: Icons.link_off_rounded,
            perigo: true,
          ),
        ]),
      ],
    );
    if (escolha == 'desconectar' && mounted) await _desconectar();
  }

  Future<void> _editarMeta() async {
    final nova = await showSaudeMetaPassosSheet(context, atual: _metaPassos);
    if (nova == null) return;
    await SaudeMetaPassos.salvar(nova);
    if (mounted) setState(() => _metaPassos = SaudeMetaPassos.ajustar(nova));
  }

  String _subtitulo() {
    final quando = _fetchedAt;
    if (quando == null) {
      return _authorized ? rotuloPlataformaSaude() : 'Conecte o seu relógio ou o app Saúde';
    }
    final hora =
        '${quando.hour.toString().padLeft(2, '0')}:${quando.minute.toString().padLeft(2, '0')}';
    final fonte = _summary?.fonte.trim() ?? '';
    return fonte.isEmpty
        ? 'Sincronizado às $hora'
        : 'Sincronizado às $hora · $fonte';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Saúde',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Saúde',
          subtitle: _subtitulo(),
          showBack: false,
          actions: [
            // Atualizar é puxar a tela para baixo (o botão repetia isso).
            FxHelpIconButton(
              tooltip: 'Como usar Saúde',
              onTap: () {
                AnalyticsService.instance.track(
                  ProductEvents.homeHelpOpened,
                  props: {'surface': 'saude'},
                );
                showFxHelpSheet(
                  context,
                  title: 'Saúde',
                  subtitle: 'Prontidão do dia a partir do relógio e do sono.',
                  tips: [
                    const FxHelpTip('Como calculamos', saudeComoCalculamos),
                    FxHelpTip(
                      'Conectar',
                      'Autorize o ${rotuloPlataformaSaude()} para ler sono, batimentos e passos.',
                    ),
                    const FxHelpTip(
                      'Quem vê',
                      'Você decide se seu personal vê seus dados, na seção Conexão.',
                    ),
                    const FxHelpTip(
                      'Atualizar',
                      'Puxe a tela para baixo: relemos o relógio e enviamos ao servidor.',
                    ),
                    FxHelpTip(
                      'Desconectar',
                      'Em "Gerenciar", na seção Conexão, no fim da tela.',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body:
            _loading
                ? const SaudeSkeleton()
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: isDark,
                  primary: primary,
                  message: _erro!,
                  title: FocuxMicrocopy.naoFoiPossivelCarregar,
                  onRetry: () {
                    setState(() {
                      _erro = null;
                      _loading = true;
                    });
                    _checkAuth();
                  },
                )
                : !_authorized
                ? SaudeDesconectadoView(
                  onConectar: _requestAccess,
                  onAtualizar: _checkAuth,
                )
                : FxContentWidthLimiter(child: _buildDashboard(isDark)),
      ),
    );
  }

  Widget _buildDashboard(bool isDark) {
    final s = _summary!;
    final recovery = _recovery;
    final chrome = ShellChrome.forBrightness(context, isDark);
    final caloriasOk = caloriasPlausiveis(
      passos: s.steps,
      kcalAtivas: s.caloriesBurned,
    );
    final temSono = s.sleepHours > 0;
    final fcRepouso =
        recovery != null && recovery.restingHeartRate > 0
            ? recovery.restingHeartRate
            : s.restingHeartRate;

    Widget entrada(int i, Widget filho) => FxPremiumEntrance(
      delay: Duration(milliseconds: 60 * i),
      child: filho,
    );

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(TokensStrip.s4),
        children: [
          if (_mostrarAvisoCompartilhando) ...[
            _AvisoCompartilhando(
              onEntendi: _dispensarAviso,
              onDesligar: () => _alterarCompartilhamento(false),
            ),
            const SizedBox(height: TokensStrip.s3),
          ],
          entrada(
            0,
            ProntidaoCard(
              recovery: recovery,
              sonoLocal: s.sleepHours > 0,
              onAtualizar: _refreshDashboard,
              onPorQue: () {
                final r = recovery;
                if (r != null) {
                  showProntidaoInsumosSheet(context, recovery: r);
                }
              },
              onVerTreino: () => context.go('/checkin/treinos'),
              onComoRegistrar: _comoLiberar,
            ),
          ),
          if (_syncSoftError != null) ...[
            const SizedBox(height: TokensStrip.s3),
            _SaudeSoftSyncBanner(isDark: isDark, message: _syncSoftError!),
          ],
          const SizedBox(height: TokensStrip.s4),
          const DashboardSectionHeader(title: 'Resumo de hoje'),
          const SizedBox(height: TokensStrip.s3),
          entrada(
            1,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SaudeMetricTile(
                    icone: Icons.directions_walk_rounded,
                    rotulo: 'Passos até agora',
                    valor: s.steps > 0 ? milhar(s.steps) : '--',
                    apoio:
                        s.steps > 0
                            ? 'de ${milhar(_metaPassos)} · toque para ajustar'
                            : 'Toque para definir a meta',
                    progresso: s.steps > 0 ? s.steps / _metaPassos : 0,
                    onTap: _editarMeta,
                  ),
                ),
                const SizedBox(width: TokensStrip.s2),
                Expanded(
                  child:
                      temSono
                          ? SaudeMetricTile(
                            icone: Icons.bedtime_outlined,
                            rotulo: 'Sono',
                            valor: duracaoDeSono(s.sleepHours),
                            apoio: 'Última noite',
                            progresso: s.sleepHours / 8,
                          )
                          : SaudeMetricTile(
                            icone: Icons.bedtime_outlined,
                            rotulo: 'Sono',
                            valor: 'Registrar sono',
                            apoio: 'Use o relógio para dormir',
                            acao: true,
                            onTap: _comoLiberar,
                          ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TokensStrip.s2),
          entrada(
            2,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SaudeMetricTile(
                    icone: Icons.favorite_border_rounded,
                    rotulo: fcRepouso > 0 ? 'FC em repouso' : 'FC média do dia',
                    valor:
                        fcRepouso > 0
                            ? '${fcRepouso.round()}'
                            : (s.avgHeartRate > 0
                                ? '${s.avgHeartRate.round()}'
                                : '--'),
                    unidade:
                        (fcRepouso > 0 || s.avgHeartRate > 0) ? 'bpm' : null,
                    apoio:
                        fcRepouso > 0
                            ? 'Entra na sua nota'
                            : (s.avgHeartRate > 0
                                ? 'Inclui treino e caminhada'
                                : saudeSemBatimento),
                    onTap: () => _explicarFc(fcRepouso: fcRepouso, media: s.avgHeartRate),
                  ),
                ),
                const SizedBox(width: TokensStrip.s2),
                Expanded(
                  child: SaudeMetricTile(
                    icone: Icons.local_fire_department_outlined,
                    rotulo: 'Calorias ativas',
                    valor:
                        caloriasOk && s.caloriesBurned >= 1
                            ? '${s.caloriesBurned.round()}'
                            : '--',
                    unidade:
                        caloriasOk && s.caloriesBurned >= 1 ? 'kcal' : null,
                    apoio: apoioDasCalorias(
                      passos: s.steps,
                      kcal: s.caloriesBurned,
                      fonteEhRelogio: fonteEhRelogio(s.fonte),
                      semDadosHoje: saudeSemDadosHoje,
                    ),
                    // Com relógio e sem energia ativa, o caminho é a permissão.
                    onTap: !(caloriasOk && s.caloriesBurned >= 1) && fonteEhRelogio(s.fonte)
                        ? _gerenciarConexao
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
          entrada(3, ProntidaoTendencia(dias: _historico)),
          const SizedBox(height: TokensStrip.s4),
          entrada(
            4,
            SaudeConexaoCard(
              rotuloFonte: rotuloPlataformaSaude(),
              sincronizado: _subtitulo(),
              compartilhando: _compartilhando,
              onCompartilhar: _alterarCompartilhamento,
              onGerenciar: _gerenciarConexao,
            ),
          ),
          const SizedBox(height: TokensStrip.s6),
          // Só faz sentido falar da nota quando ela existe.
          if (recovery?.recoveryScore != null)
            Center(
              child: Text(
                'Passos não entram na nota: medem atividade, não recuperação.',
                textAlign: TextAlign.center,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ),
          const SizedBox(height: TokensStrip.s4),
        ],
      ),
    );
  }
}

/// Aviso único para quem já compartilhava antes do interruptor existir.
class _AvisoCompartilhando extends StatelessWidget {
  const _AvisoCompartilhando({
    required this.onEntendi,
    required this.onDesligar,
  });

  final VoidCallback onEntendi;
  final VoidCallback onDesligar;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.28)),
        color: primary.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seu personal já vê sua prontidão',
            style: TextStyle(
              color: chrome.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Agora você decide: o interruptor fica na seção Conexão.',
            style: TextStyle(color: chrome.mute, fontSize: 13.5, height: 1.3),
          ),
          const SizedBox(height: TokensStrip.s3),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              FxTonalButton(
                label: 'Entendi',
                compact: true,
                onPressed: onEntendi,
              ),
              FxTonalButton(
                label: 'Desligar agora',
                compact: true,
                onPressed: onDesligar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SaudeSoftSyncBanner extends StatelessWidget {
  const _SaudeSoftSyncBanner({required this.isDark, required this.message});

  final bool isDark;
  final String message;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forBrightness(context, isDark);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TokensStrip.s3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withValues(alpha: 0.18)),
          color: primary.withValues(alpha: isDark ? 0.10 : 0.06),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync parcial',
              style: FocuxHubTypography.body(
                color: chrome.ink,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          ],
        ),
      ),
    );
  }
}
