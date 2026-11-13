import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scene_studio/main.dart';
import 'package:scene_studio/scene_data.dart';
import 'package:scene_studio/simulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final output = Platform.environment['SCENE_CAPTURE_OUTPUT'];
  testWidgets('render controlli simulati', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 20);
    tester.view.viewPadding = tester.view.padding;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    for (final font in [
      ('TikTokSans', 'assets/fonts/TikTokSans.ttf'),
      ('TikTokIcons', 'assets/fonts/TikTokIcons.ttf'),
      ('SceneShareBrands', 'assets/fonts/SceneShareBrands.ttf'),
      ('MaterialIcons', 'fonts/MaterialIcons-Regular.otf'),
    ]) {
      final loader = FontLoader(font.$1)..addFont(rootBundle.load(font.$2));
      await loader.load();
    }
    final key = GlobalKey();
    final data = SceneData.demo()
      ..darkMode = Platform.environment['SCENE_CAPTURE_DARK'] == '1';
    data.posts.first.sampleComments =
        'Bellissimo montaggio!\nQuando esce il prossimo?';
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'TikTokSans'),
          home: const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/branding/launch-logo.png'),
        key.currentContext!,
      );
      for (final path in [
        data.avatar,
        data.studio['bannerImage']!,
        for (final post in data.posts) post.cover,
        for (final name in ['edit', 'add-friend', 'menu', 'effects'])
          'assets/scene/profile-$name.png',
      ]) {
        await precacheImage(AssetImage(path), key.currentContext!);
      }
      for (final name in [
        'ref_home',
        'ref_friends',
        'ref_profile',
        'ref_grid',
        'Inbox',
        'Create-dark',
        'Bookmark',
        'ref_heart',
        'ref_comment',
        'ref_bookmark',
      ]) {
        await precacheImage(
          AssetImage('assets/icons/$name.png'),
          key.currentContext!,
        );
      }
    });
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'TikTokSans'),
          home: Simulator(data: data, startInFeed: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Future<void> shot(String name) async {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await boundary.toImage(pixelRatio: 1);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('$output/${data.darkMode ? 'dark-' : ''}$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
      });
    }

    await shot('scene-splash');
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 355));
    await shot('scene-feed');
    await tester.pump(const Duration(milliseconds: 4050));
    await tester.pump(const Duration(milliseconds: 190));
    await shot('scene-inbox-bubble');
    await tester.tap(find.text('Profile'));
    await tester.pump();
    await shot('scene-profile-loading');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    await shot('scene-profile');
    await tester.dragFrom(const Offset(135, 440), const Offset(0, -300));
    await tester.pumpAndSettle();
    await shot('scene-profile-grid');
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(PostCover).first));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 125));
    await shot('scene-zoom-in');
    await tester.pumpAndSettle();
    await shot('scene-video');
    await tester.tap(find.byKey(const Key('action_comments')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 95));
    await shot('scene-comments-opening');
    await tester.pumpAndSettle();
    await shot('scene-comments');
    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 105));
    await shot('scene-menu-opening');
    await tester.pumpAndSettle();
    await shot('scene-menu');
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
    await shot('scene-analytics');
    await tester.tap(find.byTooltip('Back').last);
    await tester.pumpAndSettle();
    final swipe = await tester.startGesture(const Offset(6, 380));
    await swipe.moveBy(const Offset(42, 0));
    await tester.pump();
    await swipe.moveBy(const Offset(175, 0));
    await tester.pump();
    await shot('scene-zoom-out');
    await swipe.up();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Profile menu'));
    await tester.pumpAndSettle();
    await shot('scene-profile-drawer');
    await tester.tap(find.text('TikTok Studio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 380));
    await shot('scene-studio-loading');
    await tester.pump(const Duration(milliseconds: 1240));
    await tester.pump(const Duration(milliseconds: 390));
    await shot('scene-studio');
    await tester.tap(find.text('Analytics'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await shot('scene-studio-analytics-loading');
    await tester.pump(const Duration(milliseconds: 1500));
    await shot('scene-studio-analytics');
    await tester.ensureVisible(find.text('Viewers'));
    await tester.tap(find.text('Viewers'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('365 days'));
    await tester.tap(find.text('365 days'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    await shot('scene-studio-viewers');
    await tester.ensureVisible(find.text('Locations'));
    await tester.tap(find.text('Locations'));
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(150, 430), const Offset(0, -480));
    await tester.pumpAndSettle();
    await shot('scene-studio-locations');
  }, skip: output == null);
}
