import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart'
    show
        CupertinoPageRoute,
        CupertinoSliverRefreshControl,
        RefreshIndicatorMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'main.dart' show Avatar, PostCover;
import 'preview_setup.dart' show studioPeriodLabels;
import 'scene_data.dart';

part 'studio_preview.dart';

const _badgeDelay = Duration(milliseconds: 4050);
const _badgeHold = Duration(milliseconds: 4720);
const _profileGridDelay = Duration(milliseconds: 250);
const _profileMetricsDelay = Duration(milliseconds: 450);
const _profileRefreshTime = Duration(milliseconds: 540);
const _studioLoadingTime = Duration(milliseconds: 1620);
const _studioCardsTime = Duration(milliseconds: 365);
const _analyticsLoadingTime = Duration(milliseconds: 1780);

// Icon font from salvadordeveloper/flutter-tiktok (MIT repository).
class TikIcons {
  static const _family = 'TikTokIcons';
  static const chat = IconData(0xe808, fontFamily: _family);
  static const create = IconData(0xe809, fontFamily: _family);
  static const heart = IconData(0xe80a, fontFamily: _family);
  static const home = IconData(0xe80b, fontFamily: _family);
  static const inbox = IconData(0xe80c, fontFamily: _family);
  static const profile = IconData(0xe80d, fontFamily: _family);
  static const reply = IconData(0xe80e, fontFamily: _family);
  static const search = IconData(0xe80f, fontFamily: _family);
}

const hotPink = Color(0xfffe2c55);
const insightBlue = Color(0xff0672d8);

double? get _desktopPreviewWidth =>
    Platform.isIOS || Platform.isAndroid ? null : 375;

class SimColors {
  final bool dark;
  const SimColors(this.dark);
  Color get bg => dark ? const Color(0xff121212) : Colors.white;
  Color get surface => dark ? const Color(0xff252525) : Colors.white;
  Color get panelBg => dark ? const Color(0xff161616) : const Color(0xfff5f5f5);
  Color get ink => dark ? Colors.white : Colors.black;
  Color get sub => dark ? const Color(0xffaaaab0) : const Color(0xff737373);
  Color get divider => dark ? const Color(0xff3a3a3a) : const Color(0xffe9e9e9);
  Color get chip => dark ? const Color(0xff333333) : const Color(0xfff1f1f1);
}

class Simulator extends StatefulWidget {
  final SceneData data;
  final VoidCallback? onSetup;
  final bool startInFeed;
  const Simulator({
    super.key,
    required this.data,
    this.onSetup,
    this.startInFeed = false,
  });
  @override
  State<Simulator> createState() => _SimulatorState();
}

class _SimulatorState extends State<Simulator> {
  final profileKey = GlobalKey<_ProfileViewState>();
  late int tab = widget.startInFeed ? 0 : 4;
  bool profileVisited = false,
      inboxRead = false,
      bubble = false,
      badgeReady = false;
  bool starting = false, feedReady = true;
  late final Timer? _launchTimer;
  Timer? _feedTimer, _inboxTimer;

  @override
  void initState() {
    super.initState();
    starting = widget.startInFeed;
    feedReady = !widget.startInFeed;
    profileVisited = !widget.startInFeed;
    badgeReady = !widget.startInFeed;
    _launchTimer = widget.startInFeed
        ? Timer(const Duration(milliseconds: 1600), replayLaunch)
        : null;
  }

  void replayLaunch() {
    setState(() => starting = false);
    _feedTimer = Timer(const Duration(milliseconds: 355), () {
      setState(() => feedReady = true);
      _inboxTimer = Timer(_badgeDelay, showInboxActivity);
    });
  }

  void showInboxActivity() {
    if (inboxRead) return;
    setState(() {
      badgeReady = true;
      bubble =
          tab == 0 &&
          widget.data.inboxUnread > 0 &&
          widget.data.inbox['popup'] != 'off';
    });
    if (bubble) {
      _inboxTimer = Timer(_badgeHold, () => setState(() => bubble = false));
    }
  }

  @override
  void dispose() {
    _launchTimer?.cancel();
    _feedTimer?.cancel();
    _inboxTimer?.cancel();
    super.dispose();
  }

  void selectTab(int index) {
    if (index == tab) {
      if (index == 4) profileKey.currentState?.scrollToTop();
      return;
    }
    setState(() {
      tab = index;
      bubble = false;
      if (index == 3) inboxRead = true;
    });
  }

  void openStudio() => Navigator.of(context).push<void>(
    CupertinoPageRoute(builder: (_) => _StudioPreview(data: widget.data)),
  );

  void openPost(int index) {
    Navigator.of(context).push<void>(
      _PostZoomRoute(
        data: widget.data,
        initialIndex: index,
        tileRect: (i) => profileKey.currentState?.visibleTileRect(i),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SimColors(widget.data.darkMode);
    final homePosts = widget.data.homePosts;
    final dark = tab == 0 || c.dark;
    final preview = AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xff28282b),
        body: Center(
          child: Container(
            width: _desktopPreviewWidth,
            height: double.infinity,
            color: tab == 0 ? Colors.black : c.bg,
            child: SafeArea(
              top: tab != 0,
              child: Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: tab == 0 && homePosts.isNotEmpty
                            ? PostViewer(
                                key: const ValueKey('feed'),
                                data: widget.data,
                                initialIndex: 0,
                                onBack: () => setState(() => tab = 4),
                                feed: true,
                                posts: homePosts,
                              )
                            : tab == 0
                            ? Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: MediaQuery.paddingOf(context).top,
                                  ),
                                  child: _FeedNavigation(onSearch: () {}),
                                ),
                              )
                            : tab == 4
                            ? ProfileView(
                                key: profileKey,
                                data: widget.data,
                                onOpen: openPost,
                                animateEntry: !profileVisited,
                                onShown: () => profileVisited = true,
                                onMenu: () => openProfileMenu(c),
                              )
                            : tab == 3
                            ? _InboxPreview(colors: c, data: widget.data)
                            : SimpleTab(
                                key: ValueKey('tab-$tab'),
                                index: tab,
                                colors: c,
                              ),
                      ),
                      SimBottomBar(
                        selected: tab,
                        colors: c,
                        unread: inboxRead || !badgeReady || bubble
                            ? 0
                            : widget.data.inboxUnread,
                        onSelected: selectTab,
                        onProfileHold: widget.onSetup,
                      ),
                    ],
                  ),
                  if (!feedReady && tab == 0)
                    Positioned.fill(
                      top: MediaQuery.paddingOf(context).top + 43,
                      bottom: 49,
                      child: const ColoredBox(color: Color(0xff121212)),
                    ),
                  if (bubble && tab == 0)
                    Positioned(
                      bottom: 54,
                      left: 0,
                      right: 0,
                      child: Align(
                        alignment: const Alignment(.60, 0),
                        child: _InboxBubble(
                          data: widget.data,
                          onTap: () => selectTab(3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (!widget.startInFeed) return preview;
    return Stack(
      fit: StackFit.expand,
      children: [
        preview,
        IgnorePointer(
          ignoring: !starting,
          child: AnimatedOpacity(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 310),
            opacity: starting ? 1 : 0,
            child: AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle.light,
              child: ColoredBox(
                color: const Color(0xff28282b),
                child: Center(
                  child: SizedBox(
                    width: _desktopPreviewWidth,
                    height: double.infinity,
                    child: const PreviewLaunchArtwork(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void openProfileMenu(SimColors colors) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: const Color(0x77000000),
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 218),
      pageBuilder: (context, _, _) =>
          _ProfileMenu(colors: colors, onStudio: openStudio),
      transitionBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}

class _PostZoomRoute extends PageRoute<void> {
  _PostZoomRoute({
    required this.data,
    required int initialIndex,
    required this.tileRect,
  }) : _index = initialIndex;

  final SceneData data;
  final Rect? Function(int) tileRect;
  int _index;

  @override
  bool get opaque => false;
  @override
  bool get maintainState => true;
  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 310);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: Colors.black,
        child: PostViewer(
          data: data,
          initialIndex: _index,
          onPageChanged: (index) => _index = index,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(
          constraints.maxWidth,
          _desktopPreviewWidth ?? constraints.maxWidth,
        );
        final target = Rect.fromLTWH(
          (constraints.maxWidth - width) / 2,
          0,
          width,
          constraints.maxHeight,
        );
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, player) {
            final progress = popGestureInProgress
                ? animation.value
                : Curves.easeInOutCubic.transform(animation.value);
            final box = navigator?.overlay?.context.findRenderObject();
            final tile = tileRect(_index);
            final origin = tile != null && box is RenderBox
                ? Rect.fromPoints(
                    box.globalToLocal(tile.topLeft),
                    box.globalToLocal(tile.bottomRight),
                  )
                : null;
            final zoom =
                origin != null && !MediaQuery.disableAnimationsOf(context);
            final bounds = zoom ? Rect.lerp(origin, target, progress)! : target;
            final playerOpacity = zoom
                ? ((progress - .38) / .47).clamp(0.0, 1.0)
                : progress;
            return Stack(
              children: [
                Positioned.fromRect(
                  rect: bounds,
                  child: ClipRect(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (zoom && playerOpacity < 1)
                          IgnorePointer(
                            child: PostCover(
                              post: data.posts[_index],
                              index: _index,
                            ),
                          ),
                        OverflowBox(
                          alignment: Alignment.center,
                          minWidth: target.width,
                          maxWidth: target.width,
                          minHeight: target.height,
                          maxHeight: target.height,
                          child: Transform.scale(
                            scale: math.max(
                              bounds.width / target.width,
                              bounds.height / target.height,
                            ),
                            child: Opacity(
                              opacity: playerOpacity,
                              child: player,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: target.left,
                  top: 0,
                  bottom: 0,
                  width: 24,
                  child: IgnorePointer(
                    ignoring: !animation.isCompleted && !popGestureInProgress,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      dragStartBehavior: DragStartBehavior.down,
                      onHorizontalDragStart: (_) => _startBackGesture(),
                      onHorizontalDragUpdate: (details) =>
                          _dragBack(details.primaryDelta ?? 0, width),
                      onHorizontalDragEnd: (details) =>
                          _finishBackGesture(details.primaryVelocity ?? 0),
                      onHorizontalDragCancel: () =>
                          _finishBackGesture(0, cancelled: true),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _startBackGesture() {
    if (isCurrent && !popGestureInProgress && popGestureEnabled) {
      navigator!.didStartUserGesture();
    }
  }

  void _dragBack(double delta, double width) {
    if (popGestureInProgress && isCurrent) {
      controller!.value = (controller!.value - delta / width).clamp(0.0, 1.0);
    }
  }

  void _finishBackGesture(double velocity, {bool cancelled = false}) {
    if (!popGestureInProgress) return;
    final nav = navigator!;
    if (!isCurrent) {
      nav.didStopUserGesture();
      return;
    }
    final motion = controller!;
    final pop =
        !cancelled &&
        (velocity > 550 || (velocity >= -550 && motion.value < .64));
    const duration = Duration(milliseconds: 210);
    if (pop) nav.pop();
    final settle = pop
        ? motion.animateBack(0, duration: duration, curve: Curves.easeOutCubic)
        : motion.animateTo(1, duration: duration, curve: Curves.easeOutCubic);
    settle.whenCompleteOrCancel(() {
      if (nav.mounted) nav.didStopUserGesture();
    });
  }
}

class SimBottomBar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;
  final SimColors colors;
  final int unread;
  final VoidCallback? onProfileHold;
  const SimBottomBar({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.colors,
    this.unread = 0,
    this.onProfileHold,
  });
  @override
  Widget build(BuildContext context) {
    final dark = selected == 0 || colors.dark;
    final fg = dark ? Colors.white : Colors.black;
    final labels = ['Home', 'Friends', '', 'Inbox', 'Profile'];
    return Container(
      height: 49,
      decoration: BoxDecoration(
        color: dark ? Colors.black : Colors.white,
        border: Border(top: BorderSide(color: fg.withValues(alpha: .09))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          5,
          (i) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelected(i),
            onLongPress: i == 4 ? onProfileHold : null,
            child: SizedBox(
              width: 62,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  SizedBox.expand(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (i == 2)
                          Image.asset(
                            'assets/icons/${dark ? 'Create' : 'Create-dark'}.png',
                            width: 43,
                            height: 30,
                            fit: BoxFit.contain,
                          )
                        else
                          ImageIcon(
                            AssetImage(
                              'assets/icons/${i == 0
                                  ? (selected == i ? 'Home-active' : 'ref_home')
                                  : i == 1
                                  ? 'ref_friends'
                                  : i == 3
                                  ? (selected == i ? 'Inbox-active' : 'Inbox')
                                  : (selected == i ? 'ref_profile' : 'Profile')}.png',
                            ),
                            size: 22,
                            color: selected == i
                                ? fg
                                : fg.withValues(alpha: .62),
                          ),
                        if (labels[i].isNotEmpty)
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 10,
                              height: 1.15,
                              fontWeight: FontWeight.w600,
                              color: selected == i
                                  ? fg
                                  : fg.withValues(alpha: .62),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (i == 3 && unread > 0)
                    Positioned(
                      top: 2,
                      left: 37,
                      child: _InboxBadge(count: unread),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfileView extends StatefulWidget {
  final SceneData data;
  final ValueChanged<int> onOpen;
  final VoidCallback onMenu, onShown;
  final bool animateEntry;
  const ProfileView({
    super.key,
    required this.data,
    required this.onOpen,
    required this.onMenu,
    required this.onShown,
    required this.animateEntry,
  });
  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  int section = 0;
  final _scroll = ScrollController();
  final tileKeys = <String, GlobalKey>{};
  late bool coversReady = !widget.animateEntry;
  late bool metricsReady = !widget.animateEntry;
  late final AnimationController viewClock = AnimationController(
    vsync: this,
    duration: Duration(
      seconds: widget.data.posts.fold(
        1,
        (longest, post) => math.max(longest, post.seconds.clamp(1, 3600)),
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animateEntry) reveal();
    if (!widget.animateEntry) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) startViewIncrease();
      });
    }
  }

  Future<void> reveal() async {
    await Future<void>.delayed(_profileGridDelay);
    if (!mounted) return;
    setState(() => coversReady = true);
    await Future<void>.delayed(_profileMetricsDelay - _profileGridDelay);
    if (!mounted) return;
    setState(() => metricsReady = true);
    startViewIncrease();
    widget.onShown();
  }

  Future<void> refresh() async {
    await Future<void>.delayed(_profileRefreshTime);
    if (!mounted) return;
    if (!metricsReady) {
      setState(() => metricsReady = true);
      startViewIncrease();
    }
  }

  void startViewIncrease() {
    if (!widget.data.posts.any(
      (post) => post.endViews > 0 || post.growthPercent > 0,
    )) {
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      viewClock.value = 1;
    } else {
      viewClock.forward();
    }
  }

  void scrollToTop() {
    if (!_scroll.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    viewClock.dispose();
    super.dispose();
  }

  Rect? visibleTileRect(int index) {
    final tile = tileKeys[widget.data.posts[index].id]?.currentContext
        ?.findRenderObject();
    final viewport = context.findRenderObject();
    if (tile is! RenderBox ||
        viewport is! RenderBox ||
        !tile.hasSize ||
        !viewport.hasSize) {
      return null;
    }
    final rect = tile.localToGlobal(Offset.zero) & tile.size;
    final visible = viewport.localToGlobal(Offset.zero) & viewport.size;
    return visible.overlaps(rect) ? rect.intersect(visible) : null;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final c = SimColors(d.darkMode);
    return ColoredBox(
      color: c.bg,
      child: CustomScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          _refreshSliver(refresh),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        height: 44,
                        child: Icon(Icons.edit_outlined, color: c.ink),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.card_giftcard_rounded,
                          color: hotPink,
                        ),
                        tooltip: 'Rewards',
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 38,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Avatar(
                              path: metricsReady ? d.avatar : '',
                              radius: 12,
                            ),
                            Positioned(
                              right: 2,
                              bottom: 0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: c.bg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Text(
                                    '99',
                                    style: TextStyle(
                                      color: c.ink,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.person_add_alt, color: c.ink),
                        tooltip: 'Friends',
                      ),
                      IconButton(
                        onPressed: widget.onMenu,
                        tooltip: 'Profile menu',
                        icon: Icon(Icons.menu, color: c.ink),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 7, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    d.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: c.ink,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 26,
                                      letterSpacing: -.7,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: c.ink,
                                  size: 18,
                                ),
                                const CircleAvatar(
                                  radius: 3,
                                  backgroundColor: hotPink,
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '@${d.handle}',
                              style: TextStyle(
                                color: c.sub,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 13),
                            Row(
                              children: [
                                Flexible(
                                  child: stat(d.following, 'Following', c),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: stat(
                                    _profileCount(d.followers, 5),
                                    'Followers',
                                    c,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: stat(
                                    _profileCount(d.likes, 100),
                                    'Likes',
                                    c,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 13),
                            child: Avatar(path: d.avatar, radius: 47),
                          ),
                          Positioned(
                            top: 0,
                            left: 3,
                            right: 3,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: Text(
                                  "What's up?",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: c.sub, fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xff19c5e8),
                                border: Border.all(color: c.bg, width: 2),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 13, 16, 0),
                  child: Text(
                    d.bio,
                    style: TextStyle(color: c.ink, fontSize: 13, height: 1.3),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 5),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.chip,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Text(
                        '+ Add college',
                        style: TextStyle(
                          color: c.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(5, (i) {
                      final icons = [
                        Icons.grid_on,
                        Icons.face_retouching_natural,
                        Icons.lock_outline,
                        Icons.bookmark_border,
                        Icons.favorite_border,
                      ];
                      return Expanded(
                        child: InkWell(
                          onTap: () => setState(() => section = i),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (i == 0)
                                ImageIcon(
                                  const AssetImage('assets/icons/ref_grid.png'),
                                  size: 24,
                                  color: section == i ? c.ink : c.sub,
                                )
                              else
                                Icon(
                                  icons[i],
                                  size: 23,
                                  color: section == i ? c.ink : c.sub,
                                ),
                              const SizedBox(height: 8),
                              Container(
                                width: 45,
                                height: 2,
                                color: section == i
                                    ? c.ink
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          if (section != 0 || d.posts.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('No videos yet', style: TextStyle(color: c.sub)),
              ),
            )
          else
            SliverGrid(
              delegate: SliverChildBuilderDelegate((context, i) {
                final p = d.posts[i];
                return InkWell(
                  key: tileKeys.putIfAbsent(p.id, GlobalKey.new),
                  onTap: () => widget.onOpen(i),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (coversReady)
                        PostCover(post: p, index: i)
                      else
                        ColoredBox(color: c.chip),
                      const IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xaa000000)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 5,
                        right: 5,
                        bottom: 6,
                        child: Row(
                          children: [
                            Icon(
                              p.scheduledLabel.isEmpty
                                  ? Icons.play_arrow_outlined
                                  : Icons.schedule,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: ViewCount(post: p, clock: viewClock),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }, childCount: d.posts.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
                childAspectRatio: .73,
              ),
            ),
        ],
      ),
    );
  }

  String _profileCount(String value, int delta) {
    final baseline = parseCount(value);
    if (metricsReady ||
        baseline <= delta ||
        value.trim().toUpperCase().endsWith('M')) {
      return value;
    }
    if (value.trim().toUpperCase().endsWith('K')) {
      return _compactCount(baseline - delta, 1000, 'K');
    }
    return _groupedCount(baseline - delta);
  }

  Widget stat(String number, String label, SimColors c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        number,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: c.ink,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(label, style: TextStyle(color: c.sub, fontSize: 12)),
      ),
    ],
  );
}

class ViewCount extends StatelessWidget {
  final ScenePost post;
  final AnimationController clock;
  const ViewCount({super.key, required this.post, required this.clock});
  @override
  Widget build(BuildContext context) {
    final start = parseCount(post.views);
    final end = post.endViews > 0
        ? post.endViews
        : start + (start * post.growthPercent / 100).round();
    final style = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    if (post.scheduledLabel.isNotEmpty) {
      return Text(
        post.scheduledLabel,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    if (end <= start) {
      return Text(
        post.views,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return AnimatedBuilder(
      animation: clock,
      builder: (_, _) {
        final elapsed = clock.value * clock.duration!.inMilliseconds;
        final duration = post.seconds.clamp(1, 3600) * 1000;
        final phase = Curves.easeOutCubic.transform(
          (elapsed / duration).clamp(0.0, 1.0),
        );
        final value = start + ((end - start) * phase).round();
        return Text(
          value == start
              ? post.views
              : post.exactViewGrowth && phase < 1
              ? _groupedCount(value)
              : _formatLikeSource(
                  value,
                  post.views,
                  precise: post.exactViewGrowth,
                ),
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

String _formatLikeSource(int value, String source, {bool precise = false}) {
  final suffix = source.trim().toUpperCase();
  if (precise && suffix.endsWith('M')) {
    return _compactCount(value, 1000000, 'M', decimals: 6);
  }
  if (value < 1000000 && suffix.endsWith('K')) {
    return _compactCount(value, 1000, 'K', decimals: precise ? 3 : 1);
  }
  return formatCount(value);
}

String formatCount(int value) {
  if (value >= 1000000) return _compactCount(value, 1000000, 'M');
  if (value >= 10000) return _compactCount(value, 1000, 'K');
  return _groupedCount(value);
}

String _compactCount(int value, int unit, String suffix, {int decimals = 1}) =>
    '${(value / unit).toStringAsFixed(decimals).replaceFirst(RegExp(r'\.?0+$'), '')}$suffix';

String _groupedCount(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

class SimpleTab extends StatelessWidget {
  final int index;
  final SimColors colors;
  const SimpleTab({super.key, required this.index, required this.colors});
  @override
  Widget build(BuildContext context) {
    final titles = ['Home', 'Friends', 'Create', 'Inbox', 'Profile'];
    return ColoredBox(
      color: colors.bg,
      child: Column(
        children: [
          SizedBox(
            height: 55,
            child: Center(
              child: Text(
                titles[index],
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: colors.divider),
          Expanded(
            child: Center(
              child: Text(
                'No content yet',
                style: TextStyle(color: colors.sub),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PostViewer extends StatefulWidget {
  final SceneData data;
  final int initialIndex;
  final VoidCallback onBack;
  final bool feed;
  final List<ScenePost>? posts;
  final ValueChanged<int>? onPageChanged;
  const PostViewer({
    super.key,
    required this.data,
    required this.initialIndex,
    required this.onBack,
    this.feed = false,
    this.posts,
    this.onPageChanged,
  });
  @override
  State<PostViewer> createState() => _PostViewerState();
}

class _PostViewerState extends State<PostViewer> {
  final reactions = <String, _PostReactions>{};
  late PageController controller;
  late int current;
  @override
  void initState() {
    super.initState();
    current = widget.initialIndex;
    controller = PageController(initialPage: current);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.posts ?? widget.data.posts;
    return PageView.builder(
      controller: controller,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      itemCount: posts.length,
      onPageChanged: (v) {
        setState(() => current = v);
        widget.onPageChanged?.call(v);
      },
      itemBuilder: (context, i) => _PostSlide(
        key: ValueKey(posts[i].id),
        data: widget.data,
        post: posts[i],
        reactions: reactions.putIfAbsent(posts[i].id, _PostReactions.new),
        index: i,
        active: i == current,
        onBack: widget.onBack,
        feed: widget.feed,
      ),
    );
  }
}

class _PostSlide extends StatefulWidget {
  final SceneData data;
  final ScenePost post;
  final int index;
  final bool active;
  final bool feed;
  final _PostReactions reactions;
  final VoidCallback onBack;
  const _PostSlide({
    super.key,
    required this.data,
    required this.post,
    required this.index,
    required this.active,
    required this.feed,
    required this.reactions,
    required this.onBack,
  });
  @override
  State<_PostSlide> createState() => _PostSlideState();
}

class _PostSlideState extends State<_PostSlide> with TickerProviderStateMixin {
  VideoPlayerController? video;
  bool paused = false, failed = false, covered = false, muted = false;
  bool captionExpanded = false;
  Offset? heartPosition;
  late final heart = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final commentsMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 285),
    reverseDuration: const Duration(milliseconds: 215),
  );

  @override
  void initState() {
    super.initState();
    initVideo();
  }

  Future<void> initVideo() async {
    final path = widget.post.video;
    if (path.isEmpty) return;
    final file = File(path);
    if (!file.existsSync()) {
      failed = true;
      return;
    }
    final player = VideoPlayerController.file(file);
    video = player;
    try {
      await player.initialize();
      if (!mounted) return;
      await player.setLooping(true);
      if (!mounted) return;
      if (muted) await player.setVolume(0);
      if (!mounted) return;
      updatePlayback();
      setState(() {});
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  void updatePlayback() {
    final player = video;
    if (player == null || !player.value.isInitialized || failed) return;
    if (widget.active && !paused && !covered) {
      player.play();
    } else {
      player.pause();
    }
  }

  @override
  void didUpdateWidget(covariant _PostSlide old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) updatePlayback();
  }

  @override
  void dispose() {
    heart.dispose();
    commentsMotion.dispose();
    video?.dispose();
    super.dispose();
  }

  void likeAt(Offset position) {
    setState(() {
      widget.reactions.liked = true;
      heartPosition = position;
    });
    if (!MediaQuery.disableAnimationsOf(context)) heart.forward(from: 0);
  }

  Future<void> showComments() =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: SimColors(widget.data.darkMode).surface,
        barrierColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        constraints: BoxConstraints(
          maxWidth: _desktopPreviewWidth ?? double.infinity,
        ),
        transitionAnimationController: commentsMotion,
        sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
            ? AnimationStyle.noAnimation
            : null,
        builder: (_) => _CommentSheet(
          post: widget.post,
          data: widget.data,
          reactions: widget.reactions,
          fraction: widget.feed ? .66 : .64,
        ),
      ).whenComplete(() {
        if (mounted) setState(() {});
      });

  Future<void> showShare() async {
    final navigator = Navigator.of(context);
    final sheet = ModalBottomSheetRoute<bool>(
      isScrollControlled: true,
      backgroundColor: SimColors(widget.data.darkMode).surface,
      modalBarrierColor: const Color(0x18000000),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      constraints: BoxConstraints(
        maxWidth: _desktopPreviewWidth ?? double.infinity,
      ),
      sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: Duration(milliseconds: 285),
              reverseDuration: Duration(milliseconds: 210),
            ),
      builder: (sheet) => ShareSheet(
        data: widget.data,
        onAnalytics: () => Navigator.pop(sheet, true),
      ),
    );
    final openAnalytics = await navigator.push(sheet);
    await sheet.completed;
    if (openAnalytics == true && mounted) await showAnalytics();
  }

  Future<void> showAnalytics() =>
      openDetail(AnalyticsPage(post: widget.post, data: widget.data));

  Future<void> openDetail(Widget page) async {
    if (covered) return;
    covered = true;
    updatePlayback();
    try {
      await Navigator.of(context)
          .push(CupertinoPageRoute<void>(builder: (_) => page));
    } finally {
      if (mounted) {
        covered = false;
        updatePlayback();
      }
    }
  }

  String get commentCount {
    return incrementDisplayedCount(
      widget.post.comments,
      by: widget.reactions.comments.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final player = video;
    final ready = player != null && player.value.isInitialized && !failed;
    final insets = MediaQuery.paddingOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final feed = widget.feed;
    final footer = feed ? 0.0 : 56 + insets.bottom;
    const promotionHeight = 50.0;
    final overlaysBottom = footer + (feed ? 0 : promotionHeight);
    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, bounds) {
          final top = insets.top;
          final previewHeight = bounds.maxHeight - footer;
          final commentsHeight = math.max(
            0.0,
            bounds.maxHeight * (feed ? .34 : .36) - top,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                bottom: footer,
                child: AnimatedBuilder(
                  animation: commentsMotion,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onDoubleTapDown: (details) =>
                        heartPosition = details.localPosition,
                    onDoubleTap: () {
                      if (heartPosition case final position?) likeAt(position);
                    },
                    onTap: ready
                        ? () {
                            setState(() => paused = !paused);
                            updatePlayback();
                          }
                        : null,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (ready)
                          ClipRect(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox.fromSize(
                                size: player.value.size,
                                child: VideoPlayer(player),
                              ),
                            ),
                          )
                        else
                          PostCover(post: post, index: widget.index),
                        if (paused && ready)
                          const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 76,
                              color: Colors.white38,
                            ),
                          ),
                        if (failed)
                          const Center(
                            child: Text(
                              'Couldn’t play video',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  builder: (context, child) {
                    final progress = commentsMotion.value;
                    final scale = reduceMotion || previewHeight <= 0
                        ? 1.0
                        : 1 - progress * (1 - commentsHeight / previewHeight);
                    return Transform.translate(
                      offset: Offset(0, top * progress),
                      child: Transform.scale(
                        alignment: Alignment.topCenter,
                        scale: scale.clamp(.05, 1.0),
                        child: child,
                      ),
                    );
                  },
                ),
              ),
              AnimatedBuilder(
                animation: commentsMotion,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      bottom: footer,
                      child: const IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0, .18, .67, 1],
                              colors: [
                                Colors.black45,
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black54,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (feed)
                      Positioned(
                        top: top,
                        left: 0,
                        right: 0,
                        child: _FeedNavigation(
                          onSearch: () => openDetail(
                            _VideoSearchPage(data: widget.data, post: post),
                          ),
                        ),
                      ),
                    if (!feed)
                      Positioned(
                        top: top + 2,
                        left: 0,
                        right: 17,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              height: 44,
                              child: IconButton(
                                onPressed: widget.onBack,
                                tooltip: 'Back',
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                key: const Key('video_search'),
                                onTap: () => openDetail(
                                  _VideoSearchPage(
                                    data: widget.data,
                                    post: post,
                                  ),
                                ),
                                child: Container(
                                  height: 39,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        TikIcons.search,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Find related content',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 14,
                                        child: VerticalDivider(
                                          width: 22,
                                          thickness: 1,
                                          color: Colors.white30,
                                        ),
                                      ),
                                      Text(
                                        'Search',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      right: 8,
                      bottom: overlaysBottom + 14,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: widget.onBack,
                            child: Avatar(path: widget.data.avatar, radius: 23),
                          ),
                          const SizedBox(height: 19),
                          action(
                            TikIcons.heart,
                            widget.reactions.liked
                                ? incrementDisplayedCount(post.likes)
                                : post.likes,
                            onTap: () => setState(
                              () => widget.reactions.liked =
                                  !widget.reactions.liked,
                            ),
                            asset: 'ref_heart.png',
                            key: const Key('action_like'),
                            color: widget.reactions.liked
                                ? hotPink
                                : Colors.white,
                          ),
                          action(
                            TikIcons.chat,
                            commentCount,
                            onTap: showComments,
                            asset: 'ref_comment.png',
                            key: const Key('action_comments'),
                          ),
                          action(
                            Icons.bookmark,
                            widget.reactions.saved
                                ? incrementDisplayedCount(post.saves)
                                : post.saves,
                            onTap: () => setState(
                              () => widget.reactions.saved =
                                  !widget.reactions.saved,
                            ),
                            asset: 'ref_bookmark.png',
                            color: widget.reactions.saved
                                ? const Color(0xffffc838)
                                : Colors.white,
                          ),
                          if (feed)
                            action(
                              TikIcons.reply,
                              post.shares,
                              onTap: showShare,
                            )
                          else
                            action(Icons.more_horiz, '', onTap: showShare),
                          const SizedBox(height: 9),
                          GestureDetector(
                            onTap: () {
                              setState(() => muted = !muted);
                              if (ready) player.setVolume(muted ? 0 : 1);
                            },
                            child: CircleAvatar(
                              radius: 21,
                              backgroundColor: const Color(0xfff7f7f7),
                              child: Icon(
                                muted
                                    ? Icons.volume_off_rounded
                                    : Icons.volume_up_rounded,
                                size: 23,
                                color: const Color(0xff161823),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 13,
                      right: 72,
                      bottom: overlaysBottom + 9,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: widget.data.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' · 17h ago',
                                  style: TextStyle(color: Colors.white60),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                            ),
                          ),
                          if (post.caption.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _caption(post.caption),
                          ],
                          if (post.audio.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    post.audio,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!feed)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: footer,
                        height: promotionHeight,
                        child: GestureDetector(
                          onTap: showShare,
                          child: ColoredBox(
                            color: const Color(0x55000000),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(13, 0, 10, 3),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  const Expanded(
                                    child: Text(
                                      'Turn your video into a view magnet',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                    size: 23,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 13,
                      right: 13,
                      bottom: footer - (feed ? 0 : 7),
                      child: _VideoScrubber(controller: ready ? player : null),
                    ),
                    if (!feed)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: insets.bottom,
                        height: 55,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 13),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white70,
                                size: 23,
                              ),
                              Flexible(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 66,
                                  ),
                                  child: Text(
                                    post.views,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                TikIcons.reply,
                                color: Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 54,
                                  ),
                                  child: Text(
                                    post.shares,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: showAnalytics,
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xff707070),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 11,
                                  ),
                                  minimumSize: const Size(0, 36),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.standard,
                                ),
                                icon: const Icon(Icons.show_chart, size: 18),
                                label: const Text(
                                  'More insights',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                builder: (context, child) => IgnorePointer(
                  ignoring: commentsMotion.value > 0,
                  child: Opacity(
                    opacity: (1 - commentsMotion.value * 2).clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              ),
              if (heartPosition case final position?)
                Positioned(
                  left: position.dx - 37,
                  top: position.dy - 37,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: heart,
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: hotPink,
                        size: 74,
                      ),
                      builder: (context, child) {
                        final t = heart.value;
                        return Opacity(
                          opacity: t == 0 ? 0 : ((1 - t) * 2.6).clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, -24 * t),
                            child: Transform.rotate(
                              angle: -.18,
                              child: Transform.scale(
                                scale: t < .28
                                    ? .6 +
                                          Curves.easeOut.transform(t / .28) *
                                              .46
                                    : 1.06 - (t - .28) * .27,
                                child: child,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _caption(String caption) => LayoutBuilder(
    builder: (context, constraints) {
      const style = TextStyle(color: Colors.white, fontSize: 15, height: 1.25);
      final measurement = TextPainter(
        text: TextSpan(text: caption, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 2,
      )..layout(maxWidth: constraints.maxWidth);
      final expandable = measurement.didExceedMaxLines;
      measurement.dispose();
      return GestureDetector(
        onTap: expandable
            ? () => setState(() => captionExpanded = !captionExpanded)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              caption,
              maxLines: captionExpanded ? 7 : 2,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
            if (expandable)
              Text(
                captionExpanded ? 'less' : 'more',
                style: style.copyWith(fontWeight: FontWeight.w700),
              ),
          ],
        ),
      );
    },
  );

  Widget action(
    IconData icon,
    String label, {
    required VoidCallback onTap,
    Color color = Colors.white,
    String? asset,
    Key? key,
  }) => GestureDetector(
    key: key,
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: SizedBox(
      width: 48,
      height: label.isEmpty ? 48 : 69,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 130),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: Tween(begin: .86, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: asset == null
                ? Icon(icon, size: 31, color: color)
                : ImageIcon(
                    AssetImage('assets/icons/$asset'),
                    key: ValueKey(color),
                    size: 32,
                    color: color,
                  ),
          ),
          if (label.isNotEmpty)
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
              ),
            ),
        ],
      ),
    ),
  );
}

class _VideoScrubber extends StatelessWidget {
  final VideoPlayerController? controller;
  const _VideoScrubber({required this.controller});

  @override
  Widget build(BuildContext context) {
    final player = controller;
    return SliderTheme(
      data: const SliderThemeData(
        trackHeight: 3,
        activeTrackColor: Colors.white,
        inactiveTrackColor: Colors.white30,
        thumbColor: Colors.white,
        disabledThumbColor: Colors.white,
        disabledInactiveTrackColor: Colors.white30,
        overlayColor: Colors.transparent,
        padding: EdgeInsets.zero,
        trackShape: RoundedRectSliderTrackShape(),
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: 4,
          elevation: 0,
          pressedElevation: 0,
        ),
      ),
      child: SizedBox(
        height: 14,
        child: player == null
            ? const Slider(value: 0, onChanged: null)
            : ValueListenableBuilder(
                valueListenable: player,
                builder: (context, value, _) {
                  final duration = value.duration.inMilliseconds;
                  return Slider(
                    value: duration == 0
                        ? 0
                        : (value.position.inMilliseconds / duration).clamp(
                            0.0,
                            1.0,
                          ),
                    onChanged: (fraction) => player.seekTo(
                      Duration(milliseconds: (duration * fraction).round()),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _PostReactions {
  bool liked = false, saved = false;
  final List<String> comments = [];
}

class _VideoSearchPage extends StatefulWidget {
  final SceneData data;
  final ScenePost post;
  const _VideoSearchPage({required this.data, required this.post});

  @override
  State<_VideoSearchPage> createState() => _VideoSearchPageState();
}

class _VideoSearchPageState extends State<_VideoSearchPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final c = SimColors(widget.data.darkMode);
    final posts = widget.data.posts
        .where(
          (post) =>
              post != widget.post &&
              post.caption.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.bg,
        body: Center(
          child: SizedBox(
            width: _desktopPreviewWidth,
            child: SafeArea(
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Back',
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: c.ink,
                          size: 21,
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          onChanged: (text) =>
                              setState(() => query = text.trim()),
                          style: TextStyle(color: c.ink),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              TikIcons.search,
                              color: c.sub,
                              size: 18,
                            ),
                            hintText: 'Find related content',
                            hintStyle: TextStyle(color: c.sub),
                            filled: true,
                            fillColor: c.chip,
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => FocusScope.of(context).unfocus(),
                        child: const Text(
                          'Search',
                          style: TextStyle(color: hotPink),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (posts.isEmpty)
                    Expanded(
                      child: Center(
                        child: Text(
                          'No results',
                          style: TextStyle(color: c.sub),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: .75,
                              crossAxisSpacing: 4,
                              mainAxisSpacing: 4,
                            ),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          final originalIndex = widget.data.posts.indexOf(post);
                          return GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              Navigator.of(context).push(
                                _PostZoomRoute(
                                  data: widget.data,
                                  initialIndex: originalIndex,
                                  tileRect: (index) {
                                    final box = context.findRenderObject();
                                    return index == originalIndex &&
                                            box is RenderBox &&
                                            box.attached
                                        ? box.localToGlobal(Offset.zero) &
                                              box.size
                                        : null;
                                  },
                                ),
                              );
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                PostCover(post: post, index: originalIndex),
                                Positioned(
                                  left: 8,
                                  right: 8,
                                  bottom: 8,
                                  child: Text(
                                    post.caption,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

int parseCount(String value) {
  final x = value.trim().toUpperCase().replaceAll(',', '');
  final n = double.tryParse(x.replaceAll(RegExp('[^0-9.]'), '')) ?? 0;
  return (n *
          (x.endsWith('K')
              ? 1000
              : x.endsWith('M')
              ? 1000000
              : 1))
      .round();
}

String incrementDisplayedCount(String raw, {int by = 1}) {
  if (by == 0) return raw;
  final upper = raw.trim().toUpperCase();
  final value = parseCount(raw) + by;
  if (upper.endsWith('K') || upper.endsWith('M')) {
    final divisor = upper.endsWith('M') ? 1000000 : 1000;
    final decimals = upper.contains('.')
        ? upper.split('.').last.replaceAll(RegExp(r'[^0-9]'), '').length
        : 0;
    return '${(value / divisor).toStringAsFixed(decimals.clamp(0, 2))}${upper.endsWith('M') ? 'M' : 'K'}';
  }
  return value.toString();
}

class ShareSheet extends StatelessWidget {
  static const whatsApp = IconData(0xf232, fontFamily: 'SceneShareBrands');
  static const telegram = IconData(0xf3fe, fontFamily: 'SceneShareBrands');
  static const messenger = IconData(0xf39f, fontFamily: 'SceneShareBrands');
  final SceneData data;
  final VoidCallback onAnalytics;
  const ShareSheet({super.key, required this.data, required this.onAnalytics});

  @override
  Widget build(BuildContext context) {
    final colors = SimColors(data.darkMode);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 17),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 54,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'Send to',
                  style: TextStyle(
                    color: colors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Positioned(
                  left: 16,
                  child: Icon(TikIcons.search, size: 24, color: colors.ink),
                ),
                Positioned(
                  right: 12,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                    icon: CircleAvatar(
                      radius: 15,
                      backgroundColor: colors.chip,
                      child: Icon(Icons.close, color: colors.ink, size: 19),
                    ),
                  ),
                ),
              ],
            ),
          ),
          shareRow(108, colors, [
            shareItem(
              data.name,
              Icons.person,
              colors.chip,
              colors.sub,
              avatar: data.avatar,
            ),
            shareItem(
              'Alex',
              Icons.person,
              const Color(0xffdde6e6),
              const Color(0xff52686e),
            ),
            shareItem(
              'Creative',
              Icons.person,
              const Color(0xffe8e1ef),
              const Color(0xff766189),
            ),
            shareItem(
              'Studio',
              Icons.person,
              const Color(0xffeaded9),
              const Color(0xff8c625b),
            ),
            shareItem('Friends', Icons.person, colors.chip, colors.sub),
            shareItem('Contacts', Icons.person, colors.chip, colors.sub),
          ]),
          Divider(height: 1, color: colors.divider),
          shareRow(99, colors, [
            shareItem(
              'Copy link',
              Icons.link,
              const Color(0xff2e72fa),
              Colors.white,
            ),
            shareItem(
              'WhatsApp',
              whatsApp,
              const Color(0xff1bcf60),
              Colors.white,
            ),
            shareItem(
              'Telegram',
              telegram,
              const Color(0xff279fd0),
              Colors.white,
            ),
            shareItem(
              'Status',
              whatsApp,
              const Color(0xff1bcf60),
              Colors.white,
            ),
            shareItem(
              'Instagram\nDirect',
              messenger,
              const Color(0xffd8468f),
              Colors.white,
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xff5045eb),
                  Color(0xffdc2978),
                  Color(0xffffb24b),
                ],
              ),
            ),
            shareItem(
              'Email',
              Icons.mail_outline,
              const Color(0xff0bb9df),
              Colors.white,
            ),
          ]),
          shareRow(100, colors, [
            shareItem(
              'Analytics',
              Icons.stacked_line_chart_rounded,
              colors.chip,
              colors.ink,
              onTap: onAnalytics,
            ),
            shareItem(
              'Download',
              Icons.download_rounded,
              colors.chip,
              colors.ink,
            ),
            shareItem(
              'Increase\nviews',
              Icons.local_fire_department_rounded,
              colors.chip,
              colors.ink,
            ),
            shareItem('Cast', Icons.cast, colors.chip, colors.ink),
            shareItem('Pin', Icons.push_pin_rounded, colors.chip, colors.ink),
            shareItem(
              'Privacy\nsettings',
              Icons.lock_outline_rounded,
              colors.chip,
              colors.ink,
            ),
          ]),
        ],
      ),
    );
  }

  Widget shareRow(double height, SimColors colors, List<Widget> items) =>
      SizedBox(
        height: height,
        child: DefaultTextStyle(
          style: TextStyle(
            color: colors.ink,
            fontFamily: 'TikTokSans',
            fontSize: 12,
            height: 1.12,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(7, 12, 7, 0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: items,
          ),
        ),
      );

  Widget shareItem(
    String label,
    IconData icon,
    Color bg,
    Color fg, {
    VoidCallback? onTap,
    String? avatar,
    Gradient? gradient,
  }) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      width: 73,
      child: Column(
        children: [
          if (avatar != null && avatar.isNotEmpty)
            Avatar(path: avatar, radius: 26)
          else
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bg,
                gradient: gradient,
              ),
              child: Icon(icon, color: fg, size: 27),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CommentSheet extends StatefulWidget {
  final ScenePost post;
  final SceneData data;
  final _PostReactions reactions;
  final double fraction;
  const _CommentSheet({
    required this.post,
    required this.data,
    required this.reactions,
    required this.fraction,
  });

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final text = TextEditingController();
  final focus = FocusNode();
  final liked = <int>{};
  late final comments = widget.post.sampleComments
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .toList();
  String? replyTo;

  @override
  void dispose() {
    text.dispose();
    focus.dispose();
    super.dispose();
  }

  void send() {
    final content = text.text.trim();
    if (content.isEmpty) return;
    setState(() {
      widget.reactions.comments.insert(0, content);
      replyTo = null;
      text.clear();
    });
    focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = SimColors(widget.data.darkMode);
    final posted = widget.reactions.comments;
    final mq = MediaQuery.of(context);
    final count = incrementDisplayedCount(
      widget.post.comments,
      by: posted.length,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: SizedBox(
        height: math.min(
          mq.size.height * widget.fraction,
          math.max(0, mq.size.height - mq.viewInsets.bottom - 12),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(
                height: 48,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$count comments',
                      style: TextStyle(
                        color: c.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Positioned(
                      right: 5,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Close',
                        icon: Icon(Icons.close, color: c.ink, size: 23),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: comments.isEmpty && posted.isEmpty
                    ? Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(color: c.sub),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(13, 4, 12, 8),
                        physics: const BouncingScrollPhysics(),
                        itemCount: comments.length + posted.length,
                        itemBuilder: (_, index) {
                          final own = index < posted.length;
                          final commentIndex = own
                              ? index - posted.length
                              : index - posted.length + 1;
                          final user = own
                              ? widget.data.name
                              : 'user_$commentIndex';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Avatar(
                                  path: own ? widget.data.avatar : '',
                                  radius: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user,
                                        style: TextStyle(
                                          color: c.sub,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        own
                                            ? posted[index]
                                            : comments[commentIndex - 1],
                                        style: TextStyle(
                                          color: c.ink,
                                          fontSize: 14,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() => replyTo = user);
                                          focus.requestFocus();
                                        },
                                        child: Text(
                                          'Reply',
                                          style: TextStyle(
                                            color: c.sub,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(() {
                                    if (!liked.add(commentIndex)) {
                                      liked.remove(commentIndex);
                                    }
                                  }),
                                  icon: Icon(
                                    liked.contains(commentIndex)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 18,
                                    color: liked.contains(commentIndex)
                                        ? hotPink
                                        : c.sub,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Divider(height: 1, color: c.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 7, 12, 6),
                child: Row(
                  children: [
                    Avatar(path: widget.data.avatar, radius: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: text,
                        focusNode: focus,
                        onSubmitted: (_) => send(),
                        style: TextStyle(color: c.ink, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: replyTo == null
                              ? 'Add comment...'
                              : 'Reply to $replyTo',
                          hintStyle: TextStyle(color: c.sub, fontSize: 14),
                          filled: true,
                          fillColor: c.chip,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 44,
                            minHeight: 36,
                          ),
                          suffixIcon: ValueListenableBuilder(
                            valueListenable: text,
                            builder: (_, value, _) => value.text.trim().isEmpty
                                ? Icon(
                                    Icons.alternate_email,
                                    color: c.ink,
                                    size: 19,
                                  )
                                : IconButton(
                                    onPressed: send,
                                    tooltip: 'Send',
                                    icon: const Icon(
                                      Icons.arrow_upward_rounded,
                                      color: hotPink,
                                      size: 20,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const analyticsDefaults = <String, String>{
  'playtime': '210h:15m',
  'average': '31.0s',
  'completion': '14.22%',
  'newFollowers': '18',
  'totalViewers': '21.1K',
  'change': '+74',
  'newViewers': '2',
  'returning': '98',
  'nonFollowers': '96',
  'followers': '4',
  'male': '29',
  'female': '70',
  'other': '1',
  'age18': '36',
  'age25': '31',
  'age35': '17',
  'age45': '12',
  'age55': '4',
  'location1': 'Italy',
  'location1pct': '87.3',
  'location2': 'France',
  'location2pct': '7.8',
  'location3': 'United States',
  'location3pct': '1.0',
  'location4': 'Switzerland',
  'location4pct': '0.8',
  'location5': 'United Kingdom',
  'location5pct': '0.7',
  'location6': 'Romania',
  'location6pct': '0.5',
  'location7': 'Germany',
  'location7pct': '0.3',
  'location8': 'Belgium',
  'location8pct': '0.2',
  'location9': 'Bulgaria',
  'location9pct': '0.2',
  'location10': 'India',
  'location10pct': '0.2',
  'location11': 'Other',
  'location11pct': '1.0',
  'date': 'Nov 3, 2026, 6:10 PM',
  'updated': '11/12/2026',
  'length': '81.43s',
};
String metric(ScenePost p, String key) =>
    p.analytics[key] ?? analyticsDefaults[key] ?? '';

class AnalyticsEditor extends StatefulWidget {
  final ScenePost post;
  const AnalyticsEditor({super.key, required this.post});
  @override
  State<AnalyticsEditor> createState() => _AnalyticsEditorState();
}

class _AnalyticsEditorState extends State<AnalyticsEditor> {
  late Map<String, TextEditingController> fields;
  late TextEditingController comments;
  static const groups = <String, Map<String, String>>{
    'Panoramica': {
      'date': 'Data e ora pubblicazione',
      'updated': 'Data aggiornamento',
      'length': 'Durata video',
      'playtime': 'Tempo totale di riproduzione',
      'average': 'Tempo medio',
      'completion': 'Video visto fino alla fine',
      'newFollowers': 'Nuovi follower',
    },
    'Spettatori': {
      'totalViewers': 'Spettatori totali',
      'change': 'Variazione',
      'newViewers': 'Nuovi spettatori %',
      'returning': 'Spettatori di ritorno %',
      'nonFollowers': 'Non follower %',
      'followers': 'Follower %',
    },
    'Genere ed età': {
      'male': 'Uomini %',
      'female': 'Donne %',
      'other': 'Altro %',
      'age18': '18–24 %',
      'age25': '25–34 %',
      'age35': '35–44 %',
      'age45': '45–54 %',
      'age55': '55+ %',
    },
    'Località': {
      'location1': 'Paese 1',
      'location1pct': 'Paese 1 %',
      'location2': 'Paese 2',
      'location2pct': 'Paese 2 %',
      'location3': 'Paese 3',
      'location3pct': 'Paese 3 %',
      'location4': 'Paese 4',
      'location4pct': 'Paese 4 %',
      'location5': 'Paese 5',
      'location5pct': 'Paese 5 %',
      'location6': 'Paese 6',
      'location6pct': 'Paese 6 %',
      'location7': 'Paese 7',
      'location7pct': 'Paese 7 %',
      'location8': 'Paese 8',
      'location8pct': 'Paese 8 %',
      'location9': 'Paese 9',
      'location9pct': 'Paese 9 %',
      'location10': 'Paese 10',
      'location10pct': 'Paese 10 %',
      'location11': 'Paese 11',
      'location11pct': 'Paese 11 %',
    },
  };
  @override
  void initState() {
    super.initState();
    fields = {
      for (final k in analyticsDefaults.keys)
        k: TextEditingController(text: metric(widget.post, k)),
    };
    comments = TextEditingController(text: widget.post.sampleComments);
  }

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    comments.dispose();
    super.dispose();
  }

  void save() {
    widget.post.analytics = {
      for (final e in fields.entries) e.key: e.value.text,
    };
    widget.post.sampleComments = comments.text;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: const Text('Analitiche simulate'),
      actions: [TextButton(onPressed: save, child: const Text('Salva'))],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Questi valori sono locali e modificabili per ogni video.',
              style: TextStyle(color: Colors.black54),
            ),
            for (final group in groups.entries) ...[
              const SizedBox(height: 20),
              Text(
                group.key,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              for (final field in group.value.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: fields[field.key],
                    decoration: InputDecoration(
                      labelText: field.value,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Commenti simulati',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: comments,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Un commento per riga',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: save,
              child: const Text('Salva analitiche'),
            ),
          ],
        ),
      ),
    ),
  );
}

class AnalyticsPage extends StatefulWidget {
  final ScenePost post;
  final SceneData data;
  const AnalyticsPage({super.key, required this.post, required this.data});
  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController tabs;
  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 4, initialIndex: 1, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SimColors(widget.data.darkMode), p = widget.post;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: c.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xff28282b),
        body: Center(
          child: Container(
            width: _desktopPreviewWidth,
            color: c.panelBg,
            child: SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Back',
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              color: c.ink,
                              size: 21,
                            ),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: .29,
                          child: Text(
                            'Video analytics',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: c.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 13,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: c.surface,
                              border: Border.all(color: c.divider),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_rounded,
                                  color: c.ink,
                                  size: 15,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'TikTok Studio',
                                  style: TextStyle(
                                    color: c.ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: NestedScrollView(
                      headerSliverBuilder: (_, _) => [
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              const SizedBox(height: 18),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: SizedBox(
                                  width: 85,
                                  height: 114,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      PostCover(post: p, index: 0),
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 7,
                                        child: Text(
                                          metric(p, 'length'),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black,
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Posted on ${metric(p, 'date')}',
                                style: TextStyle(color: c.sub, fontSize: 14),
                              ),
                              const SizedBox(height: 18),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                ),
                                child: Row(
                                  children: [
                                    smallStat(
                                      Icons.play_arrow_rounded,
                                      p.views,
                                      c,
                                    ),
                                    smallStat(
                                      Icons.favorite_rounded,
                                      p.likes,
                                      c,
                                    ),
                                    smallStat(TikIcons.chat, p.comments, c),
                                    smallStat(TikIcons.reply, p.shares, c),
                                    smallStat(
                                      Icons.bookmark_rounded,
                                      p.saves,
                                      c,
                                      last: true,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: AnalyticsTabs(tabs: tabs, colors: c),
                        ),
                      ],
                      body: TabBarView(
                        controller: tabs,
                        children: [
                          analyticsEmpty(c, 'Inspiration'),
                          OverviewTab(post: p, colors: c),
                          ViewersTab(post: p, colors: c),
                          _EngagementTab(post: p, colors: c),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget smallStat(
    IconData icon,
    String value,
    SimColors c, {
    bool last = false,
  }) => Expanded(
    child: Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            Icon(icon, color: c.sub.withValues(alpha: .7), size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (!last)
          Positioned(
            right: 0,
            child: Container(width: 1, height: 21, color: c.divider),
          ),
      ],
    ),
  );
  Widget analyticsEmpty(SimColors c, String title) => Center(
    child: Text(
      '$title\nNessun dato nella scena',
      textAlign: TextAlign.center,
      style: TextStyle(color: c.sub),
    ),
  );
}

class AnalyticsTabs extends SliverPersistentHeaderDelegate {
  final TabController tabs;
  final SimColors colors;
  AnalyticsTabs({required this.tabs, required this.colors});
  @override
  double get minExtent => 46;
  @override
  double get maxExtent => 46;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    color: colors.panelBg,
    child: TabBar(
      controller: tabs,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelPadding: const EdgeInsets.symmetric(horizontal: 10),
      labelColor: colors.ink,
      unselectedLabelColor: colors.sub,
      indicatorColor: colors.ink,
      labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      tabs: const [
        Tab(text: 'Inspiration'),
        Tab(text: 'Overview'),
        Tab(text: 'Viewers'),
        Tab(text: 'Engagement'),
      ],
    ),
  );
  @override
  bool shouldRebuild(covariant AnalyticsTabs old) =>
      old.colors.dark != colors.dark;
}

class _EngagementTab extends StatelessWidget {
  final ScenePost post;
  final SimColors colors;
  const _EngagementTab({required this.post, required this.colors});

  @override
  Widget build(BuildContext context) {
    final comments = post.sampleComments
        .split('\n')
        .where((line) => line.trim().isNotEmpty);
    return ListView(
      children: [
        AnalyticsCard(
          colors: colors,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comments',
                style: TextStyle(
                  color: colors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (comments.isEmpty)
                Text('No comments yet', style: TextStyle(color: colors.sub)),
              for (final comment in comments.take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(comment, style: TextStyle(color: colors.ink)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AnalyticsCard extends StatelessWidget {
  final SimColors colors;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const AnalyticsCard({
    super.key,
    required this.colors,
    required this.child,
    this.padding,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(9, 9, 9, 0),
    padding: padding ?? const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(9),
    ),
    child: child,
  );
}

class OverviewTab extends StatelessWidget {
  final ScenePost post;
  final SimColors colors;
  const OverviewTab({super.key, required this.post, required this.colors});
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      AnalyticsCard(
        colors: colors,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.music_note, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Open the TikTok Studio app',
                    style: TextStyle(
                      color: colors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'View advanced insights on creators like you.',
                    style: TextStyle(color: colors.sub, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      AnalyticsCard(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Key metrics',
                  style: TextStyle(
                    fontSize: 20,
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 5),
                Icon(Icons.info_outline, size: 16, color: colors.sub),
              ],
            ),
            Text(
              'Updated on ${metric(post, 'updated')}.',
              style: TextStyle(color: colors.sub, fontSize: 13),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.15,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                metricBox('Video views', post.views, selected: true),
                metricBox('Total play time', metric(post, 'playtime')),
                metricBox('Average watch time', metric(post, 'average')),
                metricBox('Watched full video', metric(post, 'completion')),
                metricBox('New followers', metric(post, 'newFollowers')),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 25),
    ],
  );
  Widget metricBox(String label, String value, {bool selected = false}) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? insightBlue.withValues(alpha: .06) : colors.surface,
          border: Border.all(color: selected ? insightBlue : colors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.ink, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

class ViewersTab extends StatelessWidget {
  final ScenePost post;
  final SimColors colors;
  const ViewersTab({super.key, required this.post, required this.colors});
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      AnalyticsCard(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading('Total viewers ⓘ'),
            const SizedBox(height: 7),
            Text(
              metric(post, 'totalViewers'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 26,
                color: colors.ink,
              ),
            ),
            Text(
              '↑ ${metric(post, 'change')}  (vs 1d ago)',
              style: TextStyle(
                color: insightBlue,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      AnalyticsCard(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading('Viewer types ⓘ'),
            const SizedBox(height: 16),
            dualBar(
              metric(post, 'newViewers'),
              metric(post, 'returning'),
              'New viewers',
              'Returning viewers',
            ),
            const SizedBox(height: 20),
            dualBar(
              metric(post, 'nonFollowers'),
              metric(post, 'followers'),
              'Non-followers',
              'Followers',
            ),
          ],
        ),
      ),
      AnalyticsCard(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading('Gender ⓘ'),
            const SizedBox(height: 15),
            SizedBox(
              height: 120,
              width: double.infinity,
              child: CustomPaint(
                painter: GenderPainter(
                  double.tryParse(metric(post, 'male')) ?? 0,
                  double.tryParse(metric(post, 'female')) ?? 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            legend('Male', 'male', insightBlue),
            legend('Female', 'female', const Color(0xff82bdec)),
            legend('Other', 'other', const Color(0xffc9e2f7)),
          ],
        ),
      ),
      AnalyticsCard(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading('Age'),
            const SizedBox(height: 10),
            bar('18 - 24', 'age18'),
            bar('25 - 34', 'age25'),
            bar('35 - 44', 'age35'),
            bar('45 - 54', 'age45'),
            bar('55+', 'age55'),
          ],
        ),
      ),
      AnalyticsCard(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading('Locations ⓘ'),
            const SizedBox(height: 10),
            bar(metric(post, 'location1'), 'location1pct'),
            bar(metric(post, 'location2'), 'location2pct'),
            bar(metric(post, 'location3'), 'location3pct'),
            bar(metric(post, 'location4'), 'location4pct'),
            bar(metric(post, 'location5'), 'location5pct'),
            bar(metric(post, 'location6'), 'location6pct'),
            bar(metric(post, 'location7'), 'location7pct'),
            bar(metric(post, 'location8'), 'location8pct'),
            bar(metric(post, 'location9'), 'location9pct'),
            bar(metric(post, 'location10'), 'location10pct'),
            bar(metric(post, 'location11'), 'location11pct'),
          ],
        ),
      ),
      const SizedBox(height: 24),
    ],
  );
  Widget heading(String s) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: Text(
          s.replaceAll(' ⓘ', ''),
          style: TextStyle(
            color: colors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      if (s.contains('ⓘ')) ...[
        const SizedBox(width: 5),
        Icon(Icons.info_outline, size: 16, color: colors.sub),
      ],
    ],
  );
  Widget dualBar(String left, String right, String l, String r) {
    final n = (double.tryParse(left) ?? 0).clamp(0, 100);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$left%', style: TextStyle(color: colors.ink)),
            Text('$right%', style: TextStyle(color: colors.ink)),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: n / 100,
            minHeight: 10,
            color: insightBlue,
            backgroundColor: const Color(0xff82bdec),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(l, style: TextStyle(color: colors.ink, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                r,
                textAlign: TextAlign.right,
                style: TextStyle(color: colors.ink, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget legend(String label, String key, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Icon(Icons.circle, size: 9, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: colors.ink)),
        const Spacer(),
        Text('${metric(post, key)}%', style: TextStyle(color: colors.ink)),
      ],
    ),
  );
  Widget bar(String title, String key) {
    final value = metric(post, key),
        n = (double.tryParse(metric(post, key)) ?? 0).clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(color: colors.ink, fontSize: 14)),
              const Spacer(),
              Text(
                '$value%',
                style: TextStyle(color: colors.ink, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: n / 100,
              minHeight: 10,
              color: insightBlue,
              backgroundColor: colors.divider,
            ),
          ),
        ],
      ),
    );
  }
}

class GenderPainter extends CustomPainter {
  final double male, female;
  GenderPainter(this.male, this.female);
  @override
  void paint(Canvas canvas, Size size) {
    final width = math.min(size.width * .58, 210.0);
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height),
      width: width,
      height: width,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 29;
    paint.color = const Color(0xffc9e2f7);
    canvas.drawArc(rect, math.pi, math.pi, false, paint);
    paint.color = insightBlue;
    canvas.drawArc(
      rect,
      math.pi,
      math.pi * (male.clamp(0, 100) / 100),
      false,
      paint,
    );
    paint.color = const Color(0xff82bdec);
    canvas.drawArc(
      rect,
      math.pi + math.pi * (male.clamp(0, 100) / 100) + .02,
      math.pi * (female.clamp(0, 100) / 100) - .02,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant GenderPainter old) =>
      old.male != male || old.female != female;
}
