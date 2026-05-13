import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/treinos_provider.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';

const _niveis = ['INICIANTE', 'INTERMEDIARIO', 'AVANCADO'];
const _niveisLabel = ['Iniciante', 'Intermediário', 'Avançado'];
const _niveisIcon = [
  Icons.eco_rounded,
  Icons.speed_rounded,
  Icons.local_fire_department_rounded,
];
const _niveisCor = [EagleTokens.good, EagleTokens.warn, EagleTokens.bad];

const _objetivoPresets = [
  _TreinoPreset('Hipertrofia', 'Volume e carga', Icons.trending_up_rounded),
  _TreinoPreset('Emagrecimento', 'Ritmo e aderência', Icons.bolt_rounded),
  _TreinoPreset('Força', 'Base e progressão', Icons.fitness_center_rounded),
  _TreinoPreset('Condicionamento', 'Capacidade geral', Icons.speed_rounded),
];

class CreateTreinoScreen extends ConsumerStatefulWidget {
  final int? alunoId;
  final String? alunoNome;

  const CreateTreinoScreen({super.key, this.alunoId, this.alunoNome});

  @override
  ConsumerState<CreateTreinoScreen> createState() => _CreateTreinoScreenState();
}

class _CreateTreinoScreenState extends ConsumerState<CreateTreinoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController();
  String? _nivel;
  bool _loading = false;
  String? _error;

  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _nomeCtrl.addListener(_onFormChanged);
    _objetivoCtrl.addListener(_onFormChanged);
    _descricaoCtrl.addListener(_onFormChanged);
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _objetivoCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      final treino = await ref
          .read(treinoRepositoryProvider)
          .criar(
            _nomeCtrl.text.trim(),
            _descricaoCtrl.text.trim(),
            _objetivoCtrl.text.trim(),
            _nivel,
          );
      if (widget.alunoId != null) {
        await ref
            .read(treinoRepositoryProvider)
            .atribuirAluno(treino.id, widget.alunoId!);
        ref.invalidate(treinosDoAlunoProvider(widget.alunoId!));
      }
      ref.invalidate(treinosProvider);
      ref.invalidate(treinoProvider(treino.id));
      if (mounted) {
        HapticFeedback.heavyImpact();
        context.pop(true);
      }
    } catch (e) {
      String msg = 'Erro ao criar treino.';
      if (e is DioException) {
        final data = e.response?.data;
        final serverMsg =
            data is Map
                ? data['mensagem'] ?? data['message'] ?? data['erro']
                : null;
        if (serverMsg != null) msg = serverMsg.toString();
      }
      if (mounted) {
        setState(() {
          _error = msg;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _applyPreset(_TreinoPreset preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _objetivoCtrl.text = preset.title;
      if (_nomeCtrl.text.trim().isEmpty) {
        _nomeCtrl.text = 'Treino ${preset.title}';
      }
      _nivel ??= 'INTERMEDIARIO';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final canSubmit = _nomeCtrl.text.trim().isNotEmpty && !_loading;
    final previewTitle =
        _nomeCtrl.text.trim().isEmpty
            ? 'Plano sem nome'
            : _nomeCtrl.text.trim();
    final previewGoal =
        _objetivoCtrl.text.trim().isEmpty
            ? 'Escolha um objetivo'
            : _objetivoCtrl.text.trim();
    final previewLevel =
        _nivel == null
            ? 'Nível em aberto'
            : _niveisLabel[_niveis.indexOf(_nivel!)];

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.alunoId == null
                            ? 'PLANO BASE'
                            : 'PLANO DO ALUNO',
                        style: TextStyle(
                          fontSize: 12,
                          color: primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.alunoId == null
                            ? 'Novo Treino'
                            : 'Treino vinculado',
                        style: TextStyle(
                          fontSize: 28,
                          color: ink,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: mute),
                    onPressed: () => context.pop(),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          isDark ? EagleTokens.darkCard : EagleTokens.card,
                      side: BorderSide(
                        color:
                            isDark
                                ? EagleTokens.darkLine
                                : EagleTokens.lineSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entryCtrl,
                  curve: Curves.easeOut,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CreationHero(
                          title: previewTitle,
                          goal: previewGoal,
                          level: previewLevel,
                          isDark: isDark,
                          primary: primary,
                        ),
                        const SizedBox(height: 18),
                        _SectionKicker(
                          title: 'Comece por um modelo',
                          action:
                              widget.alunoId == null
                                  ? 'Biblioteca'
                                  : widget.alunoNome ?? 'Aluno',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _PresetRail(
                          presets: _objetivoPresets,
                          selected: _objetivoCtrl.text.trim(),
                          isDark: isDark,
                          primary: primary,
                          onTap: _applyPreset,
                        ),
                        const SizedBox(height: 20),
                        _SectionKicker(
                          title: 'Dados essenciais',
                          action: canSubmit ? 'Pronto' : 'Nome obrigatório',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _FxField(
                          controller: _nomeCtrl,
                          label: 'Nome do treino',
                          icon: Icons.edit_outlined,
                          isDark: isDark,
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Informe o nome'
                                      : null,
                        ),
                        const SizedBox(height: 16),
                        _LevelSelector(
                          selected: _nivel,
                          isDark: isDark,
                          onChanged: (value) => setState(() => _nivel = value),
                        ),
                        const SizedBox(height: 18),
                        _FxField(
                          controller: _objetivoCtrl,
                          label: 'Objetivo (opcional)',
                          icon: Icons.flag_outlined,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _FxField(
                          controller: _descricaoCtrl,
                          label: 'Descrição (opcional)',
                          icon: Icons.notes_rounded,
                          isDark: isDark,
                          maxLines: 2,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          _ErrorNotice(message: _error!),
                        ],
                        const SizedBox(height: 26),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed: canSubmit ? _submit : null,
                            icon:
                                _loading
                                    ? const SizedBox.shrink()
                                    : const Icon(Icons.add_rounded, size: 20),
                            label:
                                _loading
                                    ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: FxLoading(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text(
                                      'Criar treino',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  isDark
                                      ? EagleTokens.darkCardHi
                                      : EagleTokens.lineSoft,
                              disabledForegroundColor: mute,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _CreationHero extends StatelessWidget {
  final String title;
  final String goal;
  final String level;
  final bool isDark;
  final Color primary;

  const _CreationHero({
    required this.title,
    required this.goal,
    required this.level,
    required this.isDark,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final primaryDeep = BrandPalette.deep(primary);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, primaryDeep],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.12 : 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
            spreadRadius: -18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Criação guiada',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.25,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Monte a base agora. Os exercícios entram no próximo passo.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12.2,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _HeroPill(label: goal, icon: Icons.flag_rounded)),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroPill(label: level, icon: Icons.tune_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HeroPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.82), size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionKicker extends StatelessWidget {
  final String title;
  final String action;
  final bool isDark;

  const _SectionKicker({
    required this.title,
    required this.action,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.15,
            ),
          ),
        ),
        Text(
          action,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: mute,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PresetRail extends StatelessWidget {
  final List<_TreinoPreset> presets;
  final String selected;
  final bool isDark;
  final Color primary;
  final ValueChanged<_TreinoPreset> onTap;

  const _PresetRail({
    required this.presets,
    required this.selected,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final preset = presets[index];
          final active = selected == preset.title;
          return GestureDetector(
            onTap: () => onTap(preset),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 142,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    active
                        ? BrandPalette.soft(primary, dark: isDark)
                        : (isDark ? EagleTokens.darkCard : EagleTokens.card),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      active
                          ? primary.withValues(alpha: 0.38)
                          : (isDark
                              ? EagleTokens.darkLine
                              : EagleTokens.lineSoft),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    preset.icon,
                    color: active ? primary : EagleTokens.inkMute,
                    size: 20,
                  ),
                  const Spacer(),
                  Text(
                    preset.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    preset.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          isDark
                              ? EagleTokens.darkInkMute
                              : EagleTokens.inkMute,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
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

class _LevelSelector extends StatelessWidget {
  final String? selected;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _LevelSelector({
    required this.selected,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final sel = selected == _niveis[i];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(_niveis[i]);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
              decoration: BoxDecoration(
                color:
                    sel
                        ? _niveisCor[i].withValues(alpha: 0.11)
                        : (isDark ? EagleTokens.darkCard : EagleTokens.card),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      sel
                          ? _niveisCor[i].withValues(alpha: 0.38)
                          : (isDark
                              ? EagleTokens.darkLine
                              : EagleTokens.lineSoft),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _niveisIcon[i],
                    color:
                        sel
                            ? _niveisCor[i]
                            : (isDark
                                ? EagleTokens.darkInkMute
                                : EagleTokens.inkMute),
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      _niveisLabel[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            sel
                                ? _niveisCor[i]
                                : (isDark
                                    ? EagleTokens.darkInkMute
                                    : EagleTokens.inkMute),
                        fontSize: 11,
                        fontWeight: sel ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  final String message;

  const _ErrorNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: EagleTokens.bad.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: EagleTokens.bad, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: EagleTokens.bad,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FxField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final int maxLines;
  final String? Function(String?)? validator;

  const _FxField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(
        color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      cursorColor: primary,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          size: 20,
          color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
        ),
        filled: true,
        fillColor: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
        labelStyle: TextStyle(
          color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
          ),
        ),
        enabledBorder: FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
          ),
        ),
        focusedBorder: FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary.withValues(alpha: 0.68)),
        ),
        errorBorder: FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: EagleTokens.bad),
        ),
        errorStyle: const TextStyle(
          color: EagleTokens.bad,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TreinoPreset {
  final String title;
  final String subtitle;
  final IconData icon;

  const _TreinoPreset(this.title, this.subtitle, this.icon);
}
