import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../constants/aluno_360_layout.dart';
import '../data/aluno_repository.dart';
import '../utils/aluno360_ferramentas_grupos.dart';
import 'aluno360_entrance.dart';

/// Aba Ferramentas: os módulos em grupos e os dados do cadastro. Quando falta
/// algum dado, "Dados do aluno" abre a aba; completo, vai para o fim.
class Aluno360FerramentasTab extends StatelessWidget {
  const Aluno360FerramentasTab({
    super.key,
    required this.aluno,
    required this.alunoId,
    required this.gruposSection,
    this.animateEntrance = false,
    this.onEntrancePlayed,
  });

  final Aluno aluno;
  final int alunoId;
  final Widget gruposSection;
  final bool animateEntrance;
  final VoidCallback? onEntrancePlayed;

  Widget _section(int step, Widget child) {
    return Aluno360OperacaoEntrance(
      enabled: animateEntrance,
      delay: Duration(milliseconds: step * 40),
      onPlayed: onEntrancePlayed,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dados = _section(
      0,
      Aluno360DadosDoAlunoGrupo(aluno: aluno, alunoId: alunoId),
    );
    final grupos = _section(1, gruposSection);
    final dadosPrimeiro = aluno360DadosIncompletos(aluno);

    return Semantics(
      container: true,
      label: 'Ferramentas do aluno: dados do cadastro e módulos de ação',
      child: Aluno360Layout.operacaoContentWidthLimiter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            dadosPrimeiro ? dados : grupos,
            const SizedBox(height: FxSettingsLayout.groupGap),
            dadosPrimeiro ? grupos : dados,
          ],
        ),
      ),
    );
  }
}

/// "Dados do aluno": contato, objetivo, nascimento e altura, mais o verbo
/// "Editar cadastro". Cada linha abre o cadastro.
class Aluno360DadosDoAlunoGrupo extends StatelessWidget {
  const Aluno360DadosDoAlunoGrupo({
    super.key,
    required this.aluno,
    required this.alunoId,
  });

  final Aluno aluno;
  final int alunoId;

  static IconData _icone(Aluno360DadoCampo c) => switch (c) {
    Aluno360DadoCampo.contato => Icons.phone_outlined,
    Aluno360DadoCampo.objetivo => Icons.flag_outlined,
    Aluno360DadoCampo.nascimento => Icons.cake_outlined,
    Aluno360DadoCampo.altura => Icons.height_outlined,
  };

  static String _rotulo(S s, Aluno360DadoCampo c) => switch (c) {
    Aluno360DadoCampo.contato => s.aluno360DadoContato,
    Aluno360DadoCampo.objetivo => s.aluno360DadoObjetivo,
    Aluno360DadoCampo.nascimento => s.aluno360DadoNascimento,
    Aluno360DadoCampo.altura => s.aluno360DadoAltura,
  };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    void editar() => context.push('/alunos/$alunoId/editar', extra: aluno);
    final linhas = aluno360DadosDoAluno(aluno);

    return FxSettingsGroup(
      key: const ValueKey('aluno360_dados_do_aluno'),
      header: s.aluno360DadosGrupo,
      caption: s.aluno360DadosLegenda,
      children: [
        for (final l in linhas)
          FxSettingsTile(
            icon: _icone(l.campo),
            label: _rotulo(s, l.campo),
            value: l.valor ?? s.aluno360DadoInformar,
            highlight: !l.completo,
            mute: chrome.mute,
            line: chrome.line,
            onTap: editar,
          ),
        FxSettingsTile(
          icon: Icons.edit_outlined,
          label: s.aluno360DadosEditar,
          subtitle: s.aluno360DadosEditarDetalhe,
          value: '',
          mute: chrome.mute,
          line: chrome.line,
          showDivider: false,
          onTap: editar,
        ),
      ],
    );
  }
}
