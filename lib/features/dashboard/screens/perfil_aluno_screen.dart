import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/friendly_error.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../anamnese/data/anamnese_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';
import '../../../core/theme/tokens_strip.dart';

final minhasMedidasProvider = FutureProvider<List<MedidaCorporal>>((ref) async {
  final repo = EvolucaoRepository(ref.read(apiClientProvider));
  return repo.listarMinhasMedidas();
});

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
  bool _deleting = false;

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
        _objetivo.text =
            _objetivo.text.trim().isNotEmpty
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
      final url = await MediaUploadService(
        ref.read(apiClientProvider),
      ).uploadBytes(
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
        FeedbackHelper.showError(context, friendlyError(e));
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
        FeedbackHelper.showSuccess(context, 'Perfil do aluno atualizado.');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excluir conta'),
            content: const Text(
              'Esta acao e irreversivel. Seus dados pessoais serao anonimizados conforme a LGPD. Historico financeiro ou operacional pode ser mantido pelo prazo legal.\n\n'
              'Deseja realmente excluir sua conta?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: EagleTokens.bad),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Excluir definitivamente'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(apiClientProvider).dio.delete('/api/lgpd/me/delete');
      await ref.read(authProvider.notifier).logout();
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Conta excluida com sucesso.');
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  int _completionScore() {
    final values = [
      _nome.text,
      _email.text,
      _objetivo.text,
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

  String _formatarDataCurta(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final dia = parsed.day.toString().padLeft(2, '0');
    final mes = parsed.month.toString().padLeft(2, '0');
    return '$dia/$mes/${parsed.year}';
  }

  String _variacaoPeso(List<MedidaCorporal> medidas) {
    final comPeso =
        medidas.where((item) => item.peso != null).toList()
          ..sort((a, b) => a.data.compareTo(b.data));
    if (comPeso.length < 2) {
      return 'Registre pelo menos 2 pesos para ver a variacao.';
    }
    final diff = comPeso.last.peso! - comPeso.first.peso!;
    final sinal = diff > 0 ? '+' : '';
    return '$sinal${diff.toStringAsFixed(1)} kg desde a primeira medida';
  }

  Future<void> _registrarMedida() async {
    final dataCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
    final pesoCtrl = TextEditingController(text: _peso.text.trim());
    final cinturaCtrl = TextEditingController();
    final quadrilCtrl = TextEditingController();
    final bracoCtrl = TextEditingController();
    String? fotoUrl;
    bool saving = false;
    bool uploading = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> selecionarFoto() async {
              final file = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                imageQuality: 86,
              );
              if (file == null) return;
              setModalState(() => uploading = true);
              try {
                final url = await MediaUploadService(
                  ref.read(apiClientProvider),
                ).uploadBytes(
                  bytes: await file.readAsBytes(),
                  filename: file.name,
                  folder: 'alunos/evolucao',
                  resourceType: 'image',
                );
                setModalState(() => fotoUrl = url);
              } catch (e) {
                if (mounted) {
                  FeedbackHelper.showError(context, friendlyError(e));
                }
              } finally {
                if (ctx.mounted) {
                  setModalState(() => uploading = false);
                }
              }
            }

            Future<void> salvar() async {
              setModalState(() => saving = true);
              try {
                final repo = EvolucaoRepository(ref.read(apiClientProvider));
                final peso = double.tryParse(
                  pesoCtrl.text.trim().replaceAll(',', '.'),
                );
                await repo.adicionarMinhaMedida(
                  data: dataCtrl.text.trim(),
                  peso: peso,
                  cintura: double.tryParse(
                    cinturaCtrl.text.trim().replaceAll(',', '.'),
                  ),
                  quadril: double.tryParse(
                    quadrilCtrl.text.trim().replaceAll(',', '.'),
                  ),
                  braco: double.tryParse(
                    bracoCtrl.text.trim().replaceAll(',', '.'),
                  ),
                  fotoUrl: fotoUrl,
                );
                ref.invalidate(minhasMedidasProvider);
                if (peso != null) {
                  _peso.text = peso.toStringAsFixed(1);
                  await _save(silent: true);
                }
                if (!ctx.mounted || !mounted) return;
                Navigator.of(ctx).pop();
                FeedbackHelper.showSuccess(context, 'Nova medida registrada.');
              } catch (e) {
                if (!mounted) return;
                FeedbackHelper.showError(context, friendlyError(e));
              } finally {
                if (ctx.mounted) {
                  setModalState(() => saving = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: TokensStrip.borderDefault,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: TokensStrip.s4),
                      Text(
                        'Registrar progresso',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Atualize peso, medidas e uma foto opcional para acompanhar sua evolucao sem depender do personal.',
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: TokensStrip.s4),
                      _Field(
                        controller: dataCtrl,
                        label: 'Data AAAA-MM-DD',
                        icon: Icons.calendar_today_outlined,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _Field(
                              controller: pesoCtrl,
                              label: 'Peso kg',
                              icon: Icons.monitor_weight_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Field(
                              controller: cinturaCtrl,
                              label: 'Cintura cm',
                              icon: Icons.straighten_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _Field(
                              controller: quadrilCtrl,
                              label: 'Quadril cm',
                              icon: Icons.straighten_outlined,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Field(
                              controller: bracoCtrl,
                              label: 'Braco cm',
                              icon: Icons.fitness_center,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: uploading ? null : selecionarFoto,
                        icon:
                            uploading
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: FxLoading(strokeWidth: 2),
                                )
                                : const Icon(Icons.add_a_photo_outlined),
                        label: Text(
                          fotoUrl == null
                              ? 'Adicionar foto de progresso'
                              : 'Foto de progresso pronta',
                        ),
                      ),
                      if (fotoUrl != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: AspectRatio(
                            aspectRatio: 1.15,
                            child: Image.network(fotoUrl!, fit: BoxFit.cover),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FxLiquidPrimaryButton(
                          loading: saving,
                          icon: Icons.check_circle_outline,
                          label: 'Salvar medida',
                          onPressed: saving ? null : salvar,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final async = ref.watch(alunoMeProvider);
    final medidasAsync = ref.watch(minhasMedidasProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Meu perfil',
        onBack: () => safePopOrGo(context, '/dashboard/aluno'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child:
                _saving
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: FxLoading(strokeWidth: 2),
                    )
                    : const Text('Salvar'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const FxLoading(),
        error:
            (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(TokensStrip.s5),
                child: Text(friendlyError(e), textAlign: TextAlign.center),
              ),
            ),
        data: (aluno) {
          _loadIfNeeded(aluno);
          final completion = _completionScore();
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors:
                            isDark
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
                                  backgroundColor: BrandPalette.soft(primary),
                                  child:
                                      _fotoUrl == null || _fotoUrl!.isEmpty
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
                                    icon:
                                        _uploading
                                            ? const SizedBox(
                                              width: 15,
                                              height: 15,
                                              child: FxLoading(strokeWidth: 2),
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
                                      backgroundColor: BrandPalette.soft(
                                        primary,
                                      ),
                                      valueColor: AlwaysStoppedAnimation(
                                        primary,
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
                                color: BrandPalette.soft(primary, dark: isDark),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(
                                '$completion%',
                                style: TextStyle(
                                  color: primary,
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
                  const SizedBox(height: TokensStrip.s4),
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
                    subtitle:
                        'O que o aluno quer construir e de onde esta partindo.',
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
                    title: 'Progresso corporal',
                    subtitle:
                        'Medidas, foto de evolução e histórico rápido para acompanhar resultado real.',
                    isDark: isDark,
                    trailing: FilledButton.tonalIcon(
                      onPressed: _registrarMedida,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      icon: const Icon(Icons.add_chart),
                      label: const Text('Registrar'),
                    ),
                    children: [
                      medidasAsync.when(
                        loading:
                            () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: FxLoading(),
                            ),
                        error:
                            (e, _) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Não foi possível carregar sua evolução: $e',
                                style: TextStyle(color: mute, height: 1.4),
                              ),
                            ),
                        data: (medidas) {
                          final ultima =
                              medidas.isNotEmpty ? medidas.first : null;
                          final cards = <Widget>[
                            _MetricHighlightCard(
                              label: 'Último peso',
                              value:
                                  ultima?.peso != null
                                      ? '${ultima!.peso!.toStringAsFixed(1)} kg'
                                      : 'Sem registro',
                              helper:
                                  ultima != null
                                      ? 'Atualizado em ${_formatarDataCurta(ultima.data)}'
                                      : 'Registre a primeira medida',
                              icon: Icons.monitor_weight_outlined,
                              isDark: isDark,
                            ),
                            _MetricHighlightCard(
                              label: 'Variação',
                              value:
                                  medidas
                                              .where(
                                                (item) => item.peso != null,
                                              )
                                              .length >=
                                          2
                                      ? _variacaoPeso(
                                        medidas,
                                      ).split(' desde').first
                                      : '--',
                              helper: _variacaoPeso(medidas),
                              icon: Icons.show_chart,
                              isDark: isDark,
                            ),
                            _MetricHighlightCard(
                              label: 'Entradas',
                              value: '${medidas.length}',
                              helper:
                                  medidas.isEmpty
                                      ? 'Nenhuma atualização ainda'
                                      : 'Histórico pronto para comparar',
                              icon: Icons.timeline,
                              isDark: isDark,
                            ),
                          ];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < cards.length; i++) ...[
                                cards[i],
                                if (i != cards.length - 1)
                                  const SizedBox(height: 10),
                              ],
                              const SizedBox(height: 12),
                              if (medidas.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(TokensStrip.s4),
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? Colors.white.withValues(
                                              alpha: 0.04,
                                            )
                                            : BrandPalette.softer(primary),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    'Seu histórico corporal ainda está vazio. Registrar a primeira medida melhora acompanhamento, ajuste de carga e conversa com o personal.',
                                    style: TextStyle(
                                      color: mute,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                )
                              else ...[
                                Text(
                                  'Últimas atualizações',
                                  style: TextStyle(
                                    color: ink,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ...medidas
                                    .take(3)
                                    .map(
                                      (medida) => _ProgressEntryCard(
                                        medida: medida,
                                        isDark: isDark,
                                        formatarData: _formatarDataCurta,
                                      ),
                                    ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Saúde e restrições',
                    subtitle:
                        'Informações que deixam treino e dieta mais seguros.',
                    isDark: isDark,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _nivelAtividade,
                        decoration: const InputDecoration(
                          labelText: 'Nível de atividade',
                          prefixIcon: Icon(Icons.insights_outlined),
                        ),
                        items:
                            _niveisAtividade
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item.$1,
                                    child: Text(item.$2),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (value) => setState(() => _nivelAtividade = value),
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _lesoes,
                        label: 'Lesões ou limitações',
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
                        label: 'Histórico médico',
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
                        label: 'Dores crônicas',
                        icon: Icons.accessibility_new_outlined,
                        maxLines: 2,
                      ),
                      _Field(
                        controller: _restricoesAlimentares,
                        label: 'Restrições alimentares',
                        icon: Icons.no_food_outlined,
                        maxLines: 2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Rotina de treino',
                    subtitle:
                        'Preferências e disponibilidade para o plano fazer sentido.',
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
                        onSelectionChanged:
                            (values) => setState(
                              () => _disponibilidadeSemanal = values.first,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _preferenciasTreino,
                        label: 'Preferências de treino',
                        icon: Icons.sports_gymnastics_outlined,
                        maxLines: 3,
                      ),
                      _Field(
                        controller: _observacoes,
                        label: 'Observações para o personal',
                        icon: Icons.sticky_note_2_outlined,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: TokensStrip.s4),
                  FxLiquidPrimaryButton(
                    loading: _saving,
                    icon: Icons.check,
                    label: 'Salvar meu perfil',
                    onPressed: _saving ? null : _save,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EagleTokens.bad,
                      side: const BorderSide(color: EagleTokens.bad),
                    ),
                    onPressed: _deleting ? null : _confirmDeleteAccount,
                    icon:
                        _deleting
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: FxLoading(strokeWidth: 2),
                            )
                            : const Icon(Icons.delete_forever_outlined),
                    label: const Text('Excluir minha conta'),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Esses dados ajudam o personal a ajustar treino, contato, segurança e aderência sem depender de conversa toda hora.',
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
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
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
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.06)
                : BrandPalette.softer(primary),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricHighlightCard extends StatelessWidget {
  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final bool isDark;

  const _MetricHighlightCard({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            isDark
                ? Colors.white.withValues(alpha: 0.04)
                : BrandPalette.softer(primary),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? EagleTokens.darkLine : TokensStrip.borderDefault,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: BrandPalette.soft(primary, dark: isDark),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color:
                        isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  helper,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressEntryCard extends StatelessWidget {
  final MedidaCorporal medida;
  final bool isDark;
  final String Function(String value) formatarData;

  const _ProgressEntryCard({
    required this.medida,
    required this.isDark,
    required this.formatarData,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chips = <Widget>[
      if (medida.peso != null)
        _MiniValueChip(
          label: 'Peso',
          value: '${medida.peso!.toStringAsFixed(1)} kg',
        ),
      if (medida.cintura != null)
        _MiniValueChip(
          label: 'Cintura',
          value: '${medida.cintura!.toStringAsFixed(1)} cm',
        ),
      if (medida.quadril != null)
        _MiniValueChip(
          label: 'Quadril',
          value: '${medida.quadril!.toStringAsFixed(1)} cm',
        ),
      if (medida.braco != null)
        _MiniValueChip(
          label: 'Braco',
          value: '${medida.braco!.toStringAsFixed(1)} cm',
        ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                formatarData(medida.data),
                style: TextStyle(
                  color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (medida.fotoUrl != null && medida.fotoUrl!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: BrandPalette.soft(primary, dark: isDark),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Com foto',
                    style: TextStyle(
                      color: primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (chips.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          if (medida.fotoUrl != null && medida.fotoUrl!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 1.4,
                child: Image.network(medida.fotoUrl!, fit: BoxFit.cover),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniValueChip extends StatelessWidget {
  final String label;
  final String value;

  const _MiniValueChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
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
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        validator:
            requiredField
                ? (value) =>
                    value == null || value.trim().isEmpty
                        ? 'Obrigatorio.'
                        : null
                : null,
      ),
    );
  }
}
