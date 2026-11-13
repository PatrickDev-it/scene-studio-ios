import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scene_studio/scene_data.dart';
import 'package:windows_file_picker/windows_file_picker.dart';

class FakeWindowsPicker extends FilePickerPlatform {
  String? nextPath;
  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    if (nextPath == null) return null;
    return WindowsPlatformFile.fromPath(File(nextPath!).absolute.path);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'importa e copia esattamente video e immagine tramite risultato Windows',
    () async {
      final picker = FakeWindowsPicker();
      final previous = FilePickerPlatform.instance;
      FilePickerPlatform.instance = picker;
      final scratch = await Directory('test/fixtures/import_check')
          .create(recursive: true);
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (call) async => scratch.absolute.path,
          );
      addTearDown(() {
        FilePickerPlatform.instance = previous;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      for (final input in [
        ('test/fixtures/sample.mp4', true),
        ('test/fixtures/sample.png', false),
      ]) {
        picker.nextPath = input.$1;
        final result = await SceneStore.importFile(video: input.$2);
        expect(result, isNotNull);
        expect(
          await File(result!).readAsBytes(),
          await File(input.$1).readAsBytes(),
        );
        expect(result, startsWith(scratch.absolute.path));
      }
      picker.nextPath = null;
      expect(await SceneStore.importFile(video: true), isNull);
    },
  );
}
