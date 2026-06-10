import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_premium_entrance.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/aluno_repository.dart';
import '../providers/aluno_detail_providers.dart';
import '../providers/aluno_followup_provider.dart';
import '../providers/alunos_provider.dart';

class EditarAlunoScreen extends ConsumerStatefulWidget {
  final Aluno aluno;
  const EditarAlunoScreen({super.key, required this.aluno});

  @override
  ConsumerState<EditarAlunoScreen> createState() => _EditarAlunoScreenState();
}

class _EditarAlunoScreenState extends ConsumerState<EditarAlunoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _telefone;
  late final TextEditingController _whatsapp;
  late final TextEditingController _objetivo;
  String? _genero;
  String? _tipoConsultoria;
  bool _salvando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.aluno.nome);
    _email = TextEditingController(text: widget.aluno.email);
    _telefone = TextEditingController(text: widget.aluno.telefone ?? '');
    _whatsapp = TextEditingController(text: widget.aluno.whatsapp ?? '');
    _objetivo = TextEditingController(text: widget.aluno.objetivo ?? '');
    _genero = widget.aluno.genero;
    _tipoConsultoria = widget.aluno.tipoConsultoria ?? 'ONLINE';
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _whatsapp.dispose();
    _objetivo.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _salvando = true;
      _error = null;
    });
    try {
      final repo = AlunoRepository(ref.read(apiClientProvider));
      await repo.atualizarAluno(widget.aluno.id, {
        'nome': _nome.text.trim(),
        'email': _email.text.trim(),
        'telefone':
            _telefone.text.trim().isEmpty ? null : _telefone.text.trim(),
        'whatsapp':
            _whatsapp.text.trim().isEmpty ? null : _whatsapp.text.trim(),
        'objetivo':
            _objetivo.text.trim().isEmpty ? null : _objetivo.text.trim(),
        'genero': _genero,
        'tipoConsultoria': _tipoConsultoria ?? 'ONLINE',
      });
      if (!mounted) return;
      ref.invalidate(alunosProvider);
      ref.invalidate(alunosStatsProvider);
      await invalidateAluno360Providers(ref, widget.aluno.id);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      FeedbackHelper.showSuccess(context, 'Aluno atualizado!');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = friendlyError(
            e,
            fallback: 'Erro ao salvar. Tente novamente.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final chrome = ShellChrome.forDark(isDark);

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Editar Aluno',
        subtitle: 'ALUNO',
        onBack: () => safePopOrGo(context, '/alunos/${widget.aluno.id}'),
      ),
      bottomNavigationBar: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? EagleTokens.darkCard : TokensStrip.cardBg)
                .withValues(alpha: 0.96),
            border: Border(top: BorderSide(color: chrome.line)),
          ),
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s5,
            12,
            TokensStrip.s5,
            12,
          ),
          child: SafeArea(
            top: false,
            child: Semantics(
              button: true,
              enabled: !_salvando,
              label:
                  _salvando
                      ? 'Salvando alterações do aluno'
                      : 'Salvar alterações do aluno',
              child: FxLiquidPrimaryButton(
                label: 'Salvar alterações',
                loadingLabel: 'Salvando…',
                loading: _salvando,
                onPressed: _salvando ? null : _salvar,
              ),
            ),
          ),
        ),
      ),
      body: FxPremiumEntrance(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              TokensStrip.s5,
              8,
              TokensStrip.s5,
              24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ListenableBuilder(
                    listenable: Listenable.merge([_nome, _objetivo]),
                    builder: (context, _) {
                      final displayName =
                          _nome.text.trim().isEmpty
                              ? widget.aluno.nome
                              : _nome.text.trim();
                      final objetivoPreview =
                          _objetivo.text.trim().isNotEmpty
                              ? _objetivo.text.trim()
                              : (widget.aluno.objetivo ?? '').trim();
                      return Semantics(
                        label: 'Aluno $displayName',
                        child: Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: primary.withValues(
                                  alpha: 0.12,
                                ),
                                child: Text(
                                  fxInitials(displayName),
                                  style: AppTypography.inter(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: AppTypography.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isDark
                                          ? EagleTokens.darkInk
                                          : TokensStrip.textPrimary,
                                ),
                              ),
                              if (objetivoPreview.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    objetivoPreview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: mute,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  FxStaggerItem(
                    index: 0,
                    child: _SectionCard(
                      title: 'Informações básicas',
                      showHint: true,
                      hint:
                          'Contato e identificação usados no atendimento e no Copiloto.',
                      child: Column(
                        children: [
                          Semantics(
                            label: 'Nome completo obrigatório',
                            child: TextFormField(
                              controller: _nome,
                              textCapitalization: TextCapitalization.words,
                              decoration: FxInputDeco.build(
                                context,
                                'Nome completo *',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator:
                                  (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Informe o nome'
                                          : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            label: 'E-mail obrigatório',
                            child: TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: FxInputDeco.build(
                                context,
                                'E-mail *',
                                icon: Icons.alternate_email_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Informe o e-mail';
                                }
                                if (!v.contains('@')) {
                                  return 'E-mail inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            label: 'Telefone opcional',
                            child: TextFormField(
                              controller: _telefone,
                              keyboardType: TextInputType.phone,
                              decoration: FxInputDeco.build(
                                context,
                                'Telefone',
                                icon: Icons.phone_outlined,
                                hint: 'DDD + número',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Semantics(
                            label: 'WhatsApp opcional',
                            child: TextFormField(
                              controller: _whatsapp,
                              keyboardType: TextInputType.phone,
                              decoration: FxInputDeco.build(
                                context,
                                'WhatsApp',
                                icon: Icons.chat_bubble_outline_rounded,
                                hint: 'DDD + número',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FxStaggerItem(
                    index: 1,
                    child: _SectionCard(
                      title: 'Perfil do aluno',
                      hint:
                          'Objetivo, gênero e consultoria alimentam prescrição e Copiloto.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            label: 'Objetivo do aluno',
                            child: TextFormField(
                              controller: _objetivo,
                              maxLines: 2,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: FxInputDeco.build(
                                context,
                                'Objetivo',
                                icon: Icons.flag_outlined,
                                hint: 'Ex: Hipertrofia, emagrecimento',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ChipGroup(
                            label: 'Gênero',
                            options: const [
                              _ChipOption(value: 'MASCULINO', label: 'Masculino'),
                              _ChipOption(value: 'FEMININO', label: 'Feminino'),
                              _ChipOption(value: 'OUTRO', label: 'Outro'),
                            ],
                            selected: _genero,
                            onSelected: (value) => setState(() => _genero = value),
                          ),
                          const SizedBox(height: 14),
                          _ChipGroup(
                            label: 'Consultoria',
                            options: const [
                              _ChipOption(value: 'ONLINE', label: 'Online'),
                              _ChipOption(
                                value: 'PRESENCIAL',
                                label: 'Presencial',
                              ),
                              _ChipOption(value: 'HIBRIDO', label: 'Híbrido'),
                            ],
                            selected: _tipoConsultoria,
                            onSelected:
                                (value) =>
                                    setState(() => _tipoConsultoria = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      label: _error!,
                      child: Text(
                        _error!,
                        style: const TextStyle(color: EagleTokens.bad),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipOption {
  const _ChipOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<_ChipOption> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: mute,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                options.map((option) {
                  final sel = selected == option.value;
                  return Semantics(
                    button: true,
                    selected: sel,
                    label: '${option.label}${sel ? ', selecionado' : ''}',
                    child: ChoiceChip(
                      label: Text(option.label),
                      selected: sel,
                      onSelected: (_) => onSelected(option.value),
                      selectedColor: primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color:
                            sel
                                ? primary
                                : (isDark
                                    ? EagleTokens.darkInkMute
                                    : TokensStrip.textSecondary),
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color:
                            sel
                                ? primary.withValues(alpha: 0.42)
                                : (isDark
                                    ? EagleTokens.darkLine
                                    : TokensStrip.borderDefault),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.showHint = false,
    this.hint,
  });

  final String title;
  final Widget child;
  final bool showHint;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final a11y =
        showHint && hint != null ? '$title. $hint' : title;

    return Semantics(
      container: true,
      label: a11y,
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s4),
        decoration: fxListCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.inter(
                color: ink,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            if (showHint && hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint!,
                style: TextStyle(color: mute, fontSize: 11.5, height: 1.3),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
