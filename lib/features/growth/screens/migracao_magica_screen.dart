import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../planos/data/planos_repository.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/plan_entitlements.dart';
import '../utils/migracao_file_parser.dart';
import '../utils/migracao_foto_limits.dart';
import '../utils/migracao_ocr_service.dart';

part 'migracao_magica_screen_actions.part.dart';


class MigracaoMagicaScreen extends ConsumerStatefulWidget {
  const MigracaoMagicaScreen({super.key});

  @override
  ConsumerState<MigracaoMagicaScreen> createState() =>
      _MigracaoMagicaScreenState();
}

class _MigracaoMagicaScreenState extends ConsumerState<MigracaoMagicaScreen> {
  final TextEditingController _controller = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isImportingFile = false;
  String? _importedFileLabel;
  Uint8List? _importedPhotoBytes;
  List<Map<String, dynamic>>? _alunosEncontrados;
  bool _emptyResult = false;

  static const _passos = [
    'Importe planilha, foto/print (OCR no celular) ou cole texto',
    'Revise, edite ou remova linhas antes de confirmar',
    'Confirme e salve: duplicados são ignorados automaticamente',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onDraftChanged);
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onDraftChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      featureName: 'Migração Focux',
      requiredPlan: SubscriptionPlan.PREMIUM,
      capability: 'iaCopiloto',
      child: _buildContent(context),
    );
  }

  Duration _motionDuration(BuildContext context) =>
      TokensStrip.prefersReducedMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 280);

  Widget _stagger(
    BuildContext context, {
    required int index,
    required Widget child,
    Key? key,
  }) {
    final reduce = TokensStrip.prefersReducedMotion(context);
    return FxStaggerItem(
      key: key,
      index: index,
      staggerDelay:
          reduce ? Duration.zero : const Duration(milliseconds: 60),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 400),
      slideOffset: reduce ? 0 : 20,
      child: child,
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final brand = Theme.of(context).colorScheme.primary;
    final brandDeep = BrandPalette.deep(brand);
    final brandSoft = BrandPalette.soft(brand, dark: isDark);
    final brandSofter = BrandPalette.softer(brand, dark: isDark);
    final alunos = _alunosEncontrados;

    return PopScope(
      canPop: !_hasUnsavedWork,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Migração Focux',
          onBack: _handleBack,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s4,
            TokensStrip.s2,
            TokensStrip.s4,
            TokensStrip.s6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _stagger(
                context,
                index: 0,
                child: Semantics(
                  header: true,
                  label:
                      'Importe alunos com planilha, foto de app concorrente ou texto colado.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : brandSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: brand,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'IA FOCUX',
                            style: TextStyle(
                              fontSize: 12,
                              color: brand,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TokensStrip.s2),
                      Text(
                        'Importe alunos',
                        style: AppTypography.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: ink,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Planilha (.csv, .xlsx), print de app concorrente ou texto — '
                        'análise automática no app. Você revisa antes de salvar.',
                        style: TextStyle(fontSize: 14, color: mute, height: 1.55),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s3),
              _stagger(
                context,
                index: 1,
                child: Semantics(
                  label:
                      'Dica: prints de apps concorrentes como MFIT e Trainerize podem ser importados por foto.',
                  child: Container(
                    padding: const EdgeInsets.all(TokensStrip.s3),
                    decoration: BoxDecoration(
                      color: brandSofter,
                      borderRadius: BorderRadius.circular(TokensStrip.rSm),
                      border: Border.all(
                        color: brand.withValues(alpha: isDark ? 0.35 : 0.22),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.screenshot_monitor_rounded, color: brand, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Veio de outro app?',
                                style: AppTypography.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Suba um print da lista de alunos (MFIT, Trainerize, Excel, WhatsApp). '
                                'OCR no celular lê a tela — sem redigitar. Premium: '
                                '${MigracaoFotoLimits.premium} fotos/mês · Enterprise: '
                                '${MigracaoFotoLimits.enterprise}/mês.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: mute,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              _stagger(
                context,
                index: 2,
                child: Semantics(
                  label: 'Como funciona em três passos',
                  child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s5,
                    20,
                    TokensStrip.s5,
                    18,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient:
                        isDark
                            ? LinearGradient(
                              colors: [brandDeep, const Color(0xFF080C10)],
                            )
                            : LinearGradient(colors: [brand, brandDeep]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Como funciona',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ..._passos.asMap().entries.map((entry) {
                        return Semantics(
                          label: 'Passo ${entry.key + 1}. ${entry.value}',
                          child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${entry.key + 1}',
                                  style: AppTypography.mono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.88),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              ),
              const SizedBox(height: TokensStrip.s4),
              _stagger(
                context,
                index: 3,
                child: Container(
                  padding: const EdgeInsets.all(TokensStrip.s4),
                  decoration: fxListCardDecoration(context, accent: brand),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Importar dados',
                        style: AppTypography.inter(
                          fontSize: 13,
                          color: ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Planilha estruturada vai direto para revisão. Foto usa OCR gratuito no app.',
                        style: TextStyle(fontSize: 12, color: mute, height: 1.35),
                      ),
                      Builder(
                        builder: (context) {
                          final plano = ref.watch(planoFeaturesProvider).value;
                          if (plano == null || !plano.migracaoFoto) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Foto/print: Premium (${MigracaoFotoLimits.premium}/mês) ou Enterprise (${MigracaoFotoLimits.enterprise}/mês).',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: mute,
                                  height: 1.35,
                                ),
                              ),
                            );
                          }
                          final limite = plano.limiteMigracaoFotoMensal ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Fotos este mês: ${plano.migracaoFotosUsadasMes}/$limite · '
                              '${plano.migracaoFotosRestantes} restante(s)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: brand,
                                height: 1.35,
                              ),
                            ),
                          );
                        },
                      ),
                      if (_importedFileLabel != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: brandSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _importedPhotoBytes != null
                                    ? Icons.image_rounded
                                    : Icons.insert_drive_file_rounded,
                                size: 14,
                                color: brand,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _importedFileLabel!,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: brand,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_importedPhotoBytes != null) ...[
                        const SizedBox(height: TokensStrip.s3),
                        Semantics(
                          label: 'Preview do print enviado',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(TokensStrip.rSm),
                            child: Image.memory(
                              _importedPhotoBytes!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: TokensStrip.s3),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  (_isLoading || _isImportingFile)
                                      ? null
                                      : _importarArquivo,
                              icon:
                                  _isImportingFile
                                      ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: FxLoading(
                                          size: 16,
                                          strokeWidth: 2,
                                          color: brand,
                                        ),
                                      )
                                      : const Icon(Icons.upload_file_rounded, size: 18),
                              label: Text(
                                _isImportingFile ? 'Lendo...' : 'Planilha',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _isLoading ? null : _colarClipboard,
                              icon: const Icon(Icons.content_paste_go_rounded, size: 18),
                              label: const Text('Colar texto'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Semantics(
                        button: true,
                        label: 'Subir foto ou print de app concorrente',
                        child: OutlinedButton.icon(
                          onPressed:
                              (_isLoading || _isImportingFile) ? null : _subirFoto,
                          icon:
                              _isLoading && _importedPhotoBytes != null
                                  ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: FxLoading(
                                      size: 16,
                                      strokeWidth: 2,
                                      color: brand,
                                    ),
                                  )
                                  : const Icon(Icons.add_a_photo_outlined, size: 18),
                          label: Text(
                            _isLoading && _importedPhotoBytes != null
                                ? 'Lendo print (OCR)...'
                                : 'Subir foto ou print',
                          ),
                        ),
                      ),
                      Semantics(
                        label: 'Campo para colar dados desestruturados dos alunos',
                        child: Container(
                          padding: const EdgeInsets.all(TokensStrip.s3),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : brandSofter,
                            borderRadius: BorderRadius.circular(TokensStrip.rSm),
                            border: Border.all(
                              color:
                                  isDark
                                      ? EagleTokens.darkLine
                                      : brand.withValues(alpha: 0.18),
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            maxLines: 8,
                            minLines: 4,
                            style: AppTypography.mono(
                              fontSize: 13,
                              color: ink,
                              height: 1.6,
                            ),
                            decoration: InputDecoration.collapsed(
                              hintText:
                                  'Beatriz Carvalho — 28 anos — (11)99999-1111 — bia@gmail.com — hipertrofia\n'
                                  'Ou cole texto copiado de print/PDF…',
                              hintStyle: TextStyle(
                                color: mute.withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_controller.text.trim().isNotEmpty) ...[
                        const SizedBox(height: TokensStrip.s3),
                        FxLiquidPrimaryButton(
                          label: 'Iniciar migração',
                          icon: Icons.auto_awesome,
                          loading: _isLoading && _importedPhotoBytes == null,
                          loadingLabel: 'Analisando texto...',
                          onPressed:
                              (_isLoading && _importedPhotoBytes == null)
                                  ? null
                                  : _processarMigracao,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: _motionDuration(context),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildResultsSection(
                  key: ValueKey(
                    '${alunos?.length ?? 0}-$_emptyResult',
                  ),
                  isDark: isDark,
                  ink: ink,
                  mute: mute,
                  brand: brand,
                  brandDeep: brandDeep,
                  alunos: alunos,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection({
    required Key key,
    required bool isDark,
    required Color ink,
    required Color mute,
    required Color brand,
    required Color brandDeep,
    required List<Map<String, dynamic>>? alunos,
  }) {
    if (_emptyResult) {
      return _stagger(
        context,
        key: key,
        index: 4,
        child: Padding(
          padding: const EdgeInsets.only(top: TokensStrip.s4),
          child: Container(
            padding: const EdgeInsets.all(TokensStrip.s4),
            decoration: fxListCardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.search_off_rounded, color: mute, size: 28),
                const SizedBox(height: 10),
                Text(
                  'Nenhum aluno identificado',
                  style: AppTypography.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Revise o texto colado e tente novamente com mais linhas ou campos visíveis.',
                  style: TextStyle(color: mute, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (alunos == null || alunos.isEmpty) {
      return SizedBox(key: key);
    }

    return _stagger(
      context,
      key: key,
      index: 4,
      child: Padding(
        padding: const EdgeInsets.only(top: TokensStrip.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              label: '${alunos.length} alunos encontrados para revisão. Toque para editar.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${alunos.length} alunos encontrados',
                    style: AppTypography.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toque para editar · remova duplicados antes de salvar',
                    style: TextStyle(fontSize: 12, color: mute, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TokensStrip.s3),
            ...alunos.asMap().entries.map((entry) {
              final index = entry.key;
              final aluno = entry.value;
              final nome = (aluno['nome'] ?? 'Desconhecido').toString();
              final email = (aluno['email'] ?? '').toString();
              final telefone = (aluno['telefone'] ?? '').toString();
              final objetivo = (aluno['objetivo'] ?? '').toString();
              final duplicado = aluno['duplicado'] == true;
              final meta = [
                if (email.isNotEmpty) email,
                if (telefone.isNotEmpty) telefone,
                if (objetivo.isNotEmpty) objetivo,
              ].join(' · ');

              return Padding(
                padding: const EdgeInsets.only(bottom: TokensStrip.s2),
                child: Semantics(
                  label:
                      duplicado
                          ? 'Aluno $nome duplicado. $meta. Toque para editar.'
                          : 'Aluno $nome. $meta. Toque para editar.',
                  button: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _editarAluno(index),
                      borderRadius: BorderRadius.circular(TokensStrip.rCard),
                      child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: fxListCardDecoration(context, accent: brand),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark ? brandDeep : brand,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nome,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (meta.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  meta,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: mute,
                                    height: 1.35,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (duplicado) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: EagleTokens.warnSoft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Já cadastrado',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: EagleTokens.warn,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remover da lista',
                          onPressed: () => _removerAluno(index),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: mute,
                          ),
                        ),
                      ],
                    ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: TokensStrip.s3),
            FxLiquidPrimaryButton(
              label: 'Confirmar e salvar ${alunos.where((a) => a['duplicado'] != true).length} alunos',
              icon: Icons.check_rounded,
              loading: _isSaving,
              loadingLabel: 'Salvando alunos...',
              onPressed: _isSaving ? null : _salvarAlunos,
            ),
          ],
        ),
      ),
    );
  }
}
