import 'package:flutter/material.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../data/enums.dart';
import '../data/exercicio_repository.dart';
import '../data/exercicio_taxonomy_labels.dart';
import '../providers/exercicios_provider.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

class ExercicioDetailScreen extends ConsumerStatefulWidget {
  final int exercicioId;
  const ExercicioDetailScreen({super.key, required this.exercicioId});

  @override
  ConsumerState<ExercicioDetailScreen> createState() =>
      _ExercicioDetailScreenState();
}

class _ExercicioDetailScreenState extends ConsumerState<ExercicioDetailScreen> {
  bool _uploadingVideo = false;

  Future<void> _toggleFavorito(BuildContext context, bool favoritado) async {
    final repo = ref.read(exercicioRepositoryProvider);
    try {
      if (favoritado) {
        await repo.desfavoritarExercicio(widget.exercicioId);
      } else {
        await repo.favoritarExercicio(widget.exercicioId);
      }
      ref.invalidate(exercicioProvider(widget.exercicioId));
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (context.mounted) {
        FeedbackHelper.showSnackBar(
          context,
          const SnackBar(content: Text('Erro ao atualizar favorito.')),
        );
      }
    }
  }

  Future<void> _pickAndUploadVideo(BuildContext context) async {
    setState(() => _uploadingVideo = true);
    try {
      final uploaded = await ref
          .read(exercicioVideoUploaderProvider)
          .pickAndUpload(widget.exercicioId);
      if (uploaded == null) return;
      AnalyticsService.instance.track(
        'video_personal_upload',
        props: {'exId': widget.exercicioId},
      );
      ref.invalidate(exercicioProvider(widget.exercicioId));
      ref.invalidate(exerciciosFilteredProvider);
      if (!context.mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(content: Text('Video proprio adicionado ao exercicio.')),
      );
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (context.mounted) {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingVideo = false);
    }
  }

  Future<void> _updateEditorialReview(
    BuildContext context,
    String status,
    String? currentNotes,
  ) async {
    final notesCtrl = TextEditingController(text: currentNotes ?? '');
    final notes = await showDialog<String?>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(_editorialActionTitle(status)),
            content: TextField(
              controller: notesCtrl,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                border: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                hintText: 'Notas tecnicas, fonte do video ou motivo da decisao',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, notesCtrl.text.trim()),
                child: const Text('Salvar'),
              ),
            ],
          ),
    );
    notesCtrl.dispose();
    if (notes == null) return;

    try {
      await ref
          .read(exercicioRepositoryProvider)
          .atualizarCuradoriaEditorial(
            id: widget.exercicioId,
            status: status,
            notes: notes.isEmpty ? null : notes,
          );
      ref.invalidate(exercicioProvider(widget.exercicioId));
      ref.invalidate(exerciciosFilteredProvider);
      ref.invalidate(exerciciosCuradoriaProvider);
      if (!context.mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(
          content: Text(
            'Curadoria marcada como ${_formatEditorialStatus(status)}.',
          ),
        ),
      );
    } catch (e) {
      debugPrint('[Focux] Error: $e');
      if (context.mounted) {
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercicioAsync = ref.watch(exercicioProvider(widget.exercicioId));

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EagleTokens.darkBg : EagleTokens.paper;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
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
                        'DETALHES',
                        style: TextStyle(
                          fontSize: 12,
                          color: mute,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Exercicio',
                        style: TextStyle(
                          fontSize: 32,
                          color: ink,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      exercicioAsync.when(
                        data:
                            (ex) => IconButton(
                              icon: Icon(
                                ex.favoritado ? Icons.star : Icons.star_border,
                                color: ex.favoritado ? EagleTokens.warn : mute,
                              ),
                              tooltip:
                                  ex.favoritado
                                      ? 'Remover dos favoritos'
                                      : 'Adicionar aos favoritos',
                              onPressed:
                                  () => _toggleFavorito(context, ex.favoritado),
                            ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: mute),
                        onPressed: () => safePopOrGo(context, '/exercicios'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: exercicioAsync.when(
                loading: () => Center(child: FxLoading(color: primary)),
                error: (e, _) => Center(child: Text('Erro: $e')),
                data:
                    (ex) => SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            ex.nome,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ExerciseEssentials(exercicio: ex),
                          const SizedBox(height: 14),
                          _OwnVideoPanel(
                            hasVideo: ex.videoUrl?.isNotEmpty == true,
                            uploading: _uploadingVideo,
                            onUpload: () => _pickAndUploadVideo(context),
                          ),
                          if (ex.videoUrl?.isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            _VideoPlayer(url: ex.videoUrl!),
                          ] else if (ex.gifUrl != null ||
                              ex.thumbnailUrl != null) ...[
                            const SizedBox(height: 12),
                            _ExercisePreviewImage(
                              url: ex.gifUrl ?? ex.thumbnailUrl!,
                            ),
                          ],
                          if (ex.descricao?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: 14),
                            _SimpleInfoCard(
                              icon: Icons.menu_book_rounded,
                              title: 'Como orientar',
                              text: ex.descricao!.trim(),
                            ),
                          ],
                          if (ex.errosComuns?.trim().isNotEmpty == true ||
                              ex.contraindicacoes?.trim().isNotEmpty == true ||
                              ex.substitutos?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            _GuidanceExpansion(exercicio: ex),
                          ],
                          const SizedBox(height: 12),
                          _TechnicalDataExpansion(
                            exercicio: ex,
                            onChangeEditorial:
                                (status) => _updateEditorialReview(
                                  context,
                                  status,
                                  ex.editorialNotes,
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

class _ExerciseEssentials extends StatelessWidget {
  final Exercicio exercicio;

  const _ExerciseEssentials({required this.exercicio});

  @override
  Widget build(BuildContext context) {
    final items =
        [
          (Icons.fitness_center_rounded, _grupoLabel(exercicio)),
          (Icons.category_rounded, _modalidadeLabel(exercicio)),
          (Icons.construction_rounded, _equipamentoLabel(exercicio)),
          (Icons.trending_up_rounded, _dificuldadeLabel(exercicio)),
          (Icons.route_rounded, _padraoLabel(exercicio)),
        ].where((item) => item.$2?.trim().isNotEmpty == true).toList();

    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          _CompactPill(icon: item.$1, label: item.$2!.trim()),
      ],
    );
  }
}

class _CompactPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CompactPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExercisePreviewImage extends StatelessWidget {
  final String url;

  const _ExercisePreviewImage({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        url,
        height: 190,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _SimpleInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _SimpleInfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: TextStyle(
                    color: mute,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class _GuidanceExpansion extends StatelessWidget {
  final Exercicio exercicio;

  const _GuidanceExpansion({required this.exercicio});

  @override
  Widget build(BuildContext context) {
    return _CleanExpansion(
      icon: Icons.health_and_safety_outlined,
      title: 'Cuidados e substituicoes',
      children: [
        if (exercicio.errosComuns?.trim().isNotEmpty == true)
          _GuidanceCard(
            icon: Icons.report_problem_outlined,
            title: 'Erros comuns',
            text: exercicio.errosComuns!.trim(),
            color: EagleTokens.warn,
          ),
        if (exercicio.contraindicacoes?.trim().isNotEmpty == true)
          _GuidanceCard(
            icon: Icons.health_and_safety_outlined,
            title: 'Contraindicacoes',
            text: exercicio.contraindicacoes!.trim(),
            color: EagleTokens.bad,
          ),
        if (exercicio.substitutos?.trim().isNotEmpty == true)
          _GuidanceCard(
            icon: Icons.swap_horiz_rounded,
            title: 'Substitutos',
            text: exercicio.substitutos!.trim(),
            color: Theme.of(context).colorScheme.primary,
          ),
      ],
    );
  }
}

class _TechnicalDataExpansion extends StatelessWidget {
  final Exercicio exercicio;
  final ValueChanged<String> onChangeEditorial;

  const _TechnicalDataExpansion({
    required this.exercicio,
    required this.onChangeEditorial,
  });

  @override
  Widget build(BuildContext context) {
    return _CleanExpansion(
      icon: Icons.tune_rounded,
      title: 'Dados tecnicos',
      children: [
        if (_taxonomyChips(exercicio).isNotEmpty)
          Wrap(spacing: 6, runSpacing: 6, children: _taxonomyChips(exercicio)),
        _PrescriptionReadinessPanel(exercicio: exercicio),
        if (exercicio.videoSource?.isNotEmpty == true ||
            exercicio.licenseStatus?.isNotEmpty == true)
          _MediaMetadataPanel(
            source: exercicio.videoSource,
            licenseStatus: exercicio.licenseStatus,
          ),
        _EditorialReviewPanel(
          status: exercicio.editorialStatus,
          notes: exercicio.editorialNotes,
          reviewedAt: exercicio.editorialReviewedAt,
          onChange: onChangeEditorial,
        ),
      ],
    );
  }
}

class _CleanExpansion extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _CleanExpansion({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(
            title,
            style: TextStyle(
              color: ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _PrescriptionReadinessPanel extends StatelessWidget {
  final Exercicio exercicio;

  const _PrescriptionReadinessPanel({required this.exercicio});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final color = _trustColor(exercicio, primary);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_trustIcon(exercicio), color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prontidao para prescricao',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exercicio.mediaTrustLabel,
                      style: TextStyle(
                        color: mute,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            exercicio.mediaTrustDescription,
            style: TextStyle(
              color: ink.withValues(alpha: 0.82),
              fontSize: 12.8,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ReadinessCheck(
                ok: exercicio.hasPlayableMedia,
                label: 'midia',
                color: color,
              ),
              _ReadinessCheck(
                ok: exercicio.isLicensedMedia || exercicio.isPersonalUpload,
                label: 'licenca/origem',
                color: color,
              ),
              _ReadinessCheck(
                ok: exercicio.isEditorialApproved,
                label: 'curadoria',
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadinessCheck extends StatelessWidget {
  final bool ok;
  final String label;
  final Color color;

  const _ReadinessCheck({
    required this.ok,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final fallback =
        Theme.of(context).brightness == Brightness.dark
            ? EagleTokens.darkInkMute
            : EagleTokens.inkMute;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: (ok ? color : fallback).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: ok ? color : fallback,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: ok ? color : fallback,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String? _modalidadeLabel(Exercicio exercicio) {
  final value = exercicio.modalidade;
  if (value != null) return TaxonomyLabels.modalidade[value];
  return exercicio.categoria;
}

String? _grupoLabel(Exercicio exercicio) {
  final value = exercicio.grupoMuscularPrimario;
  if (value != null) return TaxonomyLabels.grupo[value];
  return exercicio.musculoAlvo;
}

String? _equipamentoLabel(Exercicio exercicio) {
  if (exercicio.equipamentos.isNotEmpty) {
    return exercicio.equipamentos
        .take(2)
        .map((e) => TaxonomyLabels.equipamento[e] ?? e.backendName)
        .join(' / ');
  }
  return exercicio.equipamento;
}

String? _dificuldadeLabel(Exercicio exercicio) {
  final value = exercicio.dificuldade;
  if (value != null) return TaxonomyLabels.dificuldade[value];
  return exercicio.nivel;
}

String? _padraoLabel(Exercicio exercicio) {
  final value = exercicio.padraoMovimento;
  if (value == null) return exercicio.mecanica;
  return TaxonomyLabels.padrao[value];
}

List<Widget> _taxonomyChips(Exercicio exercicio) {
  return [
    if (_modalidadeLabel(exercicio)?.isNotEmpty == true)
      _CompactPill(
        icon: Icons.category_rounded,
        label: _modalidadeLabel(exercicio)!,
      ),
    if (_grupoLabel(exercicio)?.isNotEmpty == true)
      _CompactPill(
        icon: Icons.fitness_center_rounded,
        label: _grupoLabel(exercicio)!,
      ),
    if (_padraoLabel(exercicio)?.isNotEmpty == true)
      _CompactPill(icon: Icons.route_rounded, label: _padraoLabel(exercicio)!),
    for (final equipamento in exercicio.equipamentos)
      _CompactPill(
        icon: Icons.construction_rounded,
        label:
            TaxonomyLabels.equipamento[equipamento] ?? equipamento.backendName,
      ),
    if (_dificuldadeLabel(exercicio)?.isNotEmpty == true)
      _CompactPill(
        icon: Icons.trending_up_rounded,
        label: _dificuldadeLabel(exercicio)!,
      ),
    if (exercicio.unilateral)
      const _CompactPill(icon: Icons.swap_horiz_rounded, label: 'Unilateral'),
  ];
}

Color _trustColor(Exercicio exercicio, Color primary) {
  return switch (exercicio.mediaTrustLevel) {
    'READY' => exercicio.isPersonalUpload ? primary : EagleTokens.good,
    'NO_VIDEO' => EagleTokens.bad,
    _ => EagleTokens.warn,
  };
}

IconData _trustIcon(Exercicio exercicio) {
  return switch (exercicio.mediaTrustLevel) {
    'READY' =>
      exercicio.isPersonalUpload
          ? Icons.workspace_premium_rounded
          : Icons.verified_rounded,
    'NO_VIDEO' => Icons.videocam_off_outlined,
    _ => Icons.rate_review_outlined,
  };
}

String _formatEditorialStatus(String value) {
  return switch (value) {
    'APPROVED' => 'Aprovado',
    'REJECTED' => 'Reprovado',
    _ => 'Pendente',
  };
}

String _editorialActionTitle(String value) {
  return switch (value) {
    'APPROVED' => 'Aprovar midia',
    'REJECTED' => 'Reprovar midia',
    _ => 'Voltar para revisao',
  };
}

class _EditorialReviewPanel extends StatelessWidget {
  final String status;
  final String? notes;
  final DateTime? reviewedAt;
  final ValueChanged<String> onChange;

  const _EditorialReviewPanel({
    required this.status,
    required this.notes,
    required this.reviewedAt,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final color = switch (status) {
      'APPROVED' => EagleTokens.good,
      'REJECTED' => EagleTokens.bad,
      _ => EagleTokens.warn,
    };
    final reviewed =
        reviewedAt == null
            ? null
            : '${reviewedAt!.day.toString().padLeft(2, '0')}/'
                '${reviewedAt!.month.toString().padLeft(2, '0')}/'
                '${reviewedAt!.year}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check_rounded, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Curadoria editorial',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        _formatEditorialStatus(status),
                        if (reviewed != null) 'revisado em $reviewed',
                      ].join(' - '),
                      style: TextStyle(
                        color: mute,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (notes?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              notes!.trim(),
              style: TextStyle(
                color: ink.withValues(alpha: 0.84),
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _EditorialActionButton(
                label: 'Aprovar',
                icon: Icons.verified_rounded,
                selected: status == 'APPROVED',
                onTap: () => onChange('APPROVED'),
              ),
              _EditorialActionButton(
                label: 'Reprovar',
                icon: Icons.block_rounded,
                selected: status == 'REJECTED',
                onTap: () => onChange('REJECTED'),
              ),
              _EditorialActionButton(
                label: 'Revisar',
                icon: Icons.rate_review_rounded,
                selected: status == 'PENDING_REVIEW',
                onTap: () => onChange('PENDING_REVIEW'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorialActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _EditorialActionButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        backgroundColor:
            selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                : null,
      ),
    );
  }
}

class _GuidanceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _GuidanceCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    color: ink.withValues(alpha: 0.82),
                    fontSize: 12.8,
                    height: 1.36,
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

class _MediaMetadataPanel extends StatelessWidget {
  final String? source;
  final String? licenseStatus;

  const _MediaMetadataPanel({
    required this.source,
    required this.licenseStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;
    final licensed = licenseStatus == 'LICENSED';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Icon(
            licensed ? Icons.verified_rounded : Icons.video_library_rounded,
            color:
                licensed
                    ? EagleTokens.good
                    : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  licensed ? 'Video licenciado' : 'Origem do video',
                  style: TextStyle(
                    color: ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (source?.isNotEmpty == true) _formatSource(source!),
                    if (licenseStatus?.isNotEmpty == true)
                      _formatLicense(licenseStatus!),
                  ].join(' | '),
                  style: TextStyle(
                    color: mute,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSource(String value) {
    return switch (value) {
      'FOCUX_LIBRARY' => 'Biblioteca Focux',
      'PERSONAL_UPLOAD' => 'Video do personal',
      _ => value.replaceAll('_', ' '),
    };
  }

  String _formatLicense(String value) {
    return switch (value) {
      'LICENSED' => 'Licenciado',
      'PERSONAL_OWNED' => 'Proprio',
      'PENDING_REVIEW' => 'Pendente',
      _ => value.replaceAll('_', ' '),
    };
  }
}

class _VideoPlayer extends StatefulWidget {
  final String url;
  const _VideoPlayer({required this.url});

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  VideoPlayerController? _ctrl;
  bool _ready = false;
  bool _failed = false;
  int _attempt = 0;
  static const int _maxProcessingAttempts = 10;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(_cloudinaryH264VideoUrl(widget.url)),
    );
    _ctrl = controller;
    if (mounted) {
      setState(() {
        _ready = false;
        _failed = false;
      });
    }

    try {
      await controller.initialize();
      if (mounted && _ctrl == controller) setState(() => _ready = true);
    } catch (_) {
      await controller.dispose();
      if (!mounted || _ctrl != controller) return;
      _ctrl = null;
      if (_attempt < _maxProcessingAttempts) {
        _attempt += 1;
        final delaySeconds = (2 + _attempt).clamp(3, 12);
        await Future<void>.delayed(Duration(seconds: delaySeconds));
        if (mounted) await _loadVideo();
        return;
      }
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Container(
        height: 180,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_file_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 34,
            ),
            const SizedBox(height: 10),
            const Text(
              'Video enviado, mas a previa ainda nao ficou disponivel.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Tente abrir novamente em instantes. Se persistir, use MP4 H.264.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
    }
    if (!_ready) {
      return const SizedBox(height: 200, child: FxLoading());
    }
    final controller = _ctrl;
    if (controller == null) return const SizedBox.shrink();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
              onPressed:
                  () => setState(() {
                    controller.value.isPlaying
                        ? controller.pause()
                        : controller.play();
                  }),
            ),
          ],
        ),
      ],
    );
  }
}

String _cloudinaryH264VideoUrl(String rawUrl) {
  final url = rawUrl.trim();
  const marker = '/video/upload/';
  if (!url.contains(marker)) return url;

  final delivery = url.substring(url.indexOf(marker) + marker.length);
  if (delivery.startsWith('f_mp4') ||
      delivery.startsWith('vc_h264') ||
      delivery.startsWith('vc_auto')) {
    return url;
  }

  return url.replaceFirst(marker, '${marker}f_mp4,vc_h264/');
}

class _OwnVideoPanel extends StatelessWidget {
  final bool hasVideo;
  final bool uploading;
  final VoidCallback onUpload;

  const _OwnVideoPanel({
    required this.hasVideo,
    required this.uploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.line;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasVideo ? Icons.verified_rounded : Icons.video_call_rounded,
              color: primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasVideo ? 'Video proprio ativo' : 'Adicionar video proprio',
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasVideo
                      ? 'Use sua demonstracao para gerar mais confianca no aluno.'
                      : 'Suba uma demonstracao sua para diferenciar este exercicio.',
                  style: TextStyle(
                    color: mute,
                    fontSize: 12.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: uploading ? null : onUpload,
            icon:
                uploading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: FxLoading(strokeWidth: 2, color: Colors.white),
                    )
                    : Icon(
                      hasVideo ? Icons.sync_rounded : Icons.upload_rounded,
                      size: 17,
                    ),
            label: Text(hasVideo ? 'Trocar' : 'Enviar'),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(92, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
