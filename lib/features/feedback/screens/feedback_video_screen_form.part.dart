part of 'feedback_video_screen.dart';

extension on _FeedbackVideoScreenState {
  Future<void> _novoFeedback() async {
    HapticFeedback.selectionClick();
    var alunoId = widget.alunoId;
    var alunoNome = widget.alunoNome?.trim() ?? '';
    if (alunoId == null) {
      try {
        final home = await ref.read(alunosHomeProvider.future);
        if (!mounted) return;
        final alunos = filterAlunoPickerAlunos(home.alunos, '');
        if (alunos.isEmpty) {
          FeedbackHelper.showError(context, 'Cadastre um aluno primeiro.');
          return;
        }
        final picked = await showFxInsetPickerSheet<int>(
          context,
          title: 'Aluno',
          items: [
            for (final a in alunos)
              FxInsetPickerSheetItem(
                value: a.id,
                label: a.nome,
                subtitle: a.email.trim().isEmpty ? null : a.email,
              ),
          ],
        );
        if (picked == null || !mounted) return;
        for (final a in alunos) {
          if (a.id == picked) {
            alunoId = a.id;
            alunoNome = a.nome;
            break;
          }
        }
      } catch (e) {
        if (!mounted) return;
        FeedbackHelper.showError(context, friendlyError(e));
        return;
      }
    }
    final selectedAlunoId = alunoId;
    if (selectedAlunoId == null) return;

    late final int selectedExercicioId;
    var exercicioNome = 'Exercício';
    try {
      final picker = await ref
          .read(exercicioRepositoryProvider)
          .listarPickerPagina(size: 30);
      if (!mounted) return;
      if (picker.content.isEmpty) {
        FeedbackHelper.showError(context, 'Cadastre um exercício primeiro.');
        return;
      }
      final pickedEx = await showFxInsetPickerSheet<int>(
        context,
        title: 'Exercício',
        items: [
          for (final e in picker.content)
            FxInsetPickerSheetItem(value: e.id, label: e.nome),
        ],
      );
      if (pickedEx == null || !mounted) return;
      selectedExercicioId = pickedEx;
      for (final e in picker.content) {
        if (e.id == pickedEx) {
          exercicioNome = e.nome;
          break;
        }
      }
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
      return;
    }

    final videoUrlCtrl = TextEditingController();
    final comentarioCtrl = TextEditingController();
    var created = false;

    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Novo feedback de vídeo',
        subtitle: alunoNome.isEmpty
            ? exercicioNome
            : 'Para ${satelliteFirstName(alunoNome)} · $exercicioNome',
        icon: Icons.videocam_outlined,
        confirmLabel: 'Salvar',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlunoInsetFormField(
              controller: videoUrlCtrl,
              label: 'URL do vídeo',
              icon: Icons.link_outlined,
              hint: 'Cloudinary, YouTube…',
            ),
            AlunoInsetFormField(
              controller: comentarioCtrl,
              label: 'Comentário técnico',
              icon: Icons.notes_outlined,
              maxLines: 3,
              showDivider: false,
            ),
          ],
        ),
      );
      if (ok != true) return;
      final video = videoUrlCtrl.text.trim();
      final com = comentarioCtrl.text.trim();
      if (video.isEmpty || com.isEmpty) {
        if (mounted) {
          FeedbackHelper.showError(context, 'Preencha todos os campos');
        }
        return;
      }
      await FeedbackVideoRepository(ref.read(apiClientProvider)).registrar(
        alunoId: selectedAlunoId,
        exercicioId: selectedExercicioId,
        videoUrl: video,
        comentario: com,
      );
      created = true;
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      videoUrlCtrl.dispose();
      comentarioCtrl.dispose();
    }
    if (created) await _load(reset: true);
  }
}
