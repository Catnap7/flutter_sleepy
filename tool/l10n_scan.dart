// A simple l10n hardcoded-string scanner for lib/** (excluding lib/l10n/**).
// Usage:
//   dart run tool/l10n_scan.dart [--fail-on-found]
//
// Flags:
//   --fail-on-found  Exit with code 1 if any findings are reported.
//
// Heuristics:
// - Korean characters: [\uac00-\ud7af]
// - Likely English UI phrases at line start: ^(How|Play|Back|Timer|Fade|Wave|Rain|Campfire|Forest|Sleep|Noise|Settings)\b
// - Ignore lines containing: // l10n:ignore, debugPrint, print(, logger.
// - Skip any files under lib/l10n/** and any *.g.dart generated files.

import 'dart:convert';
import 'dart:io';

final _korean = RegExp(r"[\uac00-\ud7af]");
final _englishUi = RegExp(r"^(\s*)(How|Play|Back|Timer|Fade|Wave|Rain|Campfire|Forest|Sleep|Noise|Settings)\b");

bool _shouldSkip(String path) {
  if (!path.startsWith('lib/')) return true;
  if (path.startsWith('lib/l10n/')) return true;
  if (path.endsWith('.g.dart')) return true;
  return false;
}

Future<void> main(List<String> args) async {
  final failOnFound = args.contains('--fail-on-found');
  final findings = <String>[];

  final libDir = Directory('lib');
  if (!await libDir.exists()) {
    stderr.writeln('No lib/ directory found.');
    exit(2);
  }

  await for (final entity in libDir.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final path = entity.path.replaceAll('\\', '/');
    if (!path.endsWith('.dart')) continue;
    if (_shouldSkip(path)) continue;

    final lines = const LineSplitter().convert(await entity.readAsString());
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final displayLineNo = i + 1;

      // Ignore directives/comments/logging
      if (line.contains('// l10n:ignore')) continue;
      if (line.contains('debugPrint') || line.contains(' print(') || line.contains('logger')) continue;

      // Skip import/export/part directives as they may contain words like "How"
      if (line.trimLeft().startsWith('import ') || line.trimLeft().startsWith('export ') || line.trimLeft().startsWith('part ')) {
        continue;
      }

      // crude check: lines containing quoted strings
      final hasQuote = line.contains("'") || line.contains('"');
      if (!hasQuote) continue;

      final isKorean = _korean.hasMatch(line);
      final startsWithUiWord = _englishUi.hasMatch(line);

      if (isKorean || startsWithUiWord) {
        findings.add('$path:$displayLineNo:$line'.trim());
      }
    }
  }

  if (findings.isEmpty) {
    stdout.writeln('l10n-scan: 0 findings.');
    return;
  }

  stdout.writeln('l10n-scan findings:');
  for (final f in findings) {
    stdout.writeln(' - $f');
  }
  if (failOnFound) exit(1);
}

