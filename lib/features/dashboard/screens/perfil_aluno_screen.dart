import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../anamnese/data/anamnese_repository.dart';
import '../../auth/providers/auth_provider.dart';

class PerfilAlunoScreen extends ConsumerStatefulWidget {
  const PerfilAlunoScreen({super.key});

  @override
  ConsumerState<PerfilAlunoScreen> createState() => _PerfilAlunoScreenState();
}

class _PerfilAlunoScreenState extends ConsumerState<PerfilAlunoScreen> {
  static const _niveisAtividade = [
    ('SEDENTARIO', 'Sedentario'),
    ('LEVE', 'Leve'),
    ('MODERADO', 'Moderado'),
    ('INTENSO', 'Intenso'),
    ('MUITO_INTENSO', 'Muito intenso'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _objetivo = TextEditingController();
  final _objetivoDetalhado = TextEditingController();
  final _genero = TextEditingController();
  final _tipoConsultoria = TextEditingController();
  final _peso = TextEditingController();
  final _altura = TextEditingController();
  final _dataNascimento = TextEditingController();
  final _lesoes = TextEditingController();
  final _medicamentos = TextEditingController();
  final _historicoMedico = TextEditingController();
  final _cirurgias = TextEditingController();
  final _doresCronicas = TextEditingController();
  final _preferenciasTreino = TextEditingController();
  final _restricoesAlimentares = TextEditingController();
  final _observacoes = TextEditingController();

  String? _fotoUrl;
  String? _nivelAtividade;
  int _disponibilidadeSemanal = 3;
  bool _loaded = false;
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _whatsapp.dispose();
    _objetivo.dispose();
    _objetivoDetalhado.dispose();
    _genero.dispose();
    _tipoConsultoria.dispose();
    _peso.dispose();
    _altura.dispose();
    _dataNascimento.dispose();
    _lesoes.dispose();
    _medicamentos.dispose();
    _historicoMedico.dispose();
    _cirurgias.dispose();
    _doresCronicas.dispose();
    _preferenciasTreino.dispose();
    _restricoesAlimentares.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  Future<void> _loadIfNeeded(Aluno aluno) async {
    if (_loaded) return;
    _loaded = true;
    _nome.text = aluno.nome;
    _email.text = aluno.email;
    _telefone.text = aluno.telefone ?? '';
    _whatsapp.text = aluno.whatsapp ?? '';
    _objetivo.text = aluno.objetivo ?? '';
    _genero.text = aluno.genero ?? '';
    _tipoConsultoria.text = aluno.tipoConsultoria ?? '';
    _peso.text = aluno.peso?.toString() ?? '';
    _altura.text = aluno.altura?.toString() ?? '';
    _dataNascimento.text = aluno.dataNascimento ?? '';
    _fotoUrl = aluno.fotoUrl;

    try {
      final anamnese =
          await AnamneseRepository(ref.read(apiClientProvider)).buscarMinha();
      if (!mounted) return;
      setState(() {
        _objetivo.text = _objetivo.text.trim().isNotEmpty
            ? _objetivo.text
            : (anamnese.objetivo ?? '');
        _nivelAtividade = anamnese.nivelAtividade;
        _lesoes.text = anamnese.lesoes ?? '';
        _medicamentos.text = anamnese.medicamentos ?? '';
        _historicoMedico.text = anamnese.historicoMedico ?? '';
        _cirurgias.text = anamnese.cirurgias ?? '';
        _doresCronicas.text = anamnese.doresCronicas ?? '';
        _objetivoDetalhado.text = anamnese.objetivoDetalhado ?? '';
        _disponibilidadeSemanal = anamnese.disponibilidadeSemanal ?? 3;
        _preferenciasTreino.text = anamnese.preferenciasTreino ?? '';
        _restricoesAlimentares.text = anamnese.restricoesAlimentares ?? '';
        _observacoes.text = anamnese.observacoes ?? '';
      });
    } catch (_) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _pickFoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final url = await MediaUploadService(ref.read(apiClientProvider)).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: 'alunos/fotos',
        resourceType: 'image',
      );
      if (!mounted) return;
      setState(() => _fotoUrl = url);
      await _save(silent: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar foto: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _save({bool silent = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final alunoRepo = ref.read(alunoRepositoryProvider);
      final anamneseRepo = AnamneseRepository(ref.read(apiClientProvider));
      await alunoRepo.atualizarMe({
        'nome': _nome.text.trim(),
        'email': _email.text.trim(),
        'telefone': _telefone.text.trim(),
        'whatsapp': _whatsapp.text.trim(),
        'objetivo': _objetivo.text.trim(),
        'genero': _genero.text.trim(),
        'tipoConsultoria': _tipoConsultoria.text.trim(),
        'peso': double.tryParse(_peso.text.trim().replaceAll(',', '.')),
        'altura': double.tryParse(_altura.text.trim().replaceAll(',', '.')),
        'dataNascimento': _dataNascimento.text.trim(),
        'fotoUrl': _fotoUrl,
      });
      await anamneseRepo.salvarMinha({
        'objetivo': _objetivo.text.trim(),
        'nivelAtividade': _nivelAtividade,
        'lesoes': _lesoes.text.trim(),
        'medicamentos': _medicamentos.text.trim(),
        'observacoes': _observacoes.text.trim(),
        'historicoMedico': _historicoMedico.text.trim(),
        'cirurgias': _cirurgias.text.trim(),
        'doresCronicas': _doresCronicas.text.trim(),
        'objetivoDetalhado': _objetivoDetalhado.text.trim(),
        'disponibilidadeSemanal': _disponibilidadeSemanal,
        'preferenciasTreino': _preferenciasTreino.text.trim(),
        'restricoesAlimentares': _restricoesAlimentares.text.trim(),
      });
      ref.invalidate(alunoMeProvider);
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil do aluno atualizado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  int _completionScore() {
    final values = [
      _nome.text,
      _email.text,
      _objetivo.text,
      _fotoUrl ?? '',
      _whatsapp.text,
      _peso.text,
      _altura.text,
      _dataNascimento.text,
      _nivelAtividade ?? '',
      _objetivoDetalhado.text,
      _preferenciasTreino.text,
      _restricoesAlimentares.text,
    ];
    final filled = values.where((value) => value.trim().isNotEmpty).length;
    return ((filled / values.length) * 100).round();
  }

  String _metaPrincipal() {
    if (_objetivo.text.trim().isNotEmpty) return _objetivo.text.trim();
    return 'Definir objetivo principal';
  }

  String _disponibilidadeLabel() {
    return '$_disponibilidadeSemanal dias por semana';
  }

  List<Widget> _summaryChips(Aluno aluno, bool isDark) {
    final chips = <Widget>[
      _ProfileChip(
        icon: Icons.flag_outlined,
        label: _metaPrincipal(),
        isDark: isDark,
      ),
      _ProfileChip(
        icon: Icons.calendar_today_outlined,
        label: _disponibilidadeLabel(),
        isDark: isDark,
      ),
    ];
    if (aluno.idade != null) {
      chips.add(
        _ProfileChip(
          icon: Icons.cake_outlined,
          label: '${aluno.idade} anos',
          isDark: isDark,
        ),
      );
    }
    if (_peso.text.trim().isNotEmpty) {
      chips.add(
        _ProfileChip(
          icon: Icons.monitor_weight_outlined,
          label: '${_peso.text.trim()} kg',
          isDark: isDark,
        ),
      );
    }
    if (_altura.text.trim().isNotEmpty) {
      chips.add(
        _ProfileChip(
          icon: Icons.height,
          label: '${_altura.text.trim()} m',
          isDark: isDark,
        ),
      );
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(alunoMeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        title: const Text('Meu perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/dashboard/aluno'),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (aluno) {
          _loadIfNeeded(aluno);
          final completion = _completionScore();
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? const [Color(0xFF132344), Color(0xFF0C1731)]
                            : const [Color(0xFFF2F6FF), Color(0xFFFFFFFF)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 38,
                                  backgroundImage:
                                      _fotoUrl != null && _fotoUrl!.isNotEmpty
                                          ? NetworkImage(_fotoUrl!)
                                          : null,
                                  backgroundColor: EagleTokens.brandSoft,
                                  child: _fotoUrl == null || _fotoUrl!.isEmpty
                                      ? Text(
                                          aluno.nome.isNotEmpty
                                              ? aluno.nome[0].toUpperCase()
                                              : 'A',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        )
                                      : null,
                                ),
                                Positioned(
                                  right: -4,
                                  bottom: -4,
                                  child: IconButton.filled(
                                    onPressed: _uploading ? null : _pickFoto,
                                    icon: _uploading
                                        ? const SizedBox(
                                            width: 15,
                                            height: 15,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            size: 16,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    aluno.nome,
                                    style: TextStyle(
                                      color: ink,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Quanto mais completo seu perfil, melhor o ajuste do treino.',
                                    style: TextStyle(
                                      color: mute,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _summaryChips(aluno, isDark),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Perfil preenchido',
                                    style: TextStyle(
                                      color: mute,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: LinearProgressIndicator(
                                      value: completion / 100,
                                      minHeight: 9,
                                      backgroundColor:
                                          EagleTokens.brand.withValues(alpha: 0.12),
                                      valueColor: const AlwaysStoppedAnimation(
                                        EagleTokens.brand,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 56,
                              height: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: EagleTokens.brand.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                '$completion%',
                                style: const TextStyle(
                                  color: EagleTokens.brand,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Identidade e contato',
                    subtitle: 'Dados basicos para contato e rotina do aluno.',
                    isDark: isDark,
                    children: [
                      _Field(
                        controller: _nome,
                        label: 'Nome',
                        icon: Icons.person_outline,
                        requiredField: true,
                      ),
                      _Field(
                        controller: _email,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        requiredField: true,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _Field(
                              controller: _telefone,
                              label: 'Telefone',
                              icon: Icons.phone_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Field(
                              controller: _whatsapp,
                              label: 'WhatsApp',
                              icon: Icons.chat_outlined,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _Field(
                              controller: _genero,
                              label: 'Genero',
                              icon: Icons.badge_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Field(
                              controller: _dataNascimento,
                              label: 'Nascimento AAAA-MM-DD',
                              icon: Icons.cake_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Corpo e metas',
                    subtitle: 'O que o aluno quer construir e de onde esta partindo.',
                    isDark: isDark,
                    children: [
                      _Field(
                        controller: _objetivo,
                        label: 'Objetivo principal',
                        icon: Icons.flag_outlined,
                        maxLines: 2,
                      ),
                      _Field(
                        controller: _objetivoDetalhado,
                        label: 'Objetivo detalhado',
                        icon: Icons.track_changes_outlined,
                        maxLines: 3,
                      ),
                      _Field(
                        controller: _tipoConsultoria,
                        label: 'Tipo de consultoria',
                        icon: Icons.fitness_center,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _Field(
                              controller: _peso,
                              label: 'Peso kg',
                              icon: Icons.monitor_weight_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Field(
                              controller: _altura,
                              label: 'Altura m',
                              icon: Icons.height,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Saude e restricoes',
                    subtitle: 'Informacoes que deixam treino e dieta mais seguros.',
                    isDark: isDark,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _nivelAtividade,
                        decoration: const InputDecoration(
                          labelText: 'Nivel de atividade',
                          prefixIcon: Icon(Icons.insights_outlined),
                        ),
                        items: _niveisAtividade
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item.$1,
                                child: Text(item.$2),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _nivelAtividade = value),
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _lesoes,
                        label: 'Lesoes ou limitacoes',
                        icon: Icons.healing_outlined,
                        maxLines: 3,
                      ),
                      _Field(
                        controller: _medicamentos,
                        label: 'Medicamentos em uso',
                        icon: Icons.medication_outlined,
                        maxLines: 2,
                      ),
                      _Field(
                        controller: _historicoMedico,
                        label: 'Historico medico',
                        icon: Icons.local_hospital_outlined,
                        maxLines: 3,
                      ),
                      _Field(
                        controller: _cirurgias,
                        label: 'Cirurgias realizadas',
                        icon: Icons.personal_injury_outlined,
                        maxLines: 2,
                      ),
                      _Field(
                        controller: _doresCronicas,
                        label: 'Dores cronicas',
                        icon: Icons.accessibility_new_outlined,
                        maxLines: 2,
                      ),
                      _Field(
                        controller: _restricoesAlimentares,
                        label: 'Restricoes alimentares',
                        icon: Icons.no_food_outlined,
                        maxLines: 2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Rotina de treino',
                    subtitle: 'Preferencias e disponibilidade para o plano fazer sentido.',
                    isDark: isDark,
                    children: [
                      Text(
                        'Disponibilidade semanal',
                        style: TextStyle(
                          color: ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        showSelectedIcon: false,
                        multiSelectionEnabled: false,
                        selected: {_disponibilidadeSemanal},
                        segments: const [
                          ButtonSegment(value: 1, label: Text('1')),
                          ButtonSegment(value: 2, label: Text('2')),
                          ButtonSegment(value: 3, label: Text('3')),
                          ButtonSegment(value: 4, label: Text('4')),
                          ButtonSegment(value: 5, label: Text('5')),
                          ButtonSegment(value: 6, label: Text('6')),
                          ButtonSegment(value: 7, label: Text('7')),
                        ],
                        onSelectionChanged: (values) => setState(
                          () => _disponibilidadeSemanal = values.first,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _preferenciasTreino,
                        label: 'Preferencias de treino',
                        icon: Icons.sports_gymnastics_outlined,
                        maxLines: 3,
                      ),
                      _Field(
                        controller: _observacoes,
                        label: 'Observacoes para o personal',
                        icon: Icons.sticky_note_2_outlined,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(
                      'Salvar meu perfil',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Esses dados ajudam o personal a ajustar treino, contato, seguranca e aderencia sem depender de conversa toda hora.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: mute, fontSize: 12, height: 1.45),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _ProfileChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : EagleTokens.brand.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: EagleTokens.brand),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool requiredField;
  final int maxLines;
  final TextInputType? keyboardType;

  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.requiredField = false,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        validator: requiredField
            ? (value) =>
                value == null || value.trim().isEmpty ? 'Obrigatorio.' : null
            : null,
      ),
    );
  }
}
