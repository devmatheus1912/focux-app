import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('avatar da Home usa anel da marca, não accent clareado', () {
    final source =
        File(
          'lib/features/dashboard/widgets/dashboard_header_profile_avatar.dart',
        ).readAsStringSync();

    expect(source, contains('BrandPalette.softened(primary)'));
    expect(source, isNot(contains('BrandPalette.accent(primary)')));
    expect(source, contains('Border.all'));
  });
}
