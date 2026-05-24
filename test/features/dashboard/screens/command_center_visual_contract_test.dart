import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('command center autonomy bottlenecks keep compact layout safe', () {
    final widget =
        File(
          'lib/features/dashboard/screens/personal_dashboard_screen.dart',
        ).readAsStringSync();

    expect(widget, contains('class _CommandCenterSection'));
    expect(widget, contains('commandCenterProvider'));
    expect(widget, contains('chatInboxProvider'));
    expect(widget, contains("'Central de Comando'"));
    expect(widget, contains('A melhor próxima ação'));
    expect(widget, contains('class _CommandActionPanel'));
    expect(widget, contains('class _CommandActionTile'));
    expect(widget, contains('_showCommandActionsSheet'));
    expect(widget, contains("PageStorageKey('personal-command-modules')"));
    expect(widget, contains('scrollDirection: Axis.horizontal'));
    expect(widget, contains('Shimmer.fromColors'));
    expect(widget, contains('maxLines: 2'));
    expect(widget, contains('TextOverflow.ellipsis'));
    expect(widget, contains('class _DayPulseStrip'));
    expect(widget, contains('class _PulseChip'));
    expect(widget, contains('Pulso operacional'));
    expect(widget, contains('BoxConstraints(minHeight: 48)'));
    expect(widget, contains('hideRiscoChip'));
    expect(widget, contains('retomada urgente'));
    expect(widget, isNot(contains('_RiskWaveBanner')));
    expect(widget, contains('_AderenciaSemanaEmptyCard'));
    expect(widget, contains('_isRiskEchoCopy'));
    expect(widget, contains('BrandPalette.sectionHeading'));
    expect(widget, contains('BrandPalette.sectionAction'));
  });
}
