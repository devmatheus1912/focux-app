import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/offline_drain_scheduler.dart';

class _FakeQueue {
  int pending = 0;
  int drains = 0;
  Completer<void>? gate;

  Future<int> count() async => pending;

  Future<void> drain() async {
    drains++;
    final g = gate;
    if (g != null) await g.future;
  }
}

const _interval = Duration(seconds: 60);

void main() {
  late _FakeQueue queue;
  late OfflineDrainScheduler scheduler;

  setUp(() {
    queue = _FakeQueue();
    scheduler = OfflineDrainScheduler(
      pendingCount: queue.count,
      drain: queue.drain,
      interval: _interval,
    );
  });

  tearDown(() => scheduler.dispose());

  testWidgets('fila vazia: nenhum timer e nenhuma drenagem', (tester) async {
    await scheduler.onQueueChanged();
    await scheduler.onResumed();

    expect(scheduler.hasTimer, isFalse);
    expect(queue.drains, 0);
  });

  testWidgets('item na fila: drena ao voltar ao primeiro plano', (
    tester,
  ) async {
    queue.pending = 1;

    await scheduler.onResumed();

    expect(queue.drains, 1);
    expect(scheduler.hasTimer, isTrue);
    scheduler.dispose();
  });

  testWidgets('item na fila: drena a cada intervalo e para ao esvaziar', (
    tester,
  ) async {
    queue.pending = 2;
    await scheduler.onQueueChanged();
    expect(scheduler.hasTimer, isTrue);
    expect(queue.drains, 0);

    await tester.pump(_interval);
    expect(queue.drains, 1);

    await tester.pump(_interval);
    expect(queue.drains, 2);

    queue.pending = 0;
    await tester.pump(_interval);
    expect(queue.drains, 2);
    expect(scheduler.hasTimer, isFalse);
  });

  testWidgets('segundo plano desliga o timer; resume religa', (tester) async {
    queue.pending = 1;
    await scheduler.onQueueChanged();
    expect(scheduler.hasTimer, isTrue);

    scheduler.onBackground();
    expect(scheduler.hasTimer, isFalse);
    await scheduler.onQueueChanged();
    expect(scheduler.hasTimer, isFalse);
    await tester.pump(_interval * 2);
    expect(queue.drains, 0);

    await scheduler.onResumed();
    expect(queue.drains, 1);
    expect(scheduler.hasTimer, isTrue);
    scheduler.dispose();
  });

  testWidgets('single-flight: resume durante drenagem não drena de novo', (
    tester,
  ) async {
    queue.pending = 1;
    queue.gate = Completer<void>();

    final first = scheduler.onResumed();
    await tester.pump();
    final second = scheduler.onResumed();
    await tester.pump(_interval);
    expect(queue.drains, 1);

    queue.gate!.complete();
    queue.gate = null;
    await first;
    await second;
    expect(queue.drains, 1);
    scheduler.dispose();
  });
}
