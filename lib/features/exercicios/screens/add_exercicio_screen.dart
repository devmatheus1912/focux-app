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
  final Set<Equipamento> _equipamentos = {};
  final Set<Espaco> _espacos = {Espaco.academiaCompleta};
  bool _unilateral = false;
  bool _loading = false;
  String? _error;

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
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
                        'Novo Exercicio',
                        style: TextStyle(
                          fontSize: 28,
                          color: ink,
                          fontWeight: FontWeight.w800,
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionCard(
                        title: 'Essencial',
                        child: Column(
                          children: [
                            _TextInput(
                              controller: _nomeCtrl,
                              label: 'Nome do exercicio',
                              validator:
                                  (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Informe o nome'
                                          : null,
                            ),
                            const SizedBox(height: 12),
                            _EnumDropdown<Modalidade>(
                              label: 'Modalidade',
                              value: _modalidade,
                              values: Modalidade.values,
                              labels: TaxonomyLabels.modalidade,
                              onChanged: (v) => setState(() => _modalidade = v),
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
                            _EnumDropdown<PadraoMovimento>(
                              label: 'Padrao de movimento',
                              value: _padraoMovimento,
                              values: PadraoMovimento.values,
                              labels: TaxonomyLabels.padrao,
                              onChanged:
                                  (v) => setState(() => _padraoMovimento = v),
                            ),
                            const SizedBox(height: 12),
                            _EnumDropdown<Dificuldade>(
                              label: 'Dificuldade',
                              value: _dificuldade,
                              values: Dificuldade.values,
                              labels: TaxonomyLabels.dificuldade,
                              onChanged:
                                  (v) => setState(() => _dificuldade = v),
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: _unilateral,
                              title: const Text('Unilateral'),
                              onChanged: (v) => setState(() => _unilateral = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: 'Onde usa',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                            Text(
                              'Espacos',
                              style: TextStyle(
                                color: mute,
                                fontWeight: FontWeight.w800,
                              ),
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
                        title: 'Orientacao',
                        child: Column(
                          children: [
                            _TextInput(
                              controller: _descricaoCtrl,
                              label: 'Descricao curta',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            _TextInput(
                              controller: _errosComunsCtrl,
                              label: 'Erros comuns',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            _TextInput(
                              controller: _contraindicacoesCtrl,
                              label: 'Contraindicacoes',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: EagleTokens.bad,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
                                    'Cadastrar exercicio',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final String? Function(String?)? validator;

  const _TextInput({
    required this.controller,
    required this.label,
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
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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

  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.labels,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      validator: validator,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: [
        for (final item in values)
          DropdownMenuItem<T>(
            value: item,
            child: Text(labels[item] ?? item.backendName),
          ),
      ],
      onChanged: onChanged,
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          FilterChip(
            label: Text(labels[value] ?? value.backendName),
            selected: selected.contains(value),
            onSelected: (_) => onToggle(value),
          ),
      ],
    );
  }
}
