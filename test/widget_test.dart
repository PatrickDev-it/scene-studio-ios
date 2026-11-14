import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scene_studio/main.dart';
import 'package:scene_studio/preview_setup.dart';
import 'package:scene_studio/scene_data.dart';
import 'package:scene_studio/simulation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'la modalità si ripristina e Profile apre il setup con pressione lunga',
    (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Future<void> relaunch() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(const SceneApp());
        await tester.pumpAndSettle();
      }

      await relaunch();
      expect(find.byType(VisualSetupScreen), findsOneWidget);
      await tester.tap(find.text('Viewer'));
      await tester.pumpAndSettle();
      await relaunch();
      expect(find.byType(Simulator), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('@animalchaos281'), findsOneWidget);
      await tester.longPress(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(VisualSetupScreen), findsOneWidget);
      await relaunch();
      expect(find.byType(VisualSetupScreen), findsOneWidget);

      for (final (mode, last, viewer) in [
        (StartupMode.viewer, false, true),
        (StartupMode.setup, true, false),
      ]) {
        final scene = SceneData.demo()
          ..startupMode = mode
          ..lastWasViewer = last;
        await SceneStore.save(scene);
        await relaunch();
        expect(
          find.byType(VisualSetupScreen),
          viewer ? findsNothing : findsOneWidget,
        );
        expect(find.text('Viewer'), viewer ? findsNothing : findsOneWidget);
      }
    },
  );
  testWidgets('sequenza di ripresa iPhone 8', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 20);
    tester.view.viewPadding = tester.view.padding;
    addTearDown(tester.view.reset);
    final scene = SceneData.demo();
    scene.homePostIds = ['3', '2'];
    scene.inboxUnread = 37;
    scene.inbox['follows'] = '21';
    scene.studio['summaryViews'] = '2.4M';
    scene.studioPeriods['0'] = {'postViews': '3.2M', 'postViewsDelta': '11.5'};
    scene.studioPeriods['3'] = {'viewers': '990K'};
    scene.posts.first.views = '30,689';
    scene.posts[1].views = '30,820';
    await tester.pumpWidget(
      MaterialApp(home: Simulator(data: scene, startInFeed: true)),
    );
    await tester.pump(const Duration(milliseconds: 1590));
    expect(find.byType(PreviewLaunchArtwork), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 15));
    await tester.pump(const Duration(milliseconds: 355));
    expect(find.text('Papaya'), findsOneWidget);
    await tester.dragFrom(const Offset(170, 290), const Offset(0, -470));
    await tester.pumpAndSettle();
    expect(find.text('Keep me guessing forever?'), findsOneWidget);
    expect(find.text('Carpet cleaning'), findsNothing);
    await tester.pump(const Duration(milliseconds: 4050));
    expect(find.text(' 21'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 4730));
    expect(find.text('37'), findsOneWidget);
    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(find.text('@animalchaos281'), findsOneWidget);
    expect(find.byType(PostCover), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(PostCover), findsWidgets);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('30.6K'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('30.6K'), findsOneWidget);
    expect(find.text('30.689K'), findsNothing);
    await tester.dragFrom(const Offset(182, 190), const Offset(0, 215));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.bySemanticsLabel('Loading'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Profile menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TikTok Studio'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1270));
    expect(find.bySemanticsLabel('Loading'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 385));
    expect(find.text('Monetization'), findsOneWidget);
    expect(find.text('2.4M'), findsOneWidget);
    await tester.tap(find.text('Analytics'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Key metrics'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.text('Key metrics'), findsOneWidget);
    expect(find.text('3.2M'), findsOneWidget);
    expect(find.textContaining('11.5%', findRichText: true), findsOneWidget);
    await tester.ensureVisible(find.text('Viewers'));
    await tester.tap(find.text('Viewers'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('365 days'));
    await tester.tap(find.text('365 days'));
    await tester.pump();
    expect(find.text('Total viewers'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1050));
    expect(find.text('Total viewers'), findsOneWidget);
    expect(find.text('990K'), findsOneWidget);
  });
  testWidgets('la scena di riferimento si carica dal setup', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final previous = SceneData.demo()
      ..name = 'Campagna locale'
      ..posts = []
      ..darkMode = true;
    await SceneStore.save(previous);
    await tester.pumpWidget(const SceneApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Impostazioni scena'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scena di riferimento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect((await SceneStore.load()).name, 'Campagna locale');

    await tester.tap(find.byTooltip('Impostazioni scena'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scena di riferimento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carica scena'));
    await tester.pumpAndSettle();
    final restored = await SceneStore.load();
    expect(restored.name, 'animalchaos281');
    expect(restored.posts, hasLength(9));
    expect(restored.darkMode, isTrue);
  });

  testWidgets('il setup visivo modifica il nome dalla schermata profilo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final scene = SceneData.demo()..startupMode = StartupMode.setup;
    await SceneStore.save(scene);
    await tester.pumpWidget(const SceneApp());
    await tester.pumpAndSettle();
    expect(find.byType(VisualSetupScreen), findsOneWidget);
    await tester.tap(find.text('animalchaos281').first);
    await tester.pumpAndSettle();
    expect(find.text('Nome del canale'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Campagna locale');
    await tester.tap(find.text('Salva'));
    await tester.pumpAndSettle();
    expect(find.text('Campagna locale'), findsOneWidget);
    expect((await SceneStore.load()).name, 'Campagna locale');
  });

  testWidgets(
    'il setup visivo modifica una metrica Studio dalla pagina stessa',
    (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final scene = SceneData.demo()..startupMode = StartupMode.setup;
      await SceneStore.save(scene);
      await tester.pumpWidget(const SceneApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Profile menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TikTok Studio'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1620));
      await tester.pump(const Duration(milliseconds: 390));
      await tester.tap(find.text('Analytics'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1850));
      await tester.tap(find.text('1.2M'));
      await tester.pumpAndSettle();
      expect(find.text('Visualizzazioni post'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '2.4M');
      await tester.tap(find.text('Salva'));
      await tester.pumpAndSettle();
      expect(find.text('2.4M'), findsOneWidget);
      expect(
        (await SceneStore.load()).studioPeriods['0']?['postViews'],
        '2.4M',
      );
    },
  );

  test('le visualizzazioni sono troncate senza arrotondare', () {
    const cases = {
      '335': '335',
      '1882': '1,882',
      '9,999': '9,999',
      '10,099': '10K',
      '30,689': '30.6K',
      '30.6999K': '30.6K',
      '119,599': '119.5K',
      '999,999': '999.9K',
      '1.2999999M': '1.2M',
      '1.2999K': '1,299',
    };
    for (final entry in cases.entries) {
      expect(formatViewCount(entry.key), entry.value, reason: entry.key);
    }
    final legacy = ScenePost.fromJson({
      'id': 'old',
      'views': '30.6K',
      'endViews': 30689,
      'growthPercent': 5,
      'seconds': 2,
    });
    expect(formatViewCount(legacy.views), '30.6K');
    expect(legacy.toJson(), isNot(contains('endViews')));
  });

  test('dati e analitiche si salvano e ripristinano', () async {
    final scene = SceneData.demo();
    scene.handle = 'campagna.prova';
    scene.darkMode = true;
    scene.posts.first.views = '120,069';
    scene.posts.first.analytics = {'male': '42'};
    scene.posts.first.sampleComments = 'ottimo';
    scene.homePostIds = ['3', '2', 'missing'];
    scene.inboxUnread = 42;
    scene.inbox['likes'] = '7';
    scene.studio['summaryViews'] = '3.2M';
    scene.studioPeriods['3'] = {'viewerGender': 'Female: 72'};
    await SceneStore.save(scene);
    final loaded = await SceneStore.load();
    expect(loaded.handle, 'campagna.prova');
    expect(loaded.darkMode, true);
    expect(loaded.posts.first.views, '120,069');
    expect(loaded.posts.first.analytics['male'], '42');
    expect(loaded.posts.first.sampleComments, 'ottimo');
    expect(loaded.homePosts.map((post) => post.id), ['3', '2']);
    expect(loaded.inboxUnread, 42);
    expect(loaded.inbox['likes'], '7');
    expect(loaded.studio['summaryViews'], '3.2M');
    expect(loaded.studioPeriods['3']?['viewerGender'], 'Female: 72');
  });

  testWidgets('il setup salva una selezione Home indipendente dalla griglia', (
    tester,
  ) async {
    final scene = SceneData.demo();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeSequenceEditor(data: scene, onSave: () {}),
      ),
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Togli dalla Home').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salva sequenza'));
    expect(scene.homePosts.map((post) => post.id), [
      for (int i = 2; i <= 9; i++) '$i',
    ]);
    expect(scene.posts.map((post) => post.id), [
      for (int i = 1; i <= 9; i++) '$i',
    ]);
  });
  const iPhoneViewports = [
    (Size(375, 667), 20.0, 0.0),
    (Size(375, 812), 44.0, 34.0),
  ];
  for (final (size, top, bottom) in iPhoneViewports) {
    void setViewport(WidgetTester tester) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.padding = FakeViewPadding(top: top, bottom: bottom);
      tester.view.viewPadding = tester.view.padding;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
    }

    testWidgets('zoom e swipe a ${size.height} pt', (tester) async {
      setViewport(tester);
      final scene = SceneData.demo();
      await tester.pumpWidget(MaterialApp(home: Simulator(data: scene)));
      await tester.pumpAndSettle();

      final tile = tester.getRect(find.byType(PostCover).at(1));
      await tester.tapAt(tile.center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final movingCover = tester.getRect(find.byType(PostCover).last);
      expect(movingCover.topLeft.dx, closeTo(tile.left, 6));
      expect(movingCover.width, greaterThan(tile.width));
      await tester.pumpAndSettle();
      expect(find.byType(PostViewer), findsOneWidget);

      final cancelled = await tester.startGesture(const Offset(4, 450));
      await cancelled.moveBy(const Offset(30, 0));
      await tester.pump();
      await cancelled.moveBy(const Offset(55, 0));
      await tester.pump();
      expect(
        tester.getRect(find.byType(PostCover).last).width,
        lessThan(size.width),
      );
      await cancelled.cancel();
      await tester.pumpAndSettle();
      expect(find.byType(PostViewer), findsOneWidget);

      final completed = await tester.startGesture(const Offset(4, 450));
      await completed.moveBy(const Offset(30, 0));
      await tester.pump();
      await completed.moveBy(const Offset(175, 0));
      await tester.pump();
      await completed.up();
      await tester.pumpAndSettle();
      expect(find.byType(PostViewer), findsNothing);
      expect(tester.getRect(find.byType(PostCover).at(1)), tile);
    });
    for (final dark in [false, true]) {
      testWidgets('video e pannelli a ${size.height} pt - dark: $dark', (
        tester,
      ) async {
        setViewport(tester);
        final scene = SceneData.demo()..darkMode = dark;
        scene.posts.first.sampleComments = 'Commento di prova';
        await tester.pumpWidget(MaterialApp(home: Simulator(data: scene)));
        await tester.pumpAndSettle();
        expect(find.text('@animalchaos281'), findsOneWidget);
        expect(find.byType(PostCover), findsWidgets);
        await tester.tapAt(tester.getCenter(find.byType(PostCover).first));
        await tester.pumpAndSettle();
        expect(find.text('Carpet cleaning'), findsOneWidget);
        await tester.tap(find.byKey(const Key('action_like')));
        await tester.pump(const Duration(milliseconds: 100));
        expect(
          find.byWidgetPredicate((w) => w is ImageIcon && w.color == hotPink),
          findsOneWidget,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('action_comments')));
        await tester.pumpAndSettle();
        expect(find.text('Commento di prova'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Commento locale');
        await tester.pump();
        await tester.tap(find.byTooltip('Send'));
        await tester.pumpAndSettle();
        expect(find.text('25 comments'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close).last);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('action_comments')));
        await tester.pumpAndSettle();
        expect(find.text('Commento locale'), findsOneWidget);
        await tester.tap(find.byTooltip('Close').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.more_horiz));
        await tester.pumpAndSettle();
        expect(find.text('Analytics'), findsOneWidget);
        await tester.tap(find.text('Analytics'));
        await tester.pump();
        expect(find.byType(AnalyticsPage), findsNothing);
        await tester.pumpAndSettle();
        expect(find.text('Key metrics'), findsOneWidget);
        await tester.tap(find.text('Viewers'));
        await tester.pumpAndSettle();
        expect(find.text('Total viewers'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new).last);
        await tester.pumpAndSettle();
        expect(find.text('Send to'), findsNothing);
        await tester.tap(find.text('More insights'));
        await tester.pumpAndSettle();
        expect(find.text('Key metrics'), findsOneWidget);
        await tester.tap(find.byTooltip('Back').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new).last);
        await tester.pumpAndSettle();
        expect(find.text('@animalchaos281'), findsOneWidget);
      });
    }
  }
}
