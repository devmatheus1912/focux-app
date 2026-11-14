import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_calendario_sheet.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_number_pad_sheet.dart';
import '../../../core/widgets/fx_quick_chips.dart';
import '../../../core/widgets/fx_valor_stepper.dart';
import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_series.dart';
import 'escolher_exercicio_campo.dart';

/// O que a folha "Registrar carga" devolve.
typedef CargaRegistrada = ({
  ExercicioEscolhido exercicio,
  double carga,
  int? repeticoes,
  DateTime data,
});

/// Carga aceita: de 0,5 a 1000 kg (a mesma regra do backend).
bool cargaValida(double? carga) => carga != null && carga >= 0.5 && carga <= 1000;

/// Última carga registrada do exercício e o recorde dele, sem o registro
/// [ignorarId] (o que está sendo editado).
({RecordePessoal? ultima, double? recorde}) contextoDaCarga(
  List<RecordePessoal> recordes,
  String exercicio, {
  int? ignorarId,
}) {
  final chave = exercicio.trim().toLowerCase();
  final doExercicio = [
    for (final r in recordes)
      if (r.id != ignorarId && r.exercicioNome.trim().toLowerCase() == chave) r,
  ]..sort((a, b) {
    final porData = b.data.compareTo(a.data);
    return porData != 0 ? porData : b.id.compareTo(a.id);
  });
  final cargas = [for (final r in doExercicio) if (r.cargaKg case final kg?) kg];
  return (
    ultima: doExercicio.firstOrNull,
    recorde: cargas.isEmpty ? null : cargas.reduce((a, b) => a > b ? a : b),
  );
}

/// Quanto a [carga] passa do recorde; nulo sem recorde anterior ou sem passar.
double? ganhoDeRecorde(double? carga, double? recorde) {
  if (carga == null || recorde == null || recorde <= 0 || carga <= recorde) {
    return null;
  }
  return carga - recorde;
}

enum _Dia { hoje, ontem, outra }

/// "Registrar carga" / "Editar carga": exercício, carga e repetições nos
/// steppers da execução do treino, o contexto do exercício (última e recorde),
/// a prévia do recorde e a data. Nulo ao cancelar.
Future<CargaRegistrada?> abrirRegistrarCarga(
  BuildContext context, {
  required List<RecordePessoal> recordes,
  RecordePessoal? editando,
  ExercicioEscolhido? exercicioInicial,
}) async {
  final vistos = <String>{};
  final recentes = <ExercicioEscolhido>[
    for (final r in recordes)
      if (vistos.add(r.exercicioNome.toLowerCase()))
        (id: r.exercicioId, nome: r.exercicioNome),
  ].take(5).toList();
  final estado = _EstadoDaFolha(
    exercicio:
        editando == null
            ? exercicioInicial
            : (id: editando.exercicioId, nome: editando.exercicioNome),
    carga: editando?.cargaKg,
    reps: editando?.repeticoes,
    data: DateTime.tryParse(editando?.data ?? ''),
  );
  final inicial = estado.exercicio;
  if (editando == null && inicial != null) {
    estado.partirDaUltima(contextoDaCarga(recordes, inicial.nome).ultima);
  }
  final ok = await showFxFormSheet(
    context,
    title: editando == null ? ptS.evolucaoRegistrarCarga : ptS.evolucaoEditarCarga,
    icon: null,
    confirmLabel: ptS.evolucaoSalvar,
    podeConfirmar: () {
      estado.validar();
      return estado.erroExercicio == null && estado.erroCarga == null;
    },
    child: _Conteudo(
      estado: estado,
      recordes: recordes,
      recentes: recentes,
      ignorarId: editando?.id,
    ),
  );
  final exercicio = estado.exercicio;
  final carga = estado.carga;
  estado.dispose();
  if (!ok || exercicio == null || carga == null) return null;
  return (
    exercicio: exercicio,
    carga: carga,
    repeticoes: estado.reps,
    data: estado.dataEscolhida,
  );
}

class _EstadoDaFolha extends ChangeNotifier {
  _EstadoDaFolha({this.exercicio, this.carga, this.reps, DateTime? data}) {
    if (data != null) _definirData(data);
  }

  ExercicioEscolhido? exercicio;
  double? carga;
  int? reps;
  _Dia dia = _Dia.hoje;
  DateTime? outra;
  String? erroExercicio;
  String? erroCarga;

  DateTime get dataEscolhida {
    final hoje = DateUtils.dateOnly(DateTime.now());
    return switch (dia) {
      _Dia.hoje => hoje,
      _Dia.ontem => hoje.subtract(const Duration(days: 1)),
      _Dia.outra => outra ?? hoje,
    };
  }

  void _definirData(DateTime d) {
    final hoje = DateUtils.dateOnly(DateTime.now());
    final dia = DateUtils.dateOnly(d);
    if (dia == hoje) {
      this.dia = _Dia.hoje;
    } else if (dia == hoje.subtract(const Duration(days: 1))) {
      this.dia = _Dia.ontem;
    } else {
      this.dia = _Dia.outra;
      outra = dia;
    }
  }

  void mudar(VoidCallback f) {
    f();
    notifyListeners();
  }

  /// Ao escolher o exercício, carga e repetições começam na última vez.
  void partirDaUltima(RecordePessoal? ultima) {
    if (ultima == null) return;
    carga = ultima.cargaKg ?? carga;
    reps = ultima.repeticoes ?? reps;
  }

  void validar() {
    erroExercicio = exercicio == null ? ptS.evolucaoInformeExercicio : null;
    erroCarga = cargaValida(carga) ? null : ptS.evolucaoCargaInvalida;
    notifyListeners();
  }
}

class _Conteudo extends StatelessWidget {
  const _Conteudo({
    required this.estado,
    required this.recordes,
    required this.recentes,
    this.ignorarId,
  });

  final _EstadoDaFolha estado;
  final List<RecordePessoal> recordes;
  final List<ExercicioEscolhido> recentes;
  final int? ignorarId;

  static const _passoCarga = 1.0;

  Future<void> _digitar(
    BuildContext context, {
    required String titulo,
    required double? inicial,
    required bool decimal,
    required ValueChanged<double> aoEscolher,
  }) async {
    final r = await showFxNumberPadSheet(
      context,
      titulo: titulo,
      confirmarLabel: MaterialLocalizations.of(context).okButtonLabel,
      sufixo: titulo,
      inicial: inicial,
      decimal: decimal,
      maximo: decimal ? 1000 : 100,
    );
    if (r?.valor case final v?) aoEscolher(v);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        final chrome = ShellChrome.of(context);
        final brand = Theme.of(context).colorScheme.primary;
        final exercicio = estado.exercicio;
        final ctx =
            exercicio == null
                ? null
                : contextoDaCarga(recordes, exercicio.nome, ignorarId: ignorarId);
        final ganho = ganhoDeRecorde(estado.carga, ctx?.recorde);
        final carga = estado.carga;
        final reps = estado.reps;
        final contexto = [
          if (ctx?.ultima case final u? when u.cargaKg != null)
            ptS.evolucaoCargaUltima(
              u.repeticoes == null
                  ? formatBrComUnidade(u.cargaKg!, 'kg')
                  : '${formatBrComUnidade(u.cargaKg!, 'kg')} × ${u.repeticoes}',
            ),
          if (ctx?.recorde case final kg?)
            ptS.evolucaoCargaRecordeAtual(formatBrComUnidade(kg, 'kg')),
        ].join(' · ');
        final bom = chrome.isDark ? EagleTokens.goodDark : EagleTokens.good;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EscolherExercicioCampo(
              rotulo: ptS.evolucaoCargaExercicio,
              escolhido: exercicio,
              recentes: recentes,
              erro: estado.erroExercicio,
              onEscolher:
                  (e) => estado.mudar(() {
                    final mudou =
                        estado.exercicio?.nome.toLowerCase() != e.nome.toLowerCase();
                    estado.exercicio = e;
                    estado.erroExercicio = null;
                    if (mudou && ignorarId == null) {
                      estado.partirDaUltima(contextoDaCarga(recordes, e.nome).ultima);
                    }
                  }),
            ),
            if (contexto.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: TokensStrip.s3),
                child: Text(
                  contexto,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute)
                      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: FxValorStepper(
                      label: ptS.checkinStepperKg,
                      value: carga == null ? '—' : fxNumberPadTexto(carga),
                      mute: chrome.mute,
                      ink: chrome.ink,
                      accent: brand,
                      onMinus:
                          carga == null || carga - _passoCarga < 0.5
                              ? null
                              : () => estado.mudar(() {
                                estado.carga = carga - _passoCarga;
                                estado.erroCarga = null;
                              }),
                      onPlus:
                          () => estado.mudar(() {
                            final atual = estado.carga ?? 0;
                            if (atual + _passoCarga <= 1000) {
                              estado.carga = atual + _passoCarga;
                            }
                            estado.erroCarga = null;
                          }),
                      onEditar:
                          () => _digitar(
                            context,
                            titulo: ptS.checkinStepperKg,
                            inicial: carga,
                            decimal: true,
                            aoEscolher:
                                (v) => estado.mudar(() {
                                  estado.carga = v;
                                  estado.erroCarga = null;
                                }),
                          ),
                    ),
                  ),
                  VerticalDivider(
                    width: TokensStrip.s4,
                    thickness: 1,
                    color: chrome.mute.withValues(alpha: 0.22),
                  ),
                  Expanded(
                    child: FxValorStepper(
                      label: ptS.checkinStepperReps,
                      value: reps == null ? '—' : '$reps',
                      mute: chrome.mute,
                      ink: chrome.ink,
                      accent: brand,
                      onMinus:
                          reps == null || reps <= 1
                              ? null
                              : () => estado.mudar(() => estado.reps = reps - 1),
                      onPlus:
                          () => estado.mudar(
                            () => estado.reps = ((estado.reps ?? 0) + 1).clamp(1, 100),
                          ),
                      onEditar:
                          () => _digitar(
                            context,
                            titulo: ptS.checkinStepperReps,
                            inicial: reps?.toDouble(),
                            decimal: false,
                            aoEscolher:
                                (v) => estado.mudar(
                                  () => estado.reps = v.round() < 1 ? null : v.round(),
                                ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
            if (estado.erroCarga case final erro?)
              Padding(
                padding: const EdgeInsets.only(top: TokensStrip.s2),
                child: Text(
                  erro,
                  style: FocuxHubTypography.bodyMuted(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            if (ganho != null)
              Padding(
                padding: const EdgeInsets.only(top: TokensStrip.s2),
                child: Text(
                  ptS.evolucaoCargaNovoRecorde(diferencaTexto(ganho, 'kg')),
                  style: FocuxHubTypography.chip(bom),
                ),
              ),
            const SizedBox(height: TokensStrip.s3),
            Text(ptS.evolucaoCargaData, style: FocuxHubTypography.chip(chrome.mute)),
            const SizedBox(height: TokensStrip.s1),
            FxQuickChips<_Dia>(
              itens: _Dia.values,
              selecionado: estado.dia,
              rotuloDe:
                  (d) => switch (d) {
                    _Dia.hoje => ptS.evolucaoHoje,
                    _Dia.ontem => ptS.evolucaoOntem,
                    _Dia.outra =>
                      estado.outra == null
                          ? ptS.evolucaoOutraData
                          : dataCurta(estado.outra!),
                  },
              onSelecionar: (d) async {
                if (d != _Dia.outra) {
                  estado.mudar(() => estado.dia = d);
                  return;
                }
                final hoje = DateTime.now();
                final escolha = await showFxCalendarioSheet(
                  context,
                  titulo: ptS.evolucaoCargaData,
                  inicial: estado.outra ?? hoje.subtract(const Duration(days: 2)),
                  primeiro: hoje.subtract(const Duration(days: 365)),
                  ultimo: hoje,
                );
                if (escolha?.data case final data?) {
                  estado.mudar(() {
                    estado.outra = DateUtils.dateOnly(data);
                    estado.dia = _Dia.outra;
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }
}
