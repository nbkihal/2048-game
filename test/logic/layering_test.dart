import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// CLAUDE.md §12: `logic/` is pure Dart. If a Material import ever sneaks in,
/// the rules have leaked into the UI layer — fail loudly rather than at review
/// time.
void main() {
  test('no file in lib/logic imports Flutter', () {
    final logicDir = Directory('lib/logic');
    expect(logicDir.existsSync(), isTrue, reason: 'lib/logic is missing');

    final offenders = <String>[];
    for (final entity in logicDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains("package:flutter/") || source.contains('dart:ui')) {
        offenders.add(entity.path);
      }
    }

    expect(offenders, isEmpty);
  });

  test('no file in lib/models imports Flutter', () {
    final offenders = <String>[];
    for (final entity in Directory('lib/models').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.readAsStringSync().contains("package:flutter/")) {
        offenders.add(entity.path);
      }
    }

    expect(offenders, isEmpty);
  });
}
