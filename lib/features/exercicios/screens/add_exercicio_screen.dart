import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../data/enums.dart';
import '../data/exercicio_taxonomy_labels.dart';
import '../providers/exercicios_provider.dart';

class AddExercicioScreen extends ConsumerStatefulWidget {
  const AddExercicioScreen({super.key});

  @override
  ConsumerState<AddExercicioScreen> createState() => _AddExercicioScreenState();
}

class _AddExercicioScreenState extends ConsumerState<AddExercicioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _errosComunsCtrl = TextEditingController();
  final _contraindicacoesCtrl = TextEditingController();

  Modalidade? _modalidade = Modalidade.musculacao;
  PadraoMovimento? _padraoMovimento;
  GrupoMuscular? _grupoMuscularPrimario;
  Dificuldade? _dificuldade = Dificuldade.iniciante;
  final Set<Equipamento> _equipamentos = {
    Equipamento.halter,
    Equipamento.barra,
    Equipamento.maquina,
    Equipamento.polia,
    Equipamento.banco,
  };
  final Set<Espaco> _espacos = {Espaco.academiaCompleta, Espaco.academiaBasica};
  bool _unilateral = false;
  bool _showFilters = false;
  bool _showGuidance = false;
  bool _loading = false;
  String? _error;
  String? _selectedSetupLabel = 'Academia';

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _errosComunsCtrl.dispose();
    _contraindicacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(exercicioRepositoryProvider)
          .criar(
            nome: _nomeCtrl.text.trim(),
            descricao: _descricaoCtrl.text.trim(),
            musculoAlvo: _grupoMuscularPrimario?.backendName,
            categoria: _modalidade?.backendName,
            equipamento: _equipamentos
                .map((e) => TaxonomyLabels.equipamento[e])
                .join(', '),
            nivel:
                _dificuldade == null
                    ? null
                    : TaxonomyLabels.dificuldade[_dificuldade!],
            mecanica:
                _padraoMovimento == null
                    ? null
                    : TaxonomyLabels.padrao[_padraoMovimento!],
            modalidade: _modalidade,
            padraoMovimento: _padraoMovimento,
            grupoMuscularPrimario: _grupoMuscularPrimario,
            equipamentos: _equipamentos.toList(),
            espacosCompativeis: _espacos.toList(),
            dificuldade: _dificuldade,
            unilateral: _unilateral,
            errosComuns: _errosComunsCtrl.text.trim(),
            contraindicacoes: _contraindicacoesCtrl.text.trim(),
          );
      ref.invalidate(exerciciosFilteredProvider);
      if (mounted) context.pop(true);
    } catch (_) {
      setState(() => _error = 'Erro ao cadastrar exercicio.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyQuickSetup(_ExerciseQuickSetup setup) {
    setState(() {
      _selectedSetupLabel = setup.label;
      _modalidade = setup.modalidade;
      _dificuldade = setup.dificuldade;
      if (setup.padraoMovimento != null) {
        _padraoMovimento = setup.padraoMovimento;
      }
      _equipamentos
        ..clear()
        ..addAll(setup.equipamentos);
      _espacos
        ..clear()
        ..addAll(setup.espacos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primary = Theme.of(context).colorScheme.primary;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOVO ITEM',
                        style: TextStyle(
                          fontSize: 12,
                          color: mute,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Novo Exercício',
                        style: TextStyle(
                          fontSize: 28,
                          color: ink,
                          height: 1.04,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: mute),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 132 + bottom),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionCard(
                        icon: Icons.fitness_center_rounded,
                        title: 'Identidade',
                        subtitle: 'Defina nome, grupo e intenção principal.',
                        child: Column(
                          children: [
                            _TextInput(
                              controller: _nomeCtrl,
                              label: 'Nome do exercício',
                              hint: 'Ex.: Elevação lateral',
                              validator:
                                  (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Informe o nome'
                                          : null,
                            ),
                            const SizedBox(height: 12),
                            _QuickSetupStrip(
                              selectedLabel: _selectedSetupLabel,
                              onSelected: _applyQuickSetup,
                            ),
                            const SizedBox(height: 12),
                            _EnumDropdown<GrupoMuscular>(
                              label: 'Grupo principal',
                              value: _grupoMuscularPrimario,
                              values: GrupoMuscular.values,
                              labels: TaxonomyLabels.grupo,
                              onChanged:
                                  (v) => setState(
                                    () => _grupoMuscularPrimario = v,
                                  ),
                              validator:
                                  (v) => v == null ? 'Escolha o grupo' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _EnumDropdown<Modalidade>(
                                    label: 'Modalidade',
                                    value: _modalidade,
                                    values: Modalidade.values,
                                    labels: TaxonomyLabels.modalidade,
                                    onChanged:
                                        (v) => setState(() => _modalidade = v),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _EnumDropdown<Dificuldade>(
                                    label: 'Dificuldade',
                                    value: _dificuldade,
                                    values: Dificuldade.values,
                                    labels: TaxonomyLabels.dificuldade,
                                    onChanged:
                                        (v) => setState(() => _dificuldade = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _EnumDropdown<PadraoMovimento>(
                              label: 'Padrão de movimento',
                              value: _padraoMovimento,
                              values: PadraoMovimento.values,
                              labels: TaxonomyLabels.padrao,
                              onChanged:
                                  (v) => setState(() => _padraoMovimento = v),
                            ),
                            const SizedBox(height: 12),
                            _SwitchRow(
                              value: _unilateral,
                              title: 'Unilateral',
                              subtitle:
                                  'Marque quando cada lado deve ser executado separadamente.',
                              onChanged: (v) => setState(() => _unilateral = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        icon: Icons.inventory_2_outlined,
                        title: 'Equipamentos e espaços',
                        subtitle: _filterSummary(
                          equipamentos: _equipamentos.length,
                          espacos: _espacos.length,
                        ),
                        expanded: _showFilters,
                        onToggle:
                            () => setState(() => _showFilters = !_showFilters),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GroupLabel(
                              label: 'Equipamentos',
                              count: _equipamentos.length,
                            ),
                            const SizedBox(height: 8),
                            _ChoiceGroup<Equipamento>(
                              values: Equipamento.values,
                              selected: _equipamentos,
                              labels: TaxonomyLabels.equipamento,
                              onToggle:
                                  (value) => setState(() {
                                    _equipamentos.contains(value)
                                        ? _equipamentos.remove(value)
                                        : _equipamentos.add(value);
                                  }),
                            ),
                            const SizedBox(height: 14),
                            _GroupLabel(
                              label: 'Espaços',
                              count: _espacos.length,
                            ),
                            const SizedBox(height: 8),
                            _ChoiceGroup<Espaco>(
                              values: Espaco.values,
                              selected: _espacos,
                              labels: TaxonomyLabels.espaco,
                              onToggle:
                                  (value) => setState(() {
                                    _espacos.contains(value)
                                        ? _espacos.remove(value)
                                        : _espacos.add(value);
                                  }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        icon: Icons.co_present_outlined,
                        title: 'Orientação opcional',
                        subtitle:
                            _showGuidance
                                ? 'Adicione detalhes se eles forem úteis para o aluno.'
                                : 'Execução, erros comuns e restrições quando precisar.',
                        expanded: _showGuidance,
                        onToggle:
                            () =>
                                setState(() => _showGuidance = !_showGuidance),
                        child: Column(
                          children: [
                            _TextInput(
                              controller: _descricaoCtrl,
                              label: 'Descrição curta',
                              hint: 'Como executar em uma frase objetiva.',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            _TextInput(
                              controller: _errosComunsCtrl,
                              label: 'Erros comuns',
                              hint:
                                  'Ex.: elevar os ombros, roubar com o tronco.',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            _TextInput(
                              controller: _contraindicacoesCtrl,
                              label: 'Contraindicações',
                              hint: 'Quando evitar ou adaptar este exercício.',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: EagleTokens.bad.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: EagleTokens.bad.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: EagleTokens.bad,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              top: BorderSide(
                color:
                    isDark
                        ? EagleTokens.darkLine
                        : EagleTokens.line.withValues(alpha: 0.78),
              ),
            ),
          ),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: primary.withValues(alpha: 0.42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child:
                  _loading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Cadastrar exercício',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

String _filterSummary({required int equipamentos, required int espacos}) {
  if (equipamentos == 0 && espacos == 0) {
    return 'Opcional: refine filtros quando isso ajudar na busca.';
  }
  if (equipamentos == 0) {
    final espacoText = '$espacos espaço${espacos == 1 ? '' : 's'}';
    return 'Espaço definido: $espacoText. Toque para adicionar equipamentos.';
  }
  if (espacos == 0) {
    final equipamentoText =
        '$equipamentos equipamento${equipamentos == 1 ? '' : 's'}';
    return 'Equipamentos definidos: $equipamentoText. Toque para adicionar espaços.';
  }
  final equipamentoText =
      '$equipamentos equipamento${equipamentos == 1 ? '' : 's'}';
  final espacoText = '$espacos espaço${espacos == 1 ? '' : 's'}';
  return '$equipamentoText e $espacoText definidos. Toque para ajustar.';
}

class _ExerciseQuickSetup {
  final String label;
  final IconData icon;
  final Modalidade modalidade;
  final Dificuldade dificuldade;
  final PadraoMovimento? padraoMovimento;
  final Set<Equipamento> equipamentos;
  final Set<Espaco> espacos;

  const _ExerciseQuickSetup({
    required this.label,
    required this.icon,
    required this.modalidade,
    required this.dificuldade,
    required this.padraoMovimento,
    required this.equipamentos,
    required this.espacos,
  });
}

const _quickSetups = [
  _ExerciseQuickSetup(
    label: 'Academia',
    icon: Icons.apartment_rounded,
    modalidade: Modalidade.musculacao,
    dificuldade: Dificuldade.iniciante,
    padraoMovimento: null,
    equipamentos: {
      Equipamento.halter,
      Equipamento.barra,
      Equipamento.maquina,
      Equipamento.polia,
      Equipamento.banco,
    },
    espacos: {Espaco.academiaCompleta, Espaco.academiaBasica},
  ),
  _ExerciseQuickSetup(
    label: 'Casa',
    icon: Icons.home_work_rounded,
    modalidade: Modalidade.musculacao,
    dificuldade: Dificuldade.iniciante,
    padraoMovimento: null,
    equipamentos: {
      Equipamento.halter,
      Equipamento.kettlebell,
      Equipamento.banda,
      Equipamento.pesoCorporal,
    },
    espacos: {Espaco.casaEquipada},
  ),
  _ExerciseQuickSetup(
    label: 'Peso corporal',
    icon: Icons.accessibility_new_rounded,
    modalidade: Modalidade.musculacao,
    dificuldade: Dificuldade.iniciante,
    padraoMovimento: null,
    equipamentos: {Equipamento.pesoCorporal},
    espacos: {Espaco.casaSemEquipo, Espaco.outdoor},
  ),
  _ExerciseQuickSetup(
    label: 'Mobilidade',
    icon: Icons.self_improvement_rounded,
    modalidade: Modalidade.mobilidade,
    dificuldade: Dificuldade.iniciante,
    padraoMovimento: PadraoMovimento.mobilidadeDinamica,
    equipamentos: {Equipamento.pesoCorporal, Equipamento.banda},
    espacos: {Espaco.academiaCompleta, Espaco.casaEquipada},
  ),
];

class _QuickSetupStrip extends StatelessWidget {
  final String? selectedLabel;
  final ValueChanged<_ExerciseQuickSetup> onSelected;

  const _QuickSetupStrip({
    required this.selectedLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perfil rápido',
          style: TextStyle(
            color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final setup in _quickSetups)
              FilterChip(
                avatar: Icon(
                  setup.icon,
                  color: selectedLabel == setup.label ? Colors.white : primary,
                  size: 16,
                ),
                label: Text(setup.label),
                selected: selectedLabel == setup.label,
                onSelected: (_) => onSelected(setup),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                labelStyle: TextStyle(
                  color: selectedLabel == setup.label ? Colors.white : primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
                side: BorderSide(color: primary.withValues(alpha: 0.16)),
                selectedColor: primary,
                backgroundColor:
                    isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : primary.withValues(alpha: 0.06),
              ),
          ],
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final bool expanded;
  final VoidCallback? onToggle;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.expanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (onToggle != null) ...[
          const SizedBox(width: 8),
          Icon(
            expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
          ),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? EagleTokens.darkLine : EagleTokens.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onToggle == null)
            header
          else
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: header,
              ),
            ),
          if (expanded) ...[const SizedBox(height: 14), child],
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final String? Function(String?)? validator;

  const _TextInput({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor:
            Theme.of(context).brightness == Brightness.dark
                ? EagleTokens.darkCard
                : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? EagleTokens.darkLine
                    : EagleTokens.line,
          ),
        ),
      ),
    );
  }
}

class _EnumDropdown<T extends Enum> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> values;
  final Map<T, String> labels;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final double? menuMaxHeight;

  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labels,
    required this.onChanged,
    this.validator,
    this.menuMaxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? EagleTokens.darkCard : Colors.white;
    final borderColor = isDark ? EagleTokens.darkLine : EagleTokens.line;
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (state) {
        final effectiveValue = value ?? state.value;
        final selectedLabel =
            effectiveValue == null
                ? label
                : labels[effectiveValue] ?? effectiveValue.backendName;
        return InkWell(
          onTap: () async {
            final picked = await showModalBottomSheet<T>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder:
                  (context) => _EnumPickerSheet<T>(
                    title: label,
                    values: values,
                    labels: labels,
                    selected: effectiveValue,
                    maxHeight: menuMaxHeight ?? 420,
                  ),
            );
            if (picked != null) {
              state.didChange(picked);
              onChanged(picked);
            }
          },
          borderRadius: BorderRadius.circular(15),
          child: InputDecorator(
            isEmpty: effectiveValue == null,
            decoration: InputDecoration(
              labelText: label,
              errorText: state.errorText,
              filled: true,
              fillColor: fillColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          effectiveValue == null
                              ? (isDark
                                  ? EagleTokens.darkInkMute
                                  : EagleTokens.inkMute)
                              : (isDark
                                  ? EagleTokens.darkInk
                                  : EagleTokens.ink),
                      fontWeight:
                          effectiveValue == null
                              ? FontWeight.w500
                              : FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EnumPickerSheet<T extends Enum> extends StatefulWidget {
  final String title;
  final List<T> values;
  final Map<T, String> labels;
  final T? selected;
  final double maxHeight;

  const _EnumPickerSheet({
    required this.title,
    required this.values,
    required this.labels,
    required this.selected,
    required this.maxHeight,
  });

  @override
  State<_EnumPickerSheet<T>> createState() => _EnumPickerSheetState<T>();
}

class _EnumPickerSheetState<T extends Enum> extends State<_EnumPickerSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkCardHi : Colors.white;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primary = Theme.of(context).colorScheme.primary;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final filtered =
        widget.values.where((item) {
          final label = widget.labels[item] ?? item.backendName;
          return label.toLowerCase().contains(_query.toLowerCase().trim());
        }).toList();

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          margin: const EdgeInsets.all(10),
          padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottom),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? EagleTokens.darkLine : EagleTokens.line,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.12),
                blurRadius: 28,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.16)
                          : EagleTokens.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${filtered.length}',
                    style: TextStyle(
                      color: primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              if (widget.values.length > 8) ...[
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar opção',
                    prefixIcon: Icon(Icons.search_rounded, color: mute),
                    filled: true,
                    fillColor:
                        isDark ? EagleTokens.darkCard : EagleTokens.paper,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? EagleTokens.darkLine : EagleTokens.line,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder:
                      (_, __) => Divider(
                        height: 1,
                        color:
                            isDark
                                ? EagleTokens.darkLine
                                : EagleTokens.line.withValues(alpha: 0.72),
                      ),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final selected = item == widget.selected;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      minLeadingWidth: 28,
                      leading: Icon(
                        selected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: selected ? primary : mute,
                        size: 21,
                      ),
                      title: Text(
                        widget.labels[item] ?? item.backendName,
                        style: TextStyle(
                          color: ink,
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w700,
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(item),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceGroup<T extends Enum> extends StatelessWidget {
  final List<T> values;
  final Set<T> selected;
  final Map<T, String> labels;
  final ValueChanged<T> onToggle;

  const _ChoiceGroup({
    required this.values,
    required this.selected,
    required this.labels,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(labels[value] ?? value.backendName),
            selected: selected.contains(value),
            onSelected: (_) => onToggle(value),
            showCheckmark: true,
            checkmarkColor: primary,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            labelStyle: TextStyle(
              color:
                  selected.contains(value)
                      ? primary
                      : Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(
              color:
                  selected.contains(value)
                      ? primary.withValues(alpha: 0.18)
                      : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
      ],
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String label;
  final int count;

  const _GroupLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final mute =
        Theme.of(context).brightness == Brightness.dark
            ? EagleTokens.darkInkMute
            : EagleTokens.inkMute;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: mute,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (count > 0)
          Text(
            '$count selecionado${count == 1 ? '' : 's'}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? EagleTokens.darkLine : EagleTokens.line,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color:
                          isDark
                              ? EagleTokens.darkInkMute
                              : EagleTokens.inkMute,
                      fontSize: 11.5,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
