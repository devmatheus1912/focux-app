import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/fx_motion.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/ficha_modelos_provider.dart';
import '../providers/ficha_volume_provider.dart';
import '../providers/treinos_provider.dart';
import '../utils/semana_da_fila.dart';
import '../utils/semana_do_modelo.dart';
import '../utils/treino_criacao_fluxo.dart';

/// De onde o treino foi aberto: muda o menu "…" e o que o rodapé oferece.
enum LugarDoTreino { ficha, modelo, biblioteca }

LugarDoTreino lugarDoTreino({int? alunoId, int? modeloId}) => alunoId != null
    ? LugarDoTreino.ficha
    : modeloId != null
    ? LugarDoTreino.modelo
    : LugarDoTreino.biblioteca;

/// A semana da ficha ou do modelo onde o treino está; nula na biblioteca ou antes de carregar.
List<DiaDaSemana>? semanaDoLugar(WidgetRef ref, {int? alunoId, int? modeloId}) {
  if (alunoId != null) {
    final fila = ref.watch(alunoRotinaProvider(alunoId)).asData?.value;
    return fila == null ? null : semanaDaFila(fila);
  }
  if (modeloId != null) {
    final modelo = ref.watch(fichaModeloProvider(modeloId)).asData?.value;
    return modelo == null ? null : semanaDoModelo(modelo);
  }
  return null;
}

/// Lê a semana do lugar esperando o servidor (para ações do menu).
Future<List<DiaDaSemana>?> lerSemanaDoLugar(WidgetRef ref, {int? alunoId, int? modeloId}) async {
  if (alunoId != null) return semanaDaFila(await ref.read(alunoRotinaProvider(alunoId).future));
  if (modeloId != null) return semanaDoModelo(await ref.read(fichaModeloProvider(modeloId).future));
  return null;
}

/// Dono da atualização: toda mudança na sessão passa aqui, e a ficha ou o
/// modelo por trás já mostram a contagem e o volume novos.
void sessaoMudou(
  WidgetRef ref,
  int treinoId, {
  int? alunoId,
  int? modeloId,
}) {
  ref.invalidate(treinoProvider(treinoId));
  if (alunoId != null) {
    ref.invalidate(alunoRotinaProvider(alunoId));
    ref.invalidate(fichaVolumeProvider(alunoId));
  }
  if (modeloId != null) {
    ref.invalidate(fichaModeloProvider(modeloId));
    ref.invalidate(modeloVolumeProvider(modeloId));
    ref.invalidate(fichaModelosProvider);
  }
}

/// Grava a semana na ficha do aluno ou no modelo e atualiza o que mostra ela.
Future<void> gravarSemanaDoLugar(
  WidgetRef ref, {
  int? alunoId,
  int? modeloId,
  required List<DiaDaSemana> dias,
}) async {
  if (alunoId != null) {
    await ref.read(treinoRepositoryProvider).gravarSemana(alunoId, dias);
    ref.invalidate(alunoRotinaProvider(alunoId));
    ref.invalidate(fichaVolumeProvider(alunoId));
  } else if (modeloId != null) {
    await ref.read(fichaModeloRepositoryProvider).gravarSemana(modeloId, dias);
    ref.invalidate(fichaModeloProvider(modeloId));
    ref.invalidate(modeloVolumeProvider(modeloId));
    ref.invalidate(fichaModelosProvider);
  }
}

/// A semana sem a sessão [treinoId]; o dia que fica vazio vira descanso.
List<DiaDaSemana> semanaSemASessao(List<DiaDaSemana> semana, int treinoId) => [
  for (final d in semana)
    if (d.sessoes.any((x) => x.treinoId == treinoId))
      switch (d.sessoes.where((x) => x.treinoId != treinoId).toList()) {
        final resto when resto.isEmpty => DiaDaSemana(dia: d.dia, descanso: true),
        final resto => d.copyWith(sessoes: resto),
      }
    else
      d,
];

/// Próxima sessão vazia depois de [treinoId], na ordem da semana (volta ao início).
SessaoDaSemana? proximaSessaoVazia(List<DiaDaSemana> semana, int treinoId) {
  final sessoes = [
    for (final d in semana)
      for (final x in d.sessoes)
        if (x.treinoId != null) x,
  ];
  final atual = sessoes.indexWhere((x) => x.treinoId == treinoId);
  if (atual < 0) return null;
  for (var passo = 1; passo < sessoes.length; passo++) {
    final candidata = sessoes[(atual + passo) % sessoes.length];
    if (candidata.exerciciosCount == 0) return candidata;
  }
  return null;
}

/// Rodapé de quem monta pela ficha ou pelo modelo: "Montar {próxima}" quando
/// ainda há sessão vazia, senão "Pronto".
class MontarEmSequencia extends ConsumerWidget {
  const MontarEmSequencia({
    super.key,
    required this.treinoId,
    this.alunoId,
    this.alunoNome,
    this.modeloId,
  });

  final int treinoId;
  final int? alunoId;
  final String? alunoNome;
  final int? modeloId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semana = semanaDoLugar(ref, alunoId: alunoId, modeloId: modeloId);
    final s = S.of(context);
    final proxima = semana == null ? null : proximaSessaoVazia(semana, treinoId);
    if (proxima == null) {
      return FxLiquidPrimaryButton(
        label: s.rotinaPronto,
        onPressed: () => context.pop(),
      );
    }
    return FxLiquidPrimaryButton(
      label: s.treinoMontarProxima(proxima.nome),
      onPressed: () => context.pushReplacement(
        '/treinos/${proxima.treinoId}',
        extra: TreinoRouteExtra(
          alunoId: alunoId,
          alunoNome: alunoNome,
          modeloId: modeloId,
        ).toExtra(),
      ),
    );
  }
}
