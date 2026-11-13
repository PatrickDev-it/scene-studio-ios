import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scene_studio/main.dart' show PostCover;
import 'package:scene_studio/scene_data.dart';
import 'package:scene_studio/simulation.dart';
import 'package:video_player/video_player.dart';

import '../test/import_test.dart' show FakeWindowsPicker;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Windows: importa MP4 e riproduce dal file copiato', (
    tester,
  ) async {
    final picker = FakeWindowsPicker();
    picker.nextPath = File('test/fixtures/sample.mp4').absolute.path;
    expect(File(picker.nextPath!).existsSync(), isTrue);
    FilePickerPlatform.instance = picker;
    final path = await SceneStore.importFile(video: true);
    expect(path, isNotNull);
    expect(
      await File(path!).readAsBytes(),
      await File(picker.nextPath!).readAsBytes(),
    );
    final scene = SceneData.demo()..posts.first.video = path;
    await tester.pumpWidget(MaterialApp(home: Simulator(data: scene)));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PostCover).first);
    final video = find.byType(VideoPlayer);
    for (var attempt = 0; attempt < 30 && video.evaluate().isEmpty; attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(video, findsOneWidget);
    final controller = tester.widget<VideoPlayer>(video).controller;
    expect(controller.value.isInitialized, isTrue);
    expect(controller.value.duration.inMilliseconds, greaterThan(0));
    expect(controller.value.isPlaying, isTrue);

    await tester.tap(find.text('More insights'));
    await tester.pumpAndSettle();
    expect(controller.value.isPlaying, isFalse);
    await tester.tap(find.byTooltip('Back').last);
    await tester.pumpAndSettle();
    expect(controller.value.isPlaying, isTrue);

    await tester.tapAt(tester.getCenter(video));
    await tester.pumpAndSettle(const Duration(milliseconds: 350));
    expect(controller.value.isPlaying, isFalse);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
  });
}
