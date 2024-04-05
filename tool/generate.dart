#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

const _generatedCodePointMapPath = 'generated/CarbonFonts.json';
const _generatedTtfPath = 'generated/CarbonFonts.ttf';
const _generatedOutputFilePath = 'generated/carbon_fonts.dart';
const _destinationTtfPathFromRoot = 'assets/CarbonFonts.ttf';
const _destinationOutputPathFromRoot = 'lib/src/fonts/carbon_fonts.dart';

const _ignoredKeywords = <String, String>{
  '1st': 'first_1st',
  '2nd': 'second_2nd',
  '3rd': 'third_3rd',
  '2d': 'two_d',
  '3d': 'three_d',
  '3g': 'three_g',
  '4g': 'four_g',
  '5g': 'five_g',
  '2k': 'two_k',
  '4k': 'four_k',
  'continue': 'continue_symbol'
};

const _template = '''
// Generated code - do not modify!

import 'package:flutter/widgets.dart';

part 'package:carbon_icons/src/widgets/icon_data.dart';

class CarbonIcons {
  CarbonIcons._();


''';

final _buildDir = Directory('build');

Future<void> main() async {
  if (path.basename(Directory.current.path) != 'tool') {
    print('Please run this script from the `tool` directory.');
    exit(1);
  }

  _ensureInstalled(
    command: 'fantasticon',
    installationCommand: 'npm install -g fantasticon',
  );
  _ensureInstalled(
    command: 'svgo',
    installationCommand: 'npm install -g svgo',
  );

  if (_buildDir.existsSync()) {
    print('Cleaning up previous build directory...');
    _buildDir.deleteSync(recursive: true);
  }
  _buildDir.createSync();

  print('Copying SVGs...');
  _copySvgs();

  print('Cleaning SVGs...');
  _runCommand('svgo -f ${_buildDir.path} -o ${_buildDir.path}');

  print('Generating font...');
  await _runCommand('fantasticon --config fantasticon_config.js');

  print('Generating IconData from TTF...');
  _generateIconData();

  print('Formatting generated code...');
  await _runCommand('dart format $_generatedOutputFilePath');

  print('Copying output files to the package...');
  _copyOutputFiles();

  print('Done!');
}

/// Copies the generated files to the package.
void _copyOutputFiles() {
  for (final move in {
    _generatedTtfPath: _destinationTtfPathFromRoot,
    _generatedOutputFilePath: _destinationOutputPathFromRoot,
  }.entries) {
    final source = move.key;
    final destination = move.value;

    final sourceFile = File(source);
    final destinationFile =
        File(path.join(Directory.current.parent.path, destination));

    if (!sourceFile.existsSync()) {
      throw Exception('Could not find file: $source');
    }

    sourceFile.copySync(destinationFile.path);

    print('Copied $source to $destination. Deleting $source...');
    sourceFile.deleteSync();
  }
}

/// The mapping of SVG folder names to SVG file name suffixes.
///
/// Every key is a directory name in the `svg` directory. When a directory
/// is found, the script will look for SVG files in that directory and
/// add the corresponding suffix to the icon name.
///
/// ```
/// svg/line/arrow.svg => CarbonIcons.arrow
/// svg/solid/arrow.svg => CarbonIcons.arrow_filled
/// ```
const _svgSuffixMapping = {
  'solid': '_filled',
};

/// Prepares the SVGs by copying files from the `svg` directory to the
/// `build/svg` directory. Before doing so, all SVGs are aggregated and renamed
/// if necessary.
void _copySvgs() {
  final svgDirs = Directory('svg').listSync().whereType<Directory>();
  for (final svgDir in svgDirs) {
    final svgFiles = svgDir.listSync().whereType<File>().where((file) {
      final ext = path.extension(file.path);
      return ext == '.svg';
    }).toList();

    final svgFileSuffix = _svgSuffixMapping[path.basename(svgDir.path)] ?? '';

    for (final svgFile in svgFiles) {
      final currentSvgBasename = path.basenameWithoutExtension(svgFile.path);
      var newSvgBasename =
          currentSvgBasename.toLowerCase().replaceAll('-', '_') + svgFileSuffix;

      for (final entry in _ignoredKeywords.entries) {
        final key = entry.key;
        if (newSvgBasename.startsWith(key)) {
          newSvgBasename = newSvgBasename.replaceFirst(key, entry.value);
          break;
        }
      }

      final newSvgPath = path.join(_buildDir.path, '$newSvgBasename.svg');
      svgFile.copySync(newSvgPath);
    }
  }
}

String _getFontData(String iconName, int codePoint) {
  final radix16 = codePoint.toRadixString(16).toUpperCase();
  return 'static const IconData $iconName = _CarbonIconData(0x$radix16);';
}

void _ensureInstalled({
  required String command,
  required String installationCommand,
}) {
  try {
    _runCommand('command -v $command');
  } catch (_) {
    print(
      '''
This script requires `$command` to be installed. Please run:

  $installationCommand
  
Aborting.''',
    );
    exit(1);
  }
}

/// Generates the IconData class from the TTF file.
void _generateIconData() {
  final codePointMapFile = File(_generatedCodePointMapPath);

  if (!codePointMapFile.existsSync()) {
    throw ("Could not find 'generated/CarbonFonts.json' file.");
  }

  final fileContent = codePointMapFile.readAsStringSync();
  final codePointMap = json.decode(fileContent) as Map<String, dynamic>;

  final fontBuffer = StringBuffer(_template);

  for (final entry in codePointMap.entries) {
    fontBuffer.writeln(_getFontData(entry.key, entry.value));
  }

  fontBuffer.write('}');

  final generatedOutput = File(_generatedOutputFilePath);
  generatedOutput.writeAsStringSync(fontBuffer.toString());
}

Future<void> _runCommand(String command) async {
  final result = await Process.run('bash', ['-c', command]);
  if (result.exitCode != 0) {
    throw Exception(
      'Error running command: $command\n\n${result.stderr}\n${result.stdout}',
    );
  }
}
