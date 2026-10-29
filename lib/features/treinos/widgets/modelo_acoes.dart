import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_action_sheet.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../models/ficha_modelo.dart';
import '../providers/ficha_modelos_provider.dart';
import '../providers/treinos_provider.dart';
import 'ficha_acoes.dart';
import 'ficha_vazia.dart';

/// Aplicar, renomear, excluir e criar modelo: as mesmas ações na tela do modelo
/// e no "…" do card da lista. Cada uma devolve true quando mudou algo.

/// Escolhe o aluno e, numa folha só, as cargas e o aviso de que a ficha atual sai.
Future<bool> aplicarModeloEmAluno(BuildContext context, WidgetRef ref, FichaModelo modelo) async {
  final s = S.of(context);
  final alunos = await ref.read(alunosProvider.future);
  if (!context.mounted) return false;
  final destino = await escolherAluno(
    context,
    alunos: alunos,
    excluirId: -1,
    titulo: s.modeloAplicarEmAluno,
  );
  if (destino == null || !context.mounted) return false;
  final nome = alunos.where((a) => a.id == destino).map((a) => a.nome).firstOrNull ?? '';
  final manterCargas = await showFxActionSheet<bool>(
    context,
    title: s.modeloAplicarConfirma(nome),
    itens: [
      FxActionSheetItem(
        value: true,
        label: s.modeloAplicarMantendo,
        icon: Icons.fitness_center_rounded,
      ),
      FxActionSheetItem(
        value: false,
        label: s.modeloAplicarDoZero,
        icon: Icons.restart_alt_rounded,
      ),
    ],
  );
  if (manterCargas == null || !context.mounted) return false;
  try {
    await ref
        .read(fichaModeloRepositoryProvider)
        .aplicar(modelo.id, destino, manterCargas: manterCargas);
    ref.invalidate(alunoRotinaProvider(destino));
    if (context.mounted) FeedbackHelper.showSuccess(context, s.modeloAplicado(nome));
    return true;
  } catch (_) {
    if (context.mounted) FeedbackHelper.showError(context, s.checkinNaoSalvou);
    return false;
  }
}

Future<bool> renomearModelo(BuildContext context, WidgetRef ref, FichaModelo modelo) async {
  final s = S.of(context);
  final nome = await pedirTexto(context, titulo: s.rotinaModeloNomeTitulo, inicial: modelo.nome);
  if (nome == null || !context.mounted) return false;
  try {
    await ref.read(fichaModeloRepositoryProvider).renomear(modelo.id, nome);
    ref.invalidate(fichaModeloProvider(modelo.id));
    ref.invalidate(fichaModelosProvider);
    return true;
  } catch (_) {
    if (context.mounted) FeedbackHelper.showError(context, s.checkinNaoSalvou);
    return false;
  }
}

Future<bool> excluirModelo(BuildContext context, WidgetRef ref, FichaModelo modelo) async {
  final s = S.of(context);
  final ok = await showFxConfirmSheet(
    context,
    title: s.modeloExcluirTitulo,
    message: s.modeloExcluirTexto,
    confirmLabel: s.modeloExcluir,
    destructive: true,
  );
  if (!ok || !context.mounted) return false;
  try {
    await ref.read(fichaModeloRepositoryProvider).arquivar(modelo.id);
    ref.invalidate(fichaModelosProvider);
    return true;
  } catch (_) {
    if (context.mounted) FeedbackHelper.showError(context, s.checkinNaoSalvou);
    return false;
  }
}

/// Novo modelo: dias → divisão → prévia → Criar modelo, sem pedir nome antes.
/// O nome nasce da divisão ("ABC · 5 dias") e muda depois em Renomear.
Future<void> criarNovoModelo(BuildContext context, WidgetRef ref) async {
  final s = S.of(context);
  final plano = await escolherDivisao(context, titulo: s.modelosNovo, botao: s.modeloCriar);
  if (plano == null || !context.mounted) return;
  try {
    final modelo = await ref.read(fichaModeloRepositoryProvider).criarPelaSemana(
      nome: s.modeloNomeDivisao(plano.divisao, plano.dias),
      dias: plano.semana,
    );
    ref.invalidate(fichaModelosProvider);
    if (context.mounted) context.push('/modelos/${modelo.id}');
  } catch (_) {
    if (context.mounted) FeedbackHelper.showError(context, s.checkinNaoSalvou);
  }
}
