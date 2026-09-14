import 'package:flutter_test/flutter_test.dart';

import 'package:focux_app/core/config/env.dart';

void main() {
  test('public URL helpers build landing and captura paths', () {
    expect(Env.landingPageUrl('joao'), 'https://focuxpersonal.com/p/joao');
    expect(Env.capturaPageUrl('joao'), 'https://focuxpersonal.com/c/joao');
    expect(Env.alunoLoginUrl('joao'), 'https://focuxpersonal.com/p/joao');
    expect(Env.landingPageDisplayLabel('joao'), 'focuxpersonal.com/p/joao');
    expect(Env.publicWebDisplayHost, 'focuxpersonal.com');
  });
}
