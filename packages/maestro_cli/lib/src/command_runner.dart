import 'package:args/command_runner.dart';
import 'package:maestro_cli/src/commands/bootstrap_command.dart';
import 'package:maestro_cli/src/commands/clean_command.dart';
import 'package:maestro_cli/src/commands/drive_command.dart';
import 'package:maestro_cli/src/common/logging.dart';
import 'package:maestro_cli/src/common/paths.dart';

Future<int> maestroCommandRunner(List<String> args) async {
  final runner = MaestroCommandRunner();

  var exitCode = 0;
  try {
    exitCode = await runner.run(args) ?? 0;
  } on UsageException catch (err) {
    log.severe('Error: ${err.message}');
    exitCode = 1;
  }

  return exitCode;
}

class MaestroCommandRunner extends CommandRunner<int> {
  MaestroCommandRunner()
      : super(
          'maestro',
          'Tool for running Flutter-native UI tests with superpowers',
        ) {
    addCommand(BootstrapCommand());
    addCommand(DriveCommand());
    addCommand(CleanCommand());

    argParser.addFlag('verbose', abbr: 'v', help: 'Increase logging.');
  }

  @override
  Future<int?> run(Iterable<String> args) async {
    final results = argParser.parse(args);
    final verbose = results['verbose'] as bool;
    final help = results['help'] as bool;
    setUpLogger(verbose: verbose);

    if (!results.arguments.contains('clean') && !help) {
      await _ensureArtifactsArePresent();
    }

    return super.run(args);
  }
}

Future<void> _ensureArtifactsArePresent() async {
  if (areArtifactsPresent()) {
    return;
  }

  final progress = log.progress('Downloading artifacts');
  try {
    await downloadArtifacts();
  } catch (err, st) {
    progress.fail('Failed to download artifacts');
    log.severe(null, err, st);
  }

  progress.complete('Downloaded artifacts');
}