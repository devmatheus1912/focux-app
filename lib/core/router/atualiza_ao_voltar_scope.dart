import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/alunos/providers/aluno_detail_providers.dart';
import '../../features/alunos/providers/alunos_provider.dart';
import '../../features/dashboard/providers/dashboard_provider.dart';
import '../api/mutacao_recente.dart';
import 'app_router.dart';

/// Tela que resume dados e precisa buscar de novo ao voltar para ela.
enum TelaResumo { homePersonal, homeAluno, alunos, aluno }

({TelaResumo tela, int? alunoId})? telaResumoDaRota(String caminho) {
  if (caminho == '/dashboard/personal') {
    return (tela: TelaResumo.homePersonal, alunoId: null);
  }
  if (caminho == '/dashboard/aluno') {
    return (tela: TelaResumo.homeAluno, alunoId: null);
  }
  if (caminho == '/alunos') return (tela: TelaResumo.alunos, alunoId: null);
  final aluno = RegExp(r'^/alunos/(\d+)$').firstMatch(caminho);
  if (aluno != null) {
    return (tela: TelaResumo.aluno, alunoId: int.parse(aluno.group(1)!));
  }
  return null;
}

/// Sem mudança nesta sessão, a Home ainda atualiza depois deste tempo: o dado
/// pode ter mudado em outro aparelho ou pelo aluno.
const atualizaAoVoltarIdade = Duration(seconds: 30);

bool precisaAtualizar({
  required int geracaoVista,
  required int geracaoAtual,
  required DateTime? vistaEm,
  required DateTime agora,
}) =>
    geracaoVista != geracaoAtual ||
    vistaEm == null ||
    agora.difference(vistaEm) > atualizaAoVoltarIdade;

class AtualizaAoVoltarScope extends ConsumerStatefulWidget {
  const AtualizaAoVoltarScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AtualizaAoVoltarScope> createState() =>
      _AtualizaAoVoltarScopeState();
}

class _AtualizaAoVoltarScopeState extends ConsumerState<AtualizaAoVoltarScope>
    with WidgetsBindingObserver {
  final _vistas = <String, ({int geracao, DateTime em})>{};
  String? _caminho;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppRouter.router.routerDelegate.addListener(_aoMudarRota);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppRouter.router.routerDelegate.removeListener(_aoMudarRota);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _atualizarSePreciso();
  }

  void _aoMudarRota() {
    final caminho = AppRouter.router.routerDelegate.currentConfiguration.uri.path;
    if (caminho == _caminho) return;
    _caminho = caminho;
    // O roteador avisa durante o build: invalidar provider ali é erro.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _atualizarSePreciso();
    });
  }

  void _atualizarSePreciso() {
    final caminho = _caminho;
    if (caminho == null) return;
    final alvo = telaResumoDaRota(caminho);
    if (alvo == null) return;
    final agora = DateTime.now();
    final geracao = MutacaoRecente.geracao;
    final vista = _vistas[caminho];
    // Primeira visita: a própria tela busca.
    _vistas[caminho] = (geracao: geracao, em: agora);
    if (vista == null ||
        !precisaAtualizar(
          geracaoVista: vista.geracao,
          geracaoAtual: geracao,
          vistaEm: vista.em,
          agora: agora,
        )) {
      return;
    }
    switch (alvo.tela) {
      case TelaResumo.homePersonal:
        invalidatePersonalDashboardHome(ref);
      case TelaResumo.homeAluno:
        invalidateAlunoDashboardHome(ref);
      case TelaResumo.alunos:
        invalidateAlunosCaches(ref);
      case TelaResumo.aluno:
        invalidateAluno360Providers(ref, alvo.alunoId!);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
