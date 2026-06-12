import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/treinos_list_labels.dart';

void main() {
  test('readyPlans pluralizes correctly', () {
    expect(TreinosListLabels.readyPlans(1), '1 plano pronto para uso.');
    expect(TreinosListLabels.readyPlans(3), '3 planos prontos para uso.');
  });

  test('readyCount and templateCount pluralize correctly', () {
    expect(TreinosListLabels.readyCount(1), '1 pronto');
    expect(TreinosListLabels.readyCount(2), '2 prontos');
    expect(TreinosListLabels.templateCount(1), '1 template');
    expect(TreinosListLabels.templateCount(4), '4 templates');
  });
}
