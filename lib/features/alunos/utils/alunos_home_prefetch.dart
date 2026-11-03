import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/alunos_provider.dart';

void prefetchAlunosHome(WidgetRef ref) {
  unawaited(_ignoreErrors(ref.read(alunosHomeProvider.future)));
}

Future<void> _ignoreErrors(Future<dynamic> future) async {
  try {
    await future;
  } catch (_) {}
}
