part of 'plano_alimentar_detail_screen.dart';

extension on _PlanoAlimentarDetailScreenState {
  Future<void> _abrirNovaRefeicao() async {
    if (_plano == null) return;
    HapticFeedback.selectionClick();
    final nome = TextEditingController();
    final horario = TextEditingController();
    final cal = TextEditingController();
    final prot = TextEditingController();
    final carbo = TextEditingController();
    final gord = TextEditingController();
    final alimentos = TextEditingController();
    var created = false;

    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Nova refeição',
        subtitle: 'Adicione horário, macros e alimentos.',
        icon: Icons.restaurant_outlined,
        confirmLabel: 'Adicionar refeição',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlunoInsetFormField(
              controller: nome,
              label: 'Nome da refeição',
              icon: Icons.title_outlined,
            ),
            AlunoInsetFormField(
              controller: horario,
              label: 'Horário (ex: 07:30)',
              icon: Icons.schedule_outlined,
            ),
            AlunoInsetFormField(
              controller: cal,
              label: 'Calorias (kcal)',
              icon: Icons.local_fire_department_outlined,
              keyboardType: TextInputType.number,
            ),
            AlunoInsetFormField(
              controller: prot,
              label: 'Proteína (g)',
              icon: Icons.egg_outlined,
              keyboardType: TextInputType.number,
            ),
            AlunoInsetFormField(
              controller: carbo,
              label: 'Carboidrato (g)',
              icon: Icons.breakfast_dining_outlined,
              keyboardType: TextInputType.number,
            ),
            AlunoInsetFormField(
              controller: gord,
              label: 'Gordura (g)',
              icon: Icons.water_drop_outlined,
              keyboardType: TextInputType.number,
            ),
            AlunoInsetFormField(
              controller: alimentos,
              label: 'Alimentos',
              icon: Icons.notes_outlined,
              maxLines: 4,
              showDivider: false,
            ),
          ],
        ),
      );
      if (ok != true) return;
      if (!mounted) return;
      final plano = _plano;
      if (plano == null) return;
      if (nome.text.trim().isEmpty) {
        FeedbackHelper.showWarn(context, 'Nome da refeição é obrigatório.');
        return;
      }
      await AlimentarRepository(ref.read(apiClientProvider)).criarRefeicao(
        widget.alunoId,
        plano.id,
        {
          'nomeRefeicao': nome.text.trim(),
          if (horario.text.isNotEmpty) 'horario': horario.text.trim(),
          if (cal.text.isNotEmpty) 'calorias': int.tryParse(cal.text),
          if (prot.text.isNotEmpty) 'proteinaG': int.tryParse(prot.text),
          if (carbo.text.isNotEmpty) 'carboG': int.tryParse(carbo.text),
          if (gord.text.isNotEmpty) 'gorduraG': int.tryParse(gord.text),
          if (alimentos.text.isNotEmpty) 'alimentos': alimentos.text.trim(),
        },
      );
      created = true;
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      nome.dispose();
      horario.dispose();
      cal.dispose();
      prot.dispose();
      carbo.dispose();
      gord.dispose();
      alimentos.dispose();
    }
    if (created) await _load();
  }

  Future<void> _abrirGerarIa() async {
    if (_plano == null) return;
    final objetivoCtrl = TextEditingController(text: 'Hipertrofia');
    final calCtrl = TextEditingController(text: '2500');
    final refCtrl = TextEditingController(text: '4');

    try {
      final confirm = await showFxFormSheet(
        context,
        title: 'Gerar dieta com IA',
        subtitle:
            'A IA cria refeições estruturadas e adiciona neste plano. Você confirma antes.',
        icon: Icons.auto_awesome,
        confirmLabel: 'Gerar',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlunoInsetFormField(
              controller: objetivoCtrl,
              label: 'Objetivo',
              icon: Icons.flag_outlined,
              hint: 'Ex: Hipertrofia',
            ),
            AlunoInsetFormField(
              controller: calCtrl,
              label: 'Calorias alvo',
              icon: Icons.local_fire_department_outlined,
              keyboardType: TextInputType.number,
            ),
            AlunoInsetFormField(
              controller: refCtrl,
              label: 'Nº de refeições',
              icon: Icons.restaurant_outlined,
              keyboardType: TextInputType.number,
              showDivider: false,
            ),
          ],
        ),
      );

      if (confirm != true) return;
      if (!mounted) return;
      final plano = _plano;
      if (plano == null) return;
      if (!await IaQuotaUpgrade.guardBeforeRequest(context, ref)) return;

      setState(() => _loading = true);
      await AlimentarRepository(ref.read(apiClientProvider)).gerarDietaIa(
        widget.alunoId,
        plano.id,
        objetivo: objetivoCtrl.text,
        caloriasAlvo: int.tryParse(calCtrl.text),
        numeroRefeicoes: int.tryParse(refCtrl.text),
      );
      if (!mounted) return;
      await _load();
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Dieta gerada com sucesso!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        FeedbackHelper.showError(context, friendlyError(e));
        final mapped =
            e is DioException ? IaOperationalException.fromDio(e) : e;
        await IaQuotaUpgrade.handleError(context, ref, mapped);
      }
    } finally {
      objetivoCtrl.dispose();
      calCtrl.dispose();
      refCtrl.dispose();
    }
  }
}
