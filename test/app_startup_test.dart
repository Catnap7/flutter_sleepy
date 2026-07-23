import 'dart:async';

import 'package:flutter_sleepy/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('best-effort startup continues when one task fails', () async {
    var completed = false;

    await runBestEffortStartupTasks([
      (label: 'failure', run: () async => throw StateError('expected')),
      (label: 'success', run: () async => completed = true),
    ]);

    expect(completed, isTrue);
  });

  test('best-effort startup bounds a stalled task', () async {
    final stopwatch = Stopwatch()..start();

    await runBestEffortStartupTasks(
      [(label: 'stall', run: () => Completer<void>().future)],
      timeout: const Duration(milliseconds: 20),
    );

    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
  });
}
