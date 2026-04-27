import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/exercicios_provider.dart';

const _gruposMusculares = [
  'PEITO', 'COSTAS', 'OMBROS', 'BICEPS',
  'TRICEPS', 'PERNAS', 'ABDOMEN', 'CARDIO',
];

const _categoriasExercicio = [
  'Musculação',
  'Mobilidade',
  'Lutas',
  'Yoga',
  'Funcional',
  'Cardio',
  'Outro',
];

const _equipamentosExercicio = [
  'Peso corporal',
  'Halteres',
  'Barra',
  'Maquina',
  'Cabo',
  'Elastico',
  'Kettlebell',
  'Cardio',
  'Outro',
];

const _niveisExercicio = ['Iniciante', 'Intermediario', 'Avancado'];

const _mecanicasExercicio = ['Composto', 'Isolado', 'Mobilidade', 'Cardio'];

const _objetivosExercicio = [
  'Forca',
  'Hipertrofia',
  'Emagrecimento',
  'Condicionamento',
  'Mobilidade',
  'Reabilitacao',
];

class AddExercicioScreen extends ConsumerStatefulWidget {
  const AddExercicioScreen({super.key});

  @override
  ConsumerState<AddExercicioScreen> createState() => _AddExercicioScreenState();
}

class _AddExercicioScreenState extends ConsumerState<AddExercicioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  String? _musculoAlvo;
  String? _categoria;
  String? _equipamento;
  String? _nivel;
  String? _mecanica;
  String? _objetivo;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _tagsCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(exercicioRepositoryProvider).criar(
            nome: _nomeCtrl.text.trim(),
            descricao: _descricaoCtrl.text.trim(),
            musculoAlvo: _musculoAlvo,
            categoria: _categoria,
            equipamento: _equipamento,
            nivel: _nivel,
            mecanica: _mecanica,
            objetivo: _objetivo,
            tags: _tagsCtrl.text.trim(),
            observacoes: _obsCtrl.text.trim(),
          );
      if (mounted) context.pop(true);
    } catch (e) {
      setState(() {
        _error = 'Erro ao cadastrar exercício.';
      });
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
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Novo Exercício',
                        style: TextStyle(
                          fontSize: 28,
                          color: ink,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
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
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nomeCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nome do exercício',
                          filled: true,
                          fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                        ),
                        style: TextStyle(color: ink),
                        validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _musculoAlvo,
                        decoration: InputDecoration(
                          labelText: 'Músculo alvo',
                          filled: true,
                          fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                        ),
                        items: _gruposMusculares
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: TextStyle(color: ink)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _musculoAlvo = v),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _categoria,
                        decoration: InputDecoration(
                          labelText: 'Categoria',
                          filled: true,
                          fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                        ),
                        items: _categoriasExercicio
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: TextStyle(color: ink)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _categoria = v),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _equipamento,
                        decoration: InputDecoration(
                          labelText: 'Equipamento',
                          filled: true,
                          fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                        ),
                        items: _equipamentosExercicio
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: TextStyle(color: ink)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _equipamento = v),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _nivel,
                              decoration: InputDecoration(
                                labelText: 'Nivel',
                                filled: true,
                                fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                                ),
                              ),
                              items: _niveisExercicio
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c, style: TextStyle(color: ink)),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _nivel = v),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _mecanica,
                              decoration: InputDecoration(
                                labelText: 'Mecanica',
                                filled: true,
                                fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                                ),
                              ),
                              items: _mecanicasExercicio
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c, style: TextStyle(color: ink)),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => _mecanica = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _objetivo,
                        decoration: InputDecoration(
                          labelText: 'Objetivo principal',
                          filled: true,
                          fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                        ),
                        items: _objetivosExercicio
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: TextStyle(color: ink)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _objetivo = v),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tagsCtrl,
                        decoration: InputDecoration(
                          labelText: 'Tags (opcional)',
                          hintText: 'Ex: #EmCasa,#SemEquipamento',
                          filled: true,
                          fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                        ),
                        style: TextStyle(color: ink),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descricaoCtrl,
                        decoration: InputDecoration(
                          labelText: 'Descrição (opcional)',
                          filled: true,
                          fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                        ),
                        style: TextStyle(color: ink),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _obsCtrl,
                        decoration: InputDecoration(
                          labelText: 'Observações (opcional)',
                          filled: true,
                          fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? EagleTokens.darkLine : EagleTokens.line),
                          ),
                        ),
                        style: TextStyle(color: ink),
                        maxLines: 3,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: EagleTokens.bad.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: EagleTokens.bad, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: EagleTokens.bad, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EagleTokens.brand,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: EagleTokens.brand.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text('Cadastrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
