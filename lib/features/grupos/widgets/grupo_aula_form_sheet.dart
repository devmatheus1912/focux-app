import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_calendario_sheet.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../core/widgets/fx_horario.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_inset_picker_row.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../data/grupo_aula_repository.dart';
import '../utils/grupo_aula_display.dart';
import 'grupo_aula_alunos_sheet.dart';

/// O que a folha devolve: a aula como o personal deixou e, ao criar, quem
/// já entra inscrito.
class GrupoAulaRascunho {
  const GrupoAulaRascunho({
    required this.titulo,
    required this.descricao,
    required this.inicio,
    required this.fim,
    required this.capacidade,
    required this.local,
    this.alunoIds = const [],
  });

  final String titulo;
  final String? descricao;
  final DateTime inicio;
  final DateTime fim;
  final int capacidade;
  final String? local;
  final List<int> alunoIds;
}

/// Folha de criar ou editar aula. [alunos] liga a linha "Alunos" (só ao criar).
/// [minimoCapacidade]: inscritos atuais (a capacidade não desce abaixo).
Future<GrupoAulaRascunho?> showGrupoAulaFormSheet(
  BuildContext context, {
  GrupoAula? aula,
  List<Aluno>? alunos,
  int minimoCapacidade = 1,
}) async {
  final agora = DateTime.now();
  var inicio =
      aula?.inicio ?? DateTime(agora.year, agora.month, agora.day + 1, 7);
  var fim =
      aula?.fim ??
      inicio.add(const Duration(minutes: grupoAulaDuracaoPadrao));
  // Aula gravada com duração fora das quatro: fica como opção a mais.
  final duracaoFora = grupoAulaDuracaoFora(fim.difference(inicio).inMinutes);
  var capacidade = aula?.capacidadeMax ?? 20;
  var escolhidos = <int>[];
  String? erroTitulo;
  final tituloCtrl = TextEditingController(text: aula?.titulo ?? '');
  final descricaoCtrl = TextEditingController(text: aula?.descricao ?? '');
  final localCtrl = TextEditingController(text: aula?.localAula ?? '');
  void Function(VoidCallback)? atualizar;

  try {
    final ok = await showFxFormSheet(
      context,
      title: aula == null ? 'Nova aula em grupo' : 'Editar aula',
      icon: FxIcons.grupo,
      confirmLabel: aula == null ? 'Criar aula' : 'Salvar',
      podeConfirmar: () {
        erroTitulo =
            tituloCtrl.text.trim().isEmpty ? 'Dê um nome à aula.' : null;
        atualizar?.call(() {});
        return erroTitulo == null;
      },
      child: StatefulBuilder(
        builder: (ctx, setSheet) {
          atualizar = setSheet;
          final chrome = ShellChrome.of(ctx);
          Future<void> escolherDia() async {
            final hoje = DateTime.now();
            final hojeDia = DateUtils.dateOnly(hoje);
            final diaAtual = DateUtils.dateOnly(inicio);
            // Aula antiga (editar): o calendário começa no dia dela.
            final dia = (await showFxCalendarioSheet(
              ctx,
              titulo: 'Dia',
              inicial: diaAtual,
              primeiro: diaAtual.isBefore(hojeDia) ? diaAtual : hojeDia,
              ultimo: DateTime(hoje.year, hoje.month + 6, hoje.day),
            ))?.data;
            if (dia == null) return;
            setSheet(() {
              final duracao = fim.difference(inicio);
              inicio = DateTime(
                dia.year,
                dia.month,
                dia.day,
                inicio.hour,
                inicio.minute,
              );
              fim = inicio.add(duracao);
            });
          }

          Future<void> escolherHorario() async {
            final comeco = await showFxHorario(
              ctx,
              titulo: 'Começa às',
              inicial: TimeOfDay.fromDateTime(inicio),
            );
            if (comeco == null) return;
            setSheet(() {
              final duracao = fim.difference(inicio);
              inicio = DateTime(
                inicio.year,
                inicio.month,
                inicio.day,
                comeco.hour,
                comeco.minute,
              );
              fim = inicio.add(duracao);
            });
          }

          Future<void> escolherAlunos() async {
            final lista = alunos;
            if (lista == null) return;
            final novos = await showGrupoAulaAlunosSheet(
              ctx,
              alunos: lista,
              selecionados: escolhidos.toSet(),
              limite: capacidade,
            );
            if (novos != null) setSheet(() => escolhidos = novos.toList());
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AlunoInsetFormField(
                controller: tituloCtrl,
                label: 'Título',
                icon: FxIcons.titulo,
                hint: 'Ex: Funcional ao ar livre',
                obrigatorio: true,
                ajuda: erroTitulo,
                ajudaErro: erroTitulo != null,
              ),
              AlunoInsetFormField(
                controller: descricaoCtrl,
                label: 'Descrição',
                icon: FxIcons.notas,
                hint: 'O que levar, nível, aquecimento…',
                maxLines: 2,
              ),
              FxInsetPickerRow(
                icon: FxIcons.calendario,
                label: 'Dia',
                value: grupoAulaDiaLabel(inicio),
                onTap: escolherDia,
              ),
              FxInsetPickerRow(
                icon: FxIcons.relogio,
                label: 'Começa às',
                value: grupoAulaHorarioLabel(inicio, fim),
                onTap: escolherHorario,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Builder(
                  builder: (_) {
                    final atual = fim.difference(inicio).inMinutes;
                    final fora = duracaoFora;
                    return FxChoiceStrip<int>(
                      itens: [
                        for (final m in grupoAulaDuracoes)
                          FxChoiceItem(
                            value: m,
                            label: grupoAulaDuracaoLabel(m),
                          ),
                        if (fora != null)
                          FxChoiceItem(
                            value: fora,
                            label: grupoAulaDuracaoLabel(fora),
                          ),
                      ],
                      selecionado: atual,
                      onSelecionar:
                          (m) => setSheet(
                            () => fim = inicio.add(Duration(minutes: m)),
                          ),
                    );
                  },
                ),
              ),
              FxSettingsTile(
                icon: FxIcons.grupo,
                label: 'Vagas',
                value: '',
                mute: chrome.mute,
                line: chrome.line,
                accessory: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Menos vagas',
                      onPressed:
                          capacidade <= minimoCapacidade
                              ? null
                              : () {
                                HapticFeedback.selectionClick();
                                setSheet(() => capacidade--);
                              },
                      icon: const Icon(FxIcons.remover),
                    ),
                    Text(
                      '$capacidade',
                      style: FocuxHubTypography.body(color: chrome.ink),
                    ),
                    IconButton(
                      tooltip: 'Mais vagas',
                      onPressed:
                          capacidade >= grupoAulaCapacidadeLimite
                              ? null
                              : () {
                                HapticFeedback.selectionClick();
                                setSheet(() => capacidade++);
                              },
                      icon: const Icon(FxIcons.adicionar),
                    ),
                  ],
                ),
              ),
              AlunoInsetFormField(
                controller: localCtrl,
                label: 'Local',
                icon: FxIcons.local,
                hint: 'Studio, Praia, Online…',
                showDivider: alunos != null,
              ),
              if (alunos != null)
                FxInsetPickerRow(
                  icon: FxIcons.adicionarPessoa,
                  label: 'Alunos (opcional)',
                  value: grupoAulaAlunosEscolhidosLabel(escolhidos.length),
                  onTap: escolherAlunos,
                  showDivider: false,
                ),
            ],
          );
        },
      ),
    );
    if (!ok) return null;
    String? ouNulo(String s) => s.trim().isEmpty ? null : s.trim();
    return GrupoAulaRascunho(
      titulo: tituloCtrl.text.trim(),
      descricao: ouNulo(descricaoCtrl.text),
      inicio: inicio,
      fim: fim,
      capacidade: capacidade,
      local: ouNulo(localCtrl.text),
      alunoIds: escolhidos,
    );
  } finally {
    tituloCtrl.dispose();
    descricaoCtrl.dispose();
    localCtrl.dispose();
  }
}
