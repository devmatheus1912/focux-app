import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _alunoDetailLibrarySource() {
  const dir = 'lib/features/alunos/screens';
  const mainFile = '$dir/aluno_detail_screen.dart';
  final main = File(mainFile).readAsStringSync();
  final partPattern = RegExp(r"part '([^']+\.part\.dart)';");
  final parts = partPattern
      .allMatches(main)
      .map((m) => File('$dir/${m.group(1)!}').readAsStringSync())
      .join('\n');
  return '$main\n$parts';
}

void main() {
  test('aluno detail exposes 360 view and prescriptive copilot actions', () {
    final screen = _alunoDetailLibrarySource();

    expect(screen, contains('class _Aluno360CopilotCard'));
    expect(screen, contains('Aluno 360'));
    expect(screen, contains('class _Aluno360TimelineCard'));
    expect(screen, contains("'Linha do tempo 360'"));
    expect(screen, contains('alunoScoreSnapshotsProvider'));
    expect(screen, contains('getFocuxScoreSnapshots(alunoId)'));
    expect(screen, contains('class _Timeline360Tile'));
    expect(screen, contains('alunoCopilotoActionProvider'));
    expect(screen, contains('proximaAcao(alunoId)'));
    expect(screen, contains('salvarAcaoCopiloto'));
    expect(screen, contains('commandCenterProvider'));
    expect(screen, contains('class _Aluno360SignalTile'));
    expect(screen, contains('class _CopilotPrescription'));
    expect(screen, contains('Clipboard.setData'));
    expect(screen, contains('_mensagemPronta'));
    expect(screen, contains("'Criar tarefa'"));
    expect(screen, contains("'Copiar'"));
    expect(screen, contains("'Mensagem sugerida'"));
    expect(screen, contains("'Abrir chat'"));
    expect(screen, contains('perfil, autonomia e financeiro'));
  });

  test('aluno 360 polish: unified status, refresh, altura, sparkline', () {
    final screen = _alunoDetailLibrarySource();

    expect(screen, contains('class _AlunoOperationalStatusSection'));
    expect(screen, contains('Status operacional'));
    expect(screen, contains('Índice operacional'));
    expect(screen, contains('Sinais atualizados para priorizar sua ação'));
    expect(screen, contains('Sugestão offline'));
    expect(screen, contains('invalidateAluno360Providers'));
    expect(screen, contains('alunoAderenciaSemanalProvider'));
    expect(screen, contains('class _WeeklyActivitySparkline'));
    expect(screen, contains('formatAlturaDisplay'));
    expect(screen, contains('friendlyError'));
    expect(screen, isNot(contains('Pulso operacional')));
    expect(screen, isNot(contains('Score API')));
  });
}
