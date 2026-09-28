import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/feedback_helper.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/utils/aluno360_client_cache.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../evolucao/utils/evolucao_home_client_cache.dart';
import '../providers/checkin_provider.dart';
import '../services/checkin_fila_sync.dart';
import '../utils/checkin_series_fila.dart';

/// Reenvia a fila de séries em qualquer tela: ao entrar logado, ao voltar
/// do background e quando a conexão volta. Recusa do servidor vira aviso.
class CheckinFilaSyncScope extends ConsumerStatefulWidget {
  const CheckinFilaSyncScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CheckinFilaSyncScope> createState() =>
      _CheckinFilaSyncScopeState();
}

class _CheckinFilaSyncScopeState extends ConsumerState<CheckinFilaSyncScope>
    with WidgetsBindingObserver {
  StreamSubscription<void>? _conexao;
  StreamSubscription<CheckinFilaResultado>? _rodadas;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _rodadas = ref.read(checkinFilaSyncProvider).rodadas.listen(_aoTerminar);
    _conexao = ref.read(checkinConexaoVoltouProvider).listen((_) => _enviar());
    ref.listenManual(authProvider, (_, status) {
      if (status == AuthStatus.authenticated) _enviar();
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _conexao?.cancel();
    _rodadas?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _enviar();
  }

  Future<void> _enviar() async {
    if (ref.read(authProvider) != AuthStatus.authenticated) return;
    try {
      if ((await CheckinFilaSync.store.ler()).isEmpty || !mounted) return;
      await ref.read(checkinFilaSyncProvider).enviar();
    } catch (_) {}
  }

  void _aoTerminar(CheckinFilaResultado r) {
    if (!mounted || (r.enviadas.isEmpty && r.rejeitadas == 0)) return;
    EvolucaoHomeClientCache.clear();
    Aluno360ClientCache.clear();
    invalidateAlunoDashboardHome(ref);
    if (r.rejeitadas > 0) {
      FeedbackHelper.showError(
        context,
        S.of(context).checkinSeriesRejeitadas(r.rejeitadas),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
