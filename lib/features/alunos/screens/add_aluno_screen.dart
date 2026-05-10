import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/design_tokens.dart';
import '../providers/alunos_provider.dart';

const _generos = ['Masculino', 'Feminino', 'Outro'];
const _tiposConsultoria = ['ONLINE', 'PRESENCIAL', 'HIBRIDO'];
const _tiposConsultoriaLabel = ['Online', 'Presencial', 'Híbrido'];
const _objetivosRapidos = [
  'Hipertrofia',
  'Emagrecimento',
  'Força',
  'Condicionamento',
];

const _emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';

class AddAlunoScreen extends ConsumerStatefulWidget {
  const AddAlunoScreen({super.key});

  @override
  ConsumerState<AddAlunoScreen> createState() => _AddAlunoScreenState();
}

class _AddAlunoScreenState extends ConsumerState<AddAlunoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();

  String? _genero;
  String? _tipoConsultoria;
  bool _loading = false;
  String? _error;

  late final AnimationController _entryCtrl;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  bool get _canSubmit {
    return _nomeCtrl.text.trim().isNotEmpty &&
        RegExp(_emailPattern).hasMatch(_emailCtrl.text.trim()) &&
        !_loading;
  }

  String get _firstName {
    final name = _nomeCtrl.text.trim();
    if (name.isEmpty) return 'Aluno';
    return name.split(RegExp(r'\s+')).first;
  }

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();

    _nomeCtrl.addListener(_refreshSubmitState);
    _emailCtrl.addListener(_refreshSubmitState);
    _objetivoCtrl.addListener(_refreshSubmitState);
    _whatsappCtrl.addListener(_refreshSubmitState);
  }

  void _refreshSubmitState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nomeCtrl
      ..removeListener(_refreshSubmitState)
      ..dispose();
    _emailCtrl
      ..removeListener(_refreshSubmitState)
      ..dispose();
    _objetivoCtrl
      ..removeListener(_refreshSubmitState)
      ..dispose();
    _whatsappCtrl
      ..removeListener(_refreshSubmitState)
      ..dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final objetivo = _objetivoCtrl.text.trim();
      final whatsapp = _whatsappCtrl.text.trim();
      final novoAluno = await ref
          .read(alunoRepositoryProvider)
          .criar(
            nome: _nomeCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            objetivo: objetivo.isEmpty ? null : objetivo,
            whatsapp: whatsapp.isEmpty ? null : whatsapp,
            genero: _genero,
            tipoConsultoria: _tipoConsultoria,
          );

      if (!mounted) return;
      if (novoAluno.senhaProvisoria != null) {
        _showSenhaBottomSheet(novoAluno);
      } else {
        HapticFeedback.heavyImpact();
        context.pop(true);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      var errorMsg = 'Não foi possível cadastrar o aluno. Revise os dados.';
      String? requestId;

      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data.containsKey('erro')) {
          errorMsg = data['erro'].toString();
        }
        if (data.containsKey('detalhes') && data['detalhes'] is Map) {
          final details = (data['detalhes'] as Map).entries
              .map((e) => '${e.key}: ${e.value}')
              .join('\n');
          errorMsg = '$errorMsg\n$details';
        }
        requestId = data['requestId']?.toString();
      }
      if (requestId != null) {
        errorMsg = '$errorMsg\n\nRef: $requestId';
      }

      if (mounted) setState(() => _error = errorMsg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSenhaBottomSheet(final aluno) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final whatsappNumber = (aluno.whatsapp as String? ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    );
    final hasWhatsapp = whatsappNumber.isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: isDark ? EagleTokens.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24 + MediaQuery.of(ctx).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: EagleTokens.good.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: EagleTokens.good,
                    size: 29,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aluno cadastrado',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Compartilhe o convite para o aluno acessar o app.',
                  style: TextStyle(
                    color:
                        isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                    fontSize: 13.4,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 15, 18, 14),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Senha provisória',
                        style: TextStyle(
                          color:
                              isDark
                                  ? EagleTokens.darkInkMute
                                  : EagleTokens.inkMute,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        aluno.senhaProvisoria!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 31,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 5.5,
                          color: isDark ? Colors.white : EagleTokens.ink,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        'O aluno deve trocar a senha no primeiro acesso.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              isDark
                                  ? EagleTokens.darkInkMute
                                  : EagleTokens.inkMute,
                          fontSize: 11.8,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final texto = _inviteMessage(aluno);
                      HapticFeedback.mediumImpact();
                      if (hasWhatsapp) {
                        final uri = Uri.parse(
                          'https://wa.me/55$whatsappNumber?text=${Uri.encodeComponent(texto)}',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (mounted) context.pop(true);
                          return;
                        }
                      }
                      await Clipboard.setData(ClipboardData(text: texto));
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              hasWhatsapp
                                  ? 'Mensagem copiada. Abra o WhatsApp e envie ao aluno.'
                                  : 'Convite copiado.',
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                        context.pop(true);
                      }
                    },
                    icon: Icon(
                      hasWhatsapp ? Icons.send_rounded : Icons.copy_rounded,
                      size: 18,
                    ),
                    label: Text(
                      hasWhatsapp ? 'Enviar no WhatsApp' : 'Copiar convite',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (hasWhatsapp) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: _inviteMessage(aluno)),
                        );
                        HapticFeedback.mediumImpact();
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mensagem copiada.')),
                          );
                          context.pop(true);
                        }
                      },
                      icon: Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                      ),
                      label: Text(
                        'Copiar convite',
                        style: TextStyle(
                          color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color:
                              isDark ? EagleTokens.darkLine : EagleTokens.line,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      if (mounted) context.pop(true);
                    },
                    child: Text(
                      'Fechar',
                      style: TextStyle(
                        color:
                            isDark
                                ? EagleTokens.darkInkMute
                                : EagleTokens.inkMute,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  String _inviteMessage(dynamic aluno) {
    return 'Olá ${aluno.nome.split(' ').first}! Seu perfil no Focux foi criado.\n\n'
        'Acesse com seu e-mail: ${aluno.email}\n'
        'Senha provisória: ${aluno.senhaProvisoria}\n\n'
        'Altere a senha no primeiro acesso.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(false),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: ink,
                    iconSize: 20,
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Novo item',
                          style: TextStyle(
                            color: mute,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Novo aluno',
                          style: GoogleFonts.outfit(
                            color: ink,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.9,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _entryFade,
                child: SlideTransition(
                  position: _entrySlide,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 132),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _AccessProgressStrip(
                            name: _firstName,
                            hasName: _nomeCtrl.text.trim().isNotEmpty,
                            hasEmail: RegExp(
                              _emailPattern,
                            ).hasMatch(_emailCtrl.text.trim()),
                            isDark: isDark,
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            icon: Icons.person_outline_rounded,
                            title: 'Identidade',
                            subtitle: 'Acesso e contato.',
                            isDark: isDark,
                            children: [
                              _FxFormField(
                                controller: _nomeCtrl,
                                label: 'Nome completo',
                                hint: 'Ex.: Beatriz Andrade',
                                icon: Icons.person_outline_rounded,
                                isDark: isDark,
                                validator:
                                    (v) =>
                                        v == null || v.trim().isEmpty
                                            ? 'Informe o nome completo.'
                                            : null,
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 14),
                              _FxFormField(
                                controller: _emailCtrl,
                                label: 'E-mail',
                                hint: 'aluno@email.com',
                                icon: Icons.alternate_email_rounded,
                                isDark: isDark,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isEmpty) return 'Informe o e-mail.';
                                  if (!RegExp(_emailPattern).hasMatch(value)) {
                                    return 'Informe um e-mail válido.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              _FxFormField(
                                controller: _whatsappCtrl,
                                label: 'WhatsApp',
                                helper:
                                    'Opcional. Se preencher, abrimos o WhatsApp com a mensagem pronta.',
                                hint: '(11) 99999-9999',
                                icon: Icons.phone_outlined,
                                isDark: isDark,
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _SectionCard(
                            icon: Icons.tune_rounded,
                            title: 'Perfil inicial',
                            subtitle: 'Filtros e atendimento.',
                            isDark: isDark,
                            children: [
                              _FxFormField(
                                controller: _objetivoCtrl,
                                label: 'Objetivo',
                                hint: 'Ex.: Hipertrofia',
                                icon: Icons.flag_outlined,
                                isDark: isDark,
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _objetivosRapidos.map((objetivo) {
                                      final selected =
                                          _objetivoCtrl.text.trim() == objetivo;
                                      return _OptionChip(
                                        label: objetivo,
                                        selected: selected,
                                        isDark: isDark,
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            _objetivoCtrl.text =
                                                selected ? '' : objetivo;
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 18),
                              _LabelRow(label: 'Gênero', isDark: isDark),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _generos.map((g) {
                                      return _OptionChip(
                                        label: g,
                                        selected: _genero == g,
                                        isDark: isDark,
                                        onTap:
                                            () => setState(
                                              () =>
                                                  _genero =
                                                      _genero == g ? null : g,
                                            ),
                                      );
                                    }).toList(),
                              ),
                              const SizedBox(height: 18),
                              _LabelRow(label: 'Consultoria', isDark: isDark),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(
                                  _tiposConsultoria.length,
                                  (i) {
                                    final value = _tiposConsultoria[i];
                                    return _OptionChip(
                                      label: _tiposConsultoriaLabel[i],
                                      selected: _tipoConsultoria == value,
                                      isDark: isDark,
                                      onTap:
                                          () => setState(
                                            () =>
                                                _tipoConsultoria =
                                                    _tipoConsultoria == value
                                                        ? null
                                                        : value,
                                          ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (_canSubmit) ...[
                            const SizedBox(height: 14),
                            _InvitePreviewCard(
                              isDark: isDark,
                              name: _firstName,
                              hasWhatsapp: _whatsappCtrl.text.trim().isNotEmpty,
                              consultoriaLabel:
                                  _tipoConsultoria == null
                                      ? null
                                      : _tiposConsultoriaLabel[_tiposConsultoria
                                          .indexOf(_tipoConsultoria!)],
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            _ErrorCard(message: _error!, isDark: isDark),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _BottomSubmitBar(
              isDark: isDark,
              primary: primary,
              canSubmit: _canSubmit,
              loading: _loading,
              helper:
                  _canSubmit
                      ? 'O convite de $_firstName será preparado após o cadastro.'
                      : 'Complete nome e e-mail para cadastrar',
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line.withValues(alpha: 0.86)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: mute, fontSize: 12, height: 1.25),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _AccessProgressStrip extends StatelessWidget {
  final String name;
  final bool hasName;
  final bool hasEmail;
  final bool isDark;

  const _AccessProgressStrip({
    required this.name,
    required this.hasName,
    required this.hasEmail,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final ready = hasName && hasEmail;
    final progress = (hasName ? 1 : 0) + (hasEmail ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ready
                      ? 'Convite pronto para $name'
                      : 'Preencha nome e e-mail',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ready ? ink : mute,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.18 : 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$progress/2',
                  style: TextStyle(
                    color: primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(child: _ProgressStep(done: hasName, isDark: isDark)),
              const SizedBox(width: 8),
              Expanded(child: _ProgressStep(done: hasEmail, isDark: isDark)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressStep extends StatelessWidget {
  final bool done;
  final bool isDark;

  const _ProgressStep({required this.done, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    return Container(
      height: 4,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: done ? primary : line.withValues(alpha: isDark ? 0.7 : 0.75),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _FxFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isDark;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _FxFormField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.hint,
    this.helper,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: mute,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: TextStyle(
            color: ink,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          cursorColor: primary,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 19, color: mute),
            filled: true,
            fillColor:
                isDark
                    ? EagleTokens.darkCardHi
                    : EagleTokens.paper.withValues(alpha: 0.78),
            hintStyle: TextStyle(color: mute.withValues(alpha: 0.62)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: primary.withValues(alpha: 0.42),
                width: 1.3,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: EagleTokens.bad),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: EagleTokens.bad, width: 1.3),
            ),
            errorStyle: const TextStyle(color: EagleTokens.bad, fontSize: 11),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper!,
            style: TextStyle(color: mute, fontSize: 11.5, height: 1.25),
          ),
        ],
      ],
    );
  }
}

class _LabelRow extends StatelessWidget {
  final String label;
  final bool isDark;

  const _LabelRow({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected
                  ? primary.withValues(alpha: isDark ? 0.2 : 0.1)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : EagleTokens.paper),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? primary.withValues(alpha: 0.48) : line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 15, color: primary),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? primary : ink,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvitePreviewCard extends StatelessWidget {
  final bool isDark;
  final String name;
  final bool hasWhatsapp;
  final String? consultoriaLabel;

  const _InvitePreviewCard({
    required this.isDark,
    required this.name,
    required this.hasWhatsapp,
    this.consultoriaLabel,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: isDark ? 0.22 : 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.auto_awesome_motion_rounded,
                  color: primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fluxo pós-cadastro',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$name entra na lista de alunos e recebe acesso com senha provisória.',
                      style: TextStyle(color: mute, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewBadge(
                icon: Icons.password_rounded,
                label: 'Senha provisória',
                isDark: isDark,
              ),
              _PreviewBadge(
                icon:
                    hasWhatsapp
                        ? Icons.send_to_mobile_rounded
                        : Icons.content_copy_rounded,
                label: hasWhatsapp ? 'WhatsApp pronto' : 'Mensagem copiável',
                isDark: isDark,
              ),
              if (consultoriaLabel != null)
                _PreviewBadge(
                  icon: Icons.co_present_rounded,
                  label: consultoriaLabel!,
                  isDark: isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _PreviewBadge({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: primary,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final bool isDark;

  const _ErrorCard({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EagleTokens.bad.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EagleTokens.bad.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: EagleTokens.bad, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: EagleTokens.bad, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSubmitBar extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final bool canSubmit;
  final bool loading;
  final String helper;
  final VoidCallback onSubmit;

  const _BottomSubmitBar({
    required this.isDark,
    required this.primary,
    required this.canSubmit,
    required this.loading,
    required this.helper,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, canSubmit ? 9 : 8, 20, 12),
        decoration: BoxDecoration(
          color: isDark ? EagleTokens.darkBg : EagleTokens.paper,
          border: Border(top: BorderSide(color: line.withValues(alpha: 0.65))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!canSubmit) ...[
              SizedBox(
                height: 34,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        helper,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: mute,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                helper,
                textAlign: TextAlign.center,
                style: TextStyle(color: mute, fontSize: 11, height: 1.2),
              ),
              const SizedBox(height: 7),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSubmit,
                    borderRadius: BorderRadius.circular(17),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: primary),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.18),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child:
                          loading
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                              : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_add_alt_1_rounded,
                                    size: 19,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Cadastrar aluno',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
