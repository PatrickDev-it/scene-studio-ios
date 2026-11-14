part of 'simulation.dart';

class _FeedNavigation extends StatefulWidget {
  final VoidCallback onSearch;
  const _FeedNavigation({required this.onSearch});

  @override
  State<_FeedNavigation> createState() => _FeedNavigationState();
}

class _FeedNavigationState extends State<_FeedNavigation> {
  int selected = 3;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 43,
    child: Row(
      children: [
        const SizedBox(
          width: 44,
          child: Icon(Icons.live_tv_rounded, color: Colors.white, size: 23),
        ),
        for (final (index, label) in const [
          'New York',
          'Following',
          'BLACK\nFRIDAY',
          'For You',
        ].indexed)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => selected = index),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: index == selected
                            ? Colors.white
                            : Colors.white70,
                        fontSize: index == 2 ? 11 : 15,
                        height: 1,
                        fontStyle: index == 2
                            ? FontStyle.italic
                            : FontStyle.normal,
                        fontWeight: index == selected || index == 2
                            ? FontWeight.w800
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (index == selected)
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 1,
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 2,
                          child: ColoredBox(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        SizedBox(
          width: 45,
          child: IconButton(
            tooltip: 'Search',
            onPressed: widget.onSearch,
            icon: const Icon(TikIcons.search, color: Colors.white, size: 23),
          ),
        ),
      ],
    ),
  );
}

class PreviewLaunchArtwork extends StatelessWidget {
  const PreviewLaunchArtwork({super.key});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: Center(
      child: FractionalTranslation(
        translation: const Offset(0, -.63),
        child: Image.asset('assets/branding/launch-logo.png', width: 132),
      ),
    ),
  );
}

class _InboxBadge extends StatelessWidget {
  final int count;
  const _InboxBadge({required this.count});

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 145),
    transitionBuilder: (child, animation) =>
        ScaleTransition(scale: animation, child: child),
    child: Container(
      key: ValueKey(count),
      constraints: BoxConstraints(minWidth: count < 10 ? 16 : 24),
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hotPink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        maxLines: 1,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          height: 1,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _InboxBubble extends StatelessWidget {
  final VoidCallback onTap;
  final SceneData data;
  const _InboxBubble({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180),
    curve: Curves.easeOutCubic,
    builder: (_, value, child) => Transform.scale(
      scale: .85 + .15 * value,
      alignment: Alignment.bottomCenter,
      child: Opacity(opacity: value, child: child),
    ),
    child: GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: hotPink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (icon, key, fallback) in const [
                    (TikIcons.chat, 'replies', 4),
                    (TikIcons.heart, 'likes', 4),
                    (Icons.person, 'follows', 6),
                  ]) ...[
                    Icon(icon, color: Colors.white, size: 16),
                    Text(
                      ' ${_count(key, fallback)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (key != 'follows') const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(
            width: 15,
            height: 7,
            child: CustomPaint(painter: _BubblePointer()),
          ),
        ],
      ),
    ),
  );

  String _count(String key, int fallback) {
    final value = int.tryParse(data.inbox[key] ?? '') ?? fallback;
    return value > 99 ? '99+' : math.max(0, value).toString();
  }
}

class _BubblePointer extends CustomPainter {
  const _BubblePointer();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = hotPink);
  }

  @override
  bool shouldRepaint(_BubblePointer oldDelegate) => false;
}

class _InboxPreview extends StatelessWidget {
  final SimColors colors;
  final SceneData data;
  const _InboxPreview({required this.colors, required this.data});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _StudioHeader(title: 'Inbox', colors: colors, back: false),
      Expanded(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            for (final (icon, color, title, label) in [
              (
                Icons.person_add_alt_1,
                const Color(0xff17b4cd),
                'New followers',
                'People who followed you',
              ),
              (
                Icons.bolt_rounded,
                hotPink,
                'Activity',
                'Likes, comments and mentions',
              ),
              (
                Icons.notifications,
                const Color(0xff666670),
                'System notifications',
                'Account updates',
              ),
            ])
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: color,
                  child: Icon(icon, color: Colors.white),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(label, style: TextStyle(color: colors.sub)),
              ),
            if (data.inboxUnread > 0)
              ListTile(
                leading: Avatar(path: data.avatar, radius: 20),
                title: Text(
                  data.name,
                  style: TextStyle(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text('Messages', style: TextStyle(color: colors.sub)),
              ),
          ],
        ),
      ),
    ],
  );
}

class _ProfileMenu extends StatelessWidget {
  final SimColors colors;
  final VoidCallback onStudio;
  const _ProfileMenu({required this.colors, required this.onStudio});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final canvas = math.min(screenWidth, _desktopPreviewWidth ?? screenWidth);
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.only(right: (screenWidth - canvas) / 2),
        child: Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: canvas * .85,
            height: double.infinity,
            child: ColoredBox(
              color: colors.bg,
              child: SafeArea(
                left: false,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    section('Assets'),
                    item('Balance', Icons.account_balance_wallet_outlined),
                    Divider(height: 15, color: colors.divider),
                    section('Personal tools'),
                    item('Activity center', Icons.access_time),
                    item('Offline videos', Icons.cloud_download_outlined),
                    item('Your QR code', Icons.qr_code),
                    Divider(height: 15, color: colors.divider),
                    section('Creation & business tools'),
                    item(
                      'TikTok Studio',
                      Icons.person_add_alt,
                      action: onStudio,
                    ),
                    Divider(height: 1, color: colors.divider),
                    item('Settings and privacy', Icons.settings_outlined),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget section(String text) => Padding(
    padding: const EdgeInsets.only(top: 7, bottom: 4),
    child: Text(
      text,
      style: TextStyle(
        color: colors.sub,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget item(String text, IconData icon, {VoidCallback? action}) => InkWell(
    onTap: action,
    child: SizedBox(
      height: 48,
      child: Row(
        children: [
          Icon(icon, color: colors.ink, size: 21),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: colors.sub, size: 19),
        ],
      ),
    ),
  );
}

class _TikLoading extends StatefulWidget {
  const _TikLoading();

  @override
  State<_TikLoading> createState() => _TikLoadingState();
}

class _TikLoadingState extends State<_TikLoading>
    with SingleTickerProviderStateMixin {
  late final motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      motion.stop();
    } else if (!motion.isAnimating) {
      motion.repeat();
    }
  }

  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading',
    child: SizedBox(
      width: 24,
      height: 15,
      child: CustomPaint(painter: _LoadingDots(motion)),
    ),
  );
}

class _LoadingDots extends CustomPainter {
  final Animation<double> motion;
  _LoadingDots(this.motion) : super(repaint: motion);

  @override
  void paint(Canvas canvas, Size size) {
    final phase = motion.value * math.pi * 2;
    final dx = math.cos(phase) * 5.2;
    final depth = math.sin(phase);
    final center = size.center(Offset.zero);
    final cyan = center.translate(-dx, 0), pink = center.translate(dx, 0);
    void dot(Offset offset, Color color, double radius) =>
        canvas.drawCircle(offset, radius, Paint()..color = color);
    if (depth < 0) {
      dot(pink, const Color(0xffed0c53), 5.1 + depth * .7);
      dot(cyan, const Color(0xff25f4ee), 5.1 - depth * .7);
    } else {
      dot(cyan, const Color(0xff25f4ee), 5.1 - depth * .7);
      dot(pink, const Color(0xffed0c53), 5.1 + depth * .7);
    }
    if (dx.abs() < 3) {
      dot(center, const Color(0xff161823), 4 - dx.abs());
    }
  }

  @override
  bool shouldRepaint(_LoadingDots oldDelegate) => oldDelegate.motion != motion;
}

Widget _refreshSliver(Future<void> Function() refresh) =>
    CupertinoSliverRefreshControl(
      refreshTriggerPullDistance: 74,
      refreshIndicatorExtent: 36,
      onRefresh: refresh,
      builder: (_, mode, pulled, trigger, _) => pulled <= 5
          ? const SizedBox.shrink()
          : Center(
              child: Opacity(
                opacity: mode == RefreshIndicatorMode.drag
                    ? (pulled / trigger).clamp(0.0, 1.0)
                    : 1,
                child: const _TikLoading(),
              ),
            ),
    );

class _StudioHeader extends StatelessWidget {
  final String title;
  final SimColors colors;
  final bool back;
  final VoidCallback? settings;
  const _StudioHeader({
    required this.title,
    required this.colors,
    this.back = true,
    this.settings,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    width: double.infinity,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            height: 1.15,
            fontWeight: FontWeight.w700,
            color: colors.ink,
          ),
        ),
        if (back)
          Positioned(
            left: 0,
            child: IconButton(
              tooltip: 'Back',
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new, size: 20, color: colors.ink),
            ),
          ),
        if (settings != null)
          Positioned(
            right: 0,
            child: IconButton(
              tooltip: 'Settings',
              onPressed: settings,
              icon: Transform.translate(
                offset: const Offset(-3, 0),
                child: ImageIcon(
                  const AssetImage('assets/scene/studio-settings.png'),
                  size: 27,
                  color: colors.ink,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _studioFrame(BuildContext context, SimColors colors, Widget child) =>
    AnnotatedRegion<SystemUiOverlayStyle>(
      value: colors.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _desktopPreviewWidth == null
            ? colors.panelBg
            : const Color(0xff28282b),
        body: Center(
          child: SizedBox(
            width: _desktopPreviewWidth,
            child: ColoredBox(
              color: colors.panelBg,
              child: SafeArea(child: child),
            ),
          ),
        ),
      ),
    );

class _StudioPreview extends StatefulWidget {
  final SceneData data;
  final Future<void> Function(String, ScenePost?)? onEdit;
  const _StudioPreview({required this.data, this.onEdit});

  @override
  State<_StudioPreview> createState() => _StudioPreviewState();
}

class _StudioPreviewState extends State<_StudioPreview> {
  int stage = 0;
  bool secondaryReady = false, secondaryRequested = false;

  Future<void> editField(String key) async {
    await widget.onEdit?.call('studio/$key', null);
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    await Future<void>.delayed(_studioLoadingTime);
    if (!mounted) return;
    setState(() => stage = 1);
    await Future<void>.delayed(_studioCardsTime);
    if (mounted) setState(() => stage = 2);
  }

  void openAnalytics() => Navigator.push<void>(
    context,
    CupertinoPageRoute(
      builder: (_) =>
          _StudioAnalytics(data: widget.data, onEdit: widget.onEdit),
    ),
  );

  Future<void> refresh() async {
    await Future<void>.delayed(_profileRefreshTime);
    if (mounted) setState(() => secondaryReady = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = SimColors(widget.data.darkMode);
    return DefaultTabController(
      length: 2,
      child: _studioFrame(
        context,
        c,
        Column(
          children: [
            _StudioHeader(
              title: 'TikTok Studio',
              colors: c,
              settings: () {
                Navigator.push<void>(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => _studioFrame(
                      context,
                      c,
                      Column(
                        children: [
                          _StudioHeader(title: 'Settings', colors: c),
                          ListTile(
                            title: Text(
                              'Notifications',
                              style: TextStyle(color: c.ink),
                            ),
                          ),
                          ListTile(
                            title: Text(
                              'Settings and privacy',
                              style: TextStyle(color: c.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            LayoutBuilder(
              builder: (context, constraints) => TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: EdgeInsets.zero,
                labelStyle: const TextStyle(
                  fontFamily: 'TikTokSans',
                  fontSize: 15,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'TikTokSans',
                  fontSize: 15,
                  height: 1.15,
                  fontWeight: FontWeight.w500,
                ),
                labelColor: c.ink,
                unselectedLabelColor: c.sub,
                indicatorColor: c.ink,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: [
                  SizedBox(
                    width: constraints.maxWidth * 200 / 375,
                    child: const Tab(height: 39, text: 'Posts'),
                  ),
                  SizedBox(
                    width: constraints.maxWidth * 165 / 375,
                    child: const Tab(height: 39, text: 'LIVE'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  if (stage == 0)
                    const Center(child: _TikLoading())
                  else
                    NotificationListener<ScrollUpdateNotification>(
                      onNotification: (notification) {
                        if (stage == 2 &&
                            !secondaryRequested &&
                            notification.metrics.pixels > 60) {
                          revealSecondary();
                        }
                        return false;
                      },
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        slivers: [
                          _refreshSliver(refresh),
                          SliverToBoxAdapter(
                            child: stage == 1
                                ? Column(
                                    children: [
                                      for (final height in [
                                        168.0,
                                        123.0,
                                        300.0,
                                      ])
                                        AnalyticsCard(
                                          colors: c,
                                          child: SizedBox(
                                            height: height - 36,
                                            child: const Center(
                                              child: _TikLoading(),
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      AnalyticsCard(
                                        colors: c,
                                        margin: const EdgeInsets.fromLTRB(
                                          12,
                                          12,
                                          12,
                                          0,
                                        ),
                                        radius: 15,
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          15,
                                          16,
                                          15,
                                        ),
                                        child: InkWell(
                                          onTap: openAnalytics,
                                          onLongPress: widget.onEdit == null
                                              ? null
                                              : () async {
                                                  await widget.onEdit!(
                                                    'studio',
                                                    null,
                                                  );
                                                  if (mounted) setState(() {});
                                                },
                                          child: Column(
                                            children: [
                                              _studioTitle(
                                                'Analytics',
                                                c,
                                                arrow: true,
                                              ),
                                              const SizedBox(height: 15),
                                              Row(
                                                children: [
                                                  _studioNumber(
                                                    'Post views',
                                                    widget
                                                            .data
                                                            .studio['summaryViews'] ??
                                                        formatCount(
                                                          _studioViews(
                                                            widget.data,
                                                          ),
                                                        ),
                                                    c,
                                                    delta: widget
                                                        .data
                                                        .studio['summaryViewsDelta'],
                                                    onTap: widget.onEdit == null
                                                        ? null
                                                        : () => editField(
                                                            'summaryViews',
                                                          ),
                                                    onLongPress:
                                                        widget.onEdit == null
                                                        ? null
                                                        : () => editField(
                                                            'summaryViewsDelta',
                                                          ),
                                                  ),
                                                  _studioNumber(
                                                    'Net followers',
                                                    widget
                                                            .data
                                                            .studio['summaryFollowers'] ??
                                                        widget.data.followers,
                                                    c,
                                                    delta: widget
                                                        .data
                                                        .studio['summaryFollowersDelta'],
                                                    onTap: widget.onEdit == null
                                                        ? null
                                                        : () => editField(
                                                            'summaryFollowers',
                                                          ),
                                                    onLongPress:
                                                        widget.onEdit == null
                                                        ? null
                                                        : () => editField(
                                                            'summaryFollowersDelta',
                                                          ),
                                                  ),
                                                  _studioNumber(
                                                    'Likes',
                                                    widget
                                                            .data
                                                            .studio['summaryLikes'] ??
                                                        formatCount(
                                                          _studioLikes(
                                                            widget.data,
                                                          ),
                                                        ),
                                                    c,
                                                    delta: widget
                                                        .data
                                                        .studio['summaryLikesDelta'],
                                                    onTap: widget.onEdit == null
                                                        ? null
                                                        : () => editField(
                                                            'summaryLikes',
                                                          ),
                                                    onLongPress:
                                                        widget.onEdit == null
                                                        ? null
                                                        : () => editField(
                                                            'summaryLikesDelta',
                                                          ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      AnalyticsCard(
                                        colors: c,
                                        margin: const EdgeInsets.fromLTRB(
                                          12,
                                          9,
                                          12,
                                          0,
                                        ),
                                        radius: 15,
                                        padding: const EdgeInsets.fromLTRB(
                                          11,
                                          8,
                                          11,
                                          8,
                                        ),
                                        child: Stack(
                                          children: [
                                            Row(
                                              children: [
                                                GestureDetector(
                                                  onTap: widget.onEdit == null
                                                      ? null
                                                      : () => editField(
                                                          'bannerImage',
                                                        ),
                                                  child: _StudioBannerArtwork(
                                                    path:
                                                        widget
                                                            .data
                                                            .studio['bannerImage'] ??
                                                        '',
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      GestureDetector(
                                                        onTap:
                                                            widget.onEdit ==
                                                                null
                                                            ? null
                                                            : () => editField(
                                                                'bannerTitle',
                                                              ),
                                                        child: Text(
                                                          widget
                                                                  .data
                                                                  .studio['bannerTitle'] ??
                                                              '#DailyLife Post Contest',
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: c.ink,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 7),
                                                      GestureDetector(
                                                        onTap:
                                                            widget.onEdit ==
                                                                null
                                                            ? null
                                                            : () => editField(
                                                                'bannerText',
                                                              ),
                                                        child: Text(
                                                          widget
                                                                  .data
                                                                  .studio['bannerText'] ??
                                                              r'Win up to $2,000 in rewards',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: hotPink,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Positioned(
                                              right: 2,
                                              bottom: 1,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 10,
                                                    height: 4,
                                                    decoration: BoxDecoration(
                                                      color: c.ink,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            3,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    width: 4,
                                                    height: 4,
                                                    decoration: BoxDecoration(
                                                      color: c.divider,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _monetization(c),
                                      AnalyticsCard(
                                        colors: c,
                                        child: secondaryReady
                                            ? Column(
                                                children: [
                                                  _studioTitle(
                                                    'Inspiration',
                                                    c,
                                                    arrow: true,
                                                  ),
                                                  const SizedBox(height: 10),
                                                  _studioPills(
                                                    [
                                                      'Topics',
                                                      'Posts',
                                                      'Creators',
                                                      'Searches',
                                                    ],
                                                    0,
                                                    c,
                                                    (_) {},
                                                  ),
                                                  for (final topic
                                                      in _studioTopics(
                                                        widget.data,
                                                      ).take(3))
                                                    ListTile(
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                      title: Text(
                                                        topic,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color: c.ink,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              )
                                            : SizedBox(
                                                height: 89,
                                                child: secondaryRequested
                                                    ? const Center(
                                                        child: _TikLoading(),
                                                      )
                                                    : null,
                                              ),
                                      ),
                                      AnalyticsCard(
                                        colors: c,
                                        child: _studioTitle(
                                          'More Tools',
                                          c,
                                          arrow: true,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  Center(
                    child: Text(
                      widget.data.studio['liveText'] ?? 'No LIVE data',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.sub),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> revealSecondary() async {
    setState(() => secondaryRequested = true);
    await Future<void>.delayed(const Duration(milliseconds: 690));
    if (mounted) setState(() => secondaryReady = true);
  }

  Widget _monetization(SimColors c) => AnalyticsCard(
    colors: c,
    margin: const EdgeInsets.fromLTRB(12, 9, 12, 0),
    radius: 15,
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
    child: Column(
      children: [
        _studioTitle('Monetization', c, arrow: true),
        const SizedBox(height: 17),
        Row(
          children: [
            _promo(
              widget.data.studio['promo1Title'] ?? 'TikTok Shop for Creators',
              widget.data.studio['promo1Text'] ??
                  'Get paid to share products you love.',
              'studio-promo-shop-bg',
              'promo1Title',
              'promo1Text',
            ),
            const SizedBox(width: 8),
            _promo(
              widget.data.studio['promo2Title'] ?? 'Work with Artists',
              widget.data.studio['promo2Text'] ??
                  'Create posts with featured sounds.',
              'studio-promo-artists-bg',
              'promo2Title',
              'promo2Text',
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 84,
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth:
                math.min(
                  MediaQuery.sizeOf(context).width,
                  _desktopPreviewWidth ?? double.infinity,
                ) -
                28,
            maxWidth:
                math.min(
                  MediaQuery.sizeOf(context).width,
                  _desktopPreviewWidth ?? double.infinity,
                ) -
                28,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (icon, text, dx, dy) in [
                    ('studio-live', 'LIVE Incentive Program', -1.0, -1.0),
                    ('studio-service', 'Service+', 0.0, -2.0),
                    ('studio-rewards', 'LIVE rewards', 2.0, -2.0),
                    ('studio-creator', 'Creator Marketplace', 1.0, -2.0),
                  ]) ...[
                    SizedBox(
                      width: 72,
                      child: Column(
                        children: [
                          Container(
                            height: 48,
                            width: 72,
                            decoration: BoxDecoration(
                              color: c.dark
                                  ? c.panelBg
                                  : const Color(0xfffaf7fa),
                              border: Border.all(color: c.divider, width: .7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Transform.translate(
                                offset: Offset(dx, dy),
                                child: ImageIcon(
                                  AssetImage('assets/scene/$icon.png'),
                                  color: c.ink,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            text,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.ink, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    width: 72,
                    height: 48,
                    decoration: BoxDecoration(
                    color: c.dark
                        ? c.panelBg
                        : const Color(0xfffaf7fa),
                      border: Border.all(color: c.divider, width: .7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: c.chip,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            'More ways to get paid',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.ink,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _promo(
    String title,
    String details,
    String background,
    String titleKey,
    String detailsKey,
  ) => Expanded(
    child: Container(
      height: 178,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage('assets/scene/$background.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: 'TikTokSans',
          color: Colors.black,
          fontSize: 14,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 29),
            GestureDetector(
              onTap: widget.onEdit == null ? null : () => editField(titleKey),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 5),
            GestureDetector(
              onTap: widget.onEdit == null ? null : () => editField(detailsKey),
              child: Text(
                details,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StudioBannerArtwork extends StatelessWidget {
  final String path;
  const _StudioBannerArtwork({required this.path});

  @override
  Widget build(BuildContext context) {
    final image = sceneImage(path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 66,
        height: 66,
        child: image != null
            ? Image(image: image, fit: BoxFit.cover)
            : const ColoredBox(
                color: Color(0xffd9edf8),
                child: Icon(
                  Icons.emoji_events_outlined,
                  color: Color(0xffbe7737),
                ),
              ),
      ),
    );
  }
}

int _studioViews(SceneData data) =>
    data.posts.fold(0, (total, post) => total + parseCount(post.views));
int _studioLikes(SceneData data) =>
    data.posts.fold(0, (total, post) => total + parseCount(post.likes));

List<String> _studioTopics(SceneData data) {
  final topics = data.studio['topics']
      ?.split('\n')
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .toList();
  return topics == null || topics.isEmpty
      ? [for (final post in data.posts) post.caption]
      : topics;
}

Widget _studioTitle(
  String title,
  SimColors c, {
  bool arrow = false,
  bool info = false,
}) => Row(
  children: [
    if (info) ...[
      Flexible(child: _studioTitleText(title, c)),
      const SizedBox(width: 5),
      Icon(Icons.info_outline, size: 14, color: c.sub),
    ] else
      Expanded(child: _studioTitleText(title, c)),
    if (arrow) Icon(Icons.chevron_right, size: 19, color: c.ink),
  ],
);

Widget _studioTitleText(String title, SimColors c) => Text(
  title,
  style: TextStyle(
    color: c.ink,
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w700,
  ),
);

Widget _studioNumber(
  String label,
  String value,
  SimColors c, {
  String? delta,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
}) => Expanded(
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    onLongPress: onLongPress,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: c.ink,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label == 'Post views' ? formatViewCount(value) : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: c.ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        _metricChange(label, value, c, override: delta, summary: true),
      ],
    ),
  ),
);

Widget _metricChange(
  String label,
  String value,
  SimColors colors, {
  String? override,
  String? changeValue,
  bool summary = false,
}) {
  final percentage =
      _sceneDecimal(override) ??
      switch (label) {
        'Post views' => 367.0,
        'Profile views' => 573.0,
        'Net followers' => 220.0,
        'Likes' => 551.0,
        'Comments' => 119.0,
        'Shares' => 212.0,
        _ => 0.0,
      };
  if (percentage == 0 || parseCount(value) == 0) {
    return label == 'Est. rewards'
        ? Text(r'+$0.00', style: TextStyle(color: colors.sub, fontSize: 13))
        : const SizedBox(height: 17);
  }
  final current = parseCount(value);
  final change = percentage <= -100
      ? -current
      : current - (current / (1 + percentage / 100)).round();
  final down = percentage < 0;
  final percent = percentage
      .abs()
      .toStringAsFixed(1)
      .replaceFirst(RegExp(r'\.0$'), '');
  final String sign = down ? '−' : '+';
  return Text.rich(
    TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: summary
              ? Transform.translate(
                  offset: const Offset(0, -2),
                  child: CustomPaint(
                    size: const Size(10, 7),
                    painter: _StudioDeltaTriangle(
                      colors.dark ? const Color(0xff85c9fc) : insightBlue,
                      down,
                    ),
                  ),
                )
              : Icon(
                  down ? Icons.arrow_circle_down : Icons.arrow_circle_up,
                  size: 15,
                  color: colors.dark ? const Color(0xff85c9fc) : insightBlue,
                ),
        ),
        TextSpan(
          text: summary
              ? ' $percent%'
              : ' $sign${changeValue ?? formatCount(change.abs())}',
        ),
        TextSpan(
          text: summary ? '  7d' : ' ($sign$percent%)',
          style: TextStyle(color: colors.sub, fontWeight: FontWeight.w400),
        ),
      ],
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      color: colors.dark ? const Color(0xff85c9fc) : insightBlue,
      fontWeight: FontWeight.w600,
      fontSize: 13,
      height: 1.3,
    ),
  );
}

class _StudioDeltaTriangle extends CustomPainter {
  final Color color;
  final bool down;
  const _StudioDeltaTriangle(this.color, this.down);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(1, down ? 1 : 6)
      ..lineTo(8, down ? 1 : 6)
      ..lineTo(4.5, down ? 6 : 1)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StudioDeltaTriangle oldDelegate) =>
      oldDelegate.color != color || oldDelegate.down != down;
}

double? _sceneDecimal(String? value) {
  final number = double.tryParse(
    (value ?? '').trim().replaceAll('%', '').replaceAll(',', '.'),
  );
  return number != null && number.isFinite
      ? number.clamp(-100, 9999999).toDouble()
      : null;
}

List<(String, double)> _sceneRatios(
  String? input,
  List<(String, double)> defaults,
) {
  final rows = <(String, double)>[];
  for (final line in (input ?? '').split('\n')) {
    final separator = line.lastIndexOf(':');
    if (separator < 1) continue;
    final label = line.substring(0, separator).trim();
    final value = _sceneDecimal(line.substring(separator + 1));
    if (label.isNotEmpty && value != null) {
      rows.add((label, value.clamp(0, 100).toDouble()));
    }
  }
  return rows.isEmpty ? defaults : rows;
}

List<double>? _sceneSeries(String? input) {
  final values = (input ?? '')
      .split(';')
      .map(_sceneDecimal)
      .whereType<double>()
      .where((v) => v >= 0)
      .take(48)
      .toList();
  return values.length < 2 ? null : values;
}

Widget _studioPills(
  List<String> labels,
  int selected,
  SimColors c,
  ValueChanged<int> onSelect, {
  bool blue = false,
}) => SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      for (var i = 0; i < labels.length; i++)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(blue ? 6 : 20),
                color: i != selected
                    ? c.chip
                    : blue
                    ? insightBlue.withValues(alpha: .1)
                    : c.ink,
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: i != selected
                      ? c.sub
                      : blue
                      ? insightBlue
                      : c.bg,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
    ],
  ),
);

class _StudioAnalytics extends StatefulWidget {
  final SceneData data;
  final Future<void> Function(String, ScenePost?)? onEdit;
  const _StudioAnalytics({required this.data, this.onEdit});

  @override
  State<_StudioAnalytics> createState() => _StudioAnalyticsState();
}

class _StudioAnalyticsState extends State<_StudioAnalytics> {
  static const tabs = [
    'Inspiration',
    'Overview',
    'Content',
    'Viewers',
    'Followers',
    'LIVE',
  ];
  var range = 0, inspiration = 0, ranking = 0, breakdown = 0, request = 0;
  bool loading = true, showAll = false, activityDays = false;

  Future<void> editValue(String key) async {
    await widget.onEdit?.call('period/$range/$key', null);
    if (mounted) setState(() {});
  }

  Widget editableValue(String key, Widget child) => widget.onEdit == null
      ? child
      : GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => editValue(key),
          child: child,
        );

  Map<String, String> get config =>
      widget.data.studioPeriods[range.toString()] ?? const {};

  @override
  void initState() {
    super.initState();
    finishLoading(_analyticsLoadingTime);
  }

  Future<void> finishLoading(Duration delay) async {
    final id = ++request;
    await Future<void>.delayed(delay);
    if (mounted && id == request) setState(() => loading = false);
  }

  Future<void> selectRange(int value) async {
    setState(() {
      range = value;
      loading = true;
    });
    await finishLoading(const Duration(milliseconds: 1040));
  }

  @override
  Widget build(BuildContext context) {
    final c = SimColors(widget.data.darkMode);
    return DefaultTabController(
      length: tabs.length,
      initialIndex: 1,
      child: _studioFrame(
        context,
        c,
        Column(
          children: [
            _StudioHeader(title: 'Analytics', colors: c),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.only(left: 16),
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontFamily: 'TikTokSans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'TikTokSans',
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              labelColor: c.ink,
              unselectedLabelColor: c.sub,
              indicatorColor: c.ink,
              tabs: [for (final label in tabs) Tab(height: 39, text: label)],
            ),
            Expanded(
              child: TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [for (var i = 0; i < tabs.length; i++) _page(i, c)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page(int index, SimColors c) => CustomScrollView(
    key: PageStorageKey('studio-stats-$index'),
    physics: const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
    slivers: [
      _refreshSliver(() => selectRange(range)),
      SliverList.list(
        children: [
          if (index != 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 3),
              child: _studioPills(studioPeriodLabels, range, c, selectRange),
            ),
          if (loading) ...[
            for (final height in [40.0, 92.0, 88.0, 132.0])
              AnalyticsCard(
                colors: c,
                child: SizedBox(
                  height: height,
                  width: double.infinity,
                  child: ColoredBox(color: c.panelBg),
                ),
              ),
          ] else
            ...switch (index) {
              0 => [_inspiration(c)],
              2 => [_topPosts(c)],
              3 => [
                _metrics(c, index),
                _audience(c, 'Viewer insights'),
                _activeTimes(c, 'viewer'),
              ],
              4 => [
                _metrics(c, index),
                _audience(c, 'Follower insights'),
                _activeTimes(c, 'follower'),
              ],
              5 => [_metrics(c, index)],
              _ => [_metrics(c, index), _traffic(c)],
            },
          const SizedBox(height: 12),
        ],
      ),
    ],
  );

  Widget _metrics(SimColors c, int index) {
    final scene = widget.data;
    final total = _studioViews(scene);
    final factor = const [1.0, 1.17, 1.25, 1.49][range];
    final views = (total * factor).round();
    String value(String key, String fallback) => config[key] ?? fallback;
    final fields = switch (index) {
      3 => [
        (
          'viewers',
          'Total viewers',
          value('viewers', formatCount((views * .72).round())),
        ),
        (
          'newViewers',
          'New viewers',
          value('newViewers', formatCount((views * .705).round())),
        ),
      ],
      4 => [
        ('followers', 'Total followers', value('followers', scene.followers)),
        (
          'netFollowers',
          'Net followers',
          value(
            'netFollowers',
            formatCount((parseCount(scene.followers) * .95).round()),
          ),
        ),
      ],
      5 => [
        ('liveViews', 'LIVE views', value('liveViews', '0')),
        ('liveFollowers', 'New followers', value('liveFollowers', '0')),
      ],
      _ => [
        ('postViews', 'Post views', value('postViews', formatCount(views))),
        (
          'profileViews',
          'Profile views',
          value('profileViews', formatCount((views * .032).round())),
        ),
        ('likes', 'Likes', value('likes', formatCount(_studioLikes(scene)))),
        (
          'comments',
          'Comments',
          value(
            'comments',
            formatCount(
              scene.posts.fold(0, (n, p) => n + parseCount(p.comments)),
            ),
          ),
        ),
        (
          'shares',
          'Shares',
          value(
            'shares',
            formatCount(
              scene.posts.fold(0, (n, p) => n + parseCount(p.shares)),
            ),
          ),
        ),
        ('rewards', 'Est. rewards', value('rewards', r'$0.00')),
      ],
    };
    final axis =
        config[switch (index) {
          3 => 'viewerChartAxis',
          4 || 5 => '',
          _ => 'chartAxis',
        }];
    return AnalyticsCard(
      colors: c,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _studioTitle('Key metrics', c, info: true),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: widget.onEdit == null
                ? null
                : () async {
                    await widget.onEdit!('period/$range/date', null);
                    if (mounted) setState(() {});
                  },
            child: Text(
              config['date'] ??
                  const [
                    'Nov 6 – Nov 12',
                    'Oct 16 – Nov 12',
                    'Sep 14 – Nov 12',
                    'Nov 13, 2025 – Nov 12, 2026',
                  ][range],
              style: TextStyle(
                color: c.sub,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < fields.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  _metricCell(fields[i], c, i == 0),
                  const SizedBox(width: 8),
                  _metricCell(fields[i + 1], c, false),
                ],
              ),
            ),
          const SizedBox(height: 17),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onLongPress: widget.onEdit == null
                            ? null
                            : () async {
                                await widget.onEdit!(
                                  'period/$range/${index == 3 ? 'viewerChart' : 'chart'}',
                                  null,
                                );
                                if (mounted) setState(() {});
                              },
                        child: SizedBox(
                          width: double.infinity,
                          height: 153,
                          child: CustomPaint(
                            painter: _StudioChart(
                              c,
                              lateSpike: range == 3 || index == 4,
                              axisMaximum: _sceneSeries(axis)?.first,
                              series: _sceneSeries(
                                config[switch (index) {
                                  3 => 'viewerChart',
                                  4 => 'followerChart',
                                  5 => 'liveChart',
                                  _ => 'chart',
                                }],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            const [
                              'Nov 6',
                              'Oct 16',
                              'Sep 14',
                              'Nov 13, 2025',
                            ][range],
                            style: TextStyle(color: c.sub, fontSize: 11),
                          ),
                          Text(
                            range == 3 ? 'Nov 12, 2026' : 'Nov 12',
                            style: TextStyle(color: c.sub, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (axis != null) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 34,
                    height: 110,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final label in axis.split(';').take(3))
                          Text(
                            formatViewCount(label),
                            style: TextStyle(color: c.sub, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCell(
    (String, String, String) entry,
    SimColors c,
    bool selected,
  ) => Expanded(
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onEdit == null
          ? null
          : () async {
              await widget.onEdit!('period/$range/${entry.$1}', null);
              if (mounted) setState(() {});
            },
      onLongPress: widget.onEdit == null
          ? null
          : () async {
              await widget.onEdit!('period/$range/${entry.$1}Delta', null);
              if (mounted) setState(() {});
            },
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 12, 11, 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: selected
              ? c.dark
                    ? insightBlue.withValues(alpha: .12)
                    : const Color(0xfff2faff)
              : c.surface,
          border: Border.all(color: selected ? insightBlue : c.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.$2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.ink,
                fontSize: 13,
                height: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              const {
                    'postViews',
                    'profileViews',
                    'viewers',
                    'newViewers',
                    'liveViews',
                  }.contains(entry.$1)
                  ? formatViewCount(entry.$3)
                  : entry.$3,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            _metricChange(
              entry.$2,
              entry.$3,
              c,
              override: config['${entry.$1}Delta'],
              changeValue: config['${entry.$1}Change'],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _traffic(SimColors c) => AnalyticsCard(
    colors: c,
    child: Column(
      children: [
        editableValue('traffic', _studioTitle('Traffic source', c)),
        for (final (label, percent) in _sceneRatios(config['traffic'], [
          ('For You', 94.3),
          ('Personal profile', 4.2),
          ('Search', 1.5),
        ]))
          _ratio(label, percent, c),
      ],
    ),
  );

  Widget _inspiration(SimColors c) => AnalyticsCard(
    colors: c,
    child: Column(
      children: [
        _studioTitle('Creation Inspiration', c),
        const SizedBox(height: 10),
        _studioPills(
          ['Trending topics', 'Similar posts', 'Followers'],
          inspiration,
          c,
          (i) => setState(() => inspiration = i),
        ),
        for (final (index, topic) in _studioTopics(
          widget.data,
        ).take(10).indexed)
          ListTile(
            title: Text(
              topic,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.ink, fontSize: 13),
            ),
            trailing: index < widget.data.posts.length
                ? SizedBox(
                    width: 36,
                    height: 42,
                    child: PostCover(
                      post: widget.data.posts[index],
                      index: index,
                    ),
                  )
                : null,
          ),
      ],
    ),
  );

  Widget _topPosts(SimColors c) {
    int score(ScenePost post) => switch (ranking) {
      1 => parseCount(metric(post, 'totalViewers')),
      2 => parseCount(post.likes),
      _ => parseCount(post.views),
    };
    final posts = widget.data.posts.indexed.toList()
      ..sort((a, b) => score(b.$2).compareTo(score(a.$2)));
    return AnalyticsCard(
      colors: c,
      child: Column(
        children: [
          _studioTitle('Your top posts', c),
          const SizedBox(height: 10),
          _studioPills(
            ['Most views', 'Most new viewers', 'Most likes'],
            ranking,
            c,
            (i) => setState(() => ranking = i),
            blue: true,
          ),
          for (final (rank, entry) in posts.take(10).indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (rank + 1).toString(),
                    style: TextStyle(color: c.ink, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 42,
                    height: 54,
                    child: PostCover(post: entry.$2, index: entry.$1),
                  ),
                ],
              ),
              title: Text(
                entry.$2.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                '${entry.$2.views} views',
                style: TextStyle(color: c.sub, fontSize: 11),
              ),
              onTap: () => Navigator.push<void>(
                context,
                CupertinoPageRoute(
                  builder: (_) =>
                      AnalyticsPage(post: entry.$2, data: widget.data),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _audience(SimColors c, String title) {
    final prefix = title.startsWith('Follower') ? 'follower' : 'viewer';
    final gender = _sceneRatios(config['${prefix}Gender'], [
      ('Male', 65),
      ('Female', 33),
      ('Other', 2),
    ]);
    final age = _sceneRatios(config['${prefix}Age'], [
      ('18 - 24', 36),
      ('25 - 34', 31),
      ('35 - 44', 17),
      ('45 - 54', 12),
      ('55+', 4),
    ]);
    final locations = _sceneRatios(config['${prefix}Locations'], [
      if (range == 3) ...[
        ('United States', 17.4),
        ('Philippines', 14.2),
        ('South Africa', 8.6),
        ('Canada', 5.5),
        ('Australia', 5.1),
      ] else ...[
        ('Philippines', 16.4),
        ('South Africa', 9.8),
        ('United States', 7),
        ('Canada', 6.1),
        ('Australia', 5.7),
      ],
      ('United Kingdom', 4.7),
      ('Other', 37.5),
    ]);
    const legendColors = [insightBlue, Color(0xff82bdec), Color(0xffb8d9f2)];
    return AnalyticsCard(
      colors: c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          editableValue(
            '$prefix${const ['Gender', 'Age', 'Locations'][breakdown]}',
            _studioTitle(title, c, info: true),
          ),
          const SizedBox(height: 10),
          _studioPills(
            ['Gender', 'Age', 'Locations'],
            breakdown,
            c,
            (i) => setState(() => breakdown = i),
            blue: true,
          ),
          if (breakdown == 0) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 92,
              child: CustomPaint(
                painter: GenderPainter(
                  gender.first.$2,
                  gender.length > 1 ? gender[1].$2 : 0,
                ),
              ),
            ),
            const SizedBox(height: 13),
            for (final (index, entry) in gender.indexed) ...[
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: legendColors[index % legendColors.length],
                      size: 8,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        entry.$1,
                        style: TextStyle(
                          color: c.ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      _percentLabel(entry.$2),
                      style: TextStyle(
                        color: c.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (index + 1 < gender.length)
                Divider(height: 1, color: c.divider),
            ],
          ] else if (breakdown == 1)
            for (final (label, ratio) in age) _ratio(label, ratio, c)
          else ...[
            for (final (label, ratio) in locations.take(
              showAll ? locations.length : 5,
            ))
              _ratio(label, ratio, c, location: true),
            if (locations.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: c.chip,
                      foregroundColor: c.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () => setState(() => showAll = !showAll),
                    child: Text(showAll ? 'See less' : 'See more'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _percentLabel(double value) =>
      '${value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')}%';

  Widget _ratio(
    String name,
    double value,
    SimColors c, {
    bool location = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.ink, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _percentLabel(value),
              style: TextStyle(
                color: c.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (location) Icon(Icons.chevron_right, size: 14, color: c.ink),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 10,
            color: insightBlue,
            backgroundColor: c.chip,
          ),
        ),
      ],
    ),
  );

  Widget _activeTimes(SimColors c, String prefix) => AnalyticsCard(
    colors: c,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        editableValue(
          '${prefix}Active',
          _studioTitle('Most active times', c, info: true),
        ),
        const SizedBox(height: 8),
        _studioPills(
          ['Hours', 'Days'],
          activityDays ? 1 : 0,
          c,
          (i) => setState(() => activityDays = i == 1),
          blue: true,
        ),
        const SizedBox(height: 8),
        editableValue(
          '${prefix}Active',
          Text(
            config['${prefix}Active'] ?? 'In the last 7 days, your viewers were most active on Thursday, between 5pm and 6pm.',
            style: TextStyle(color: c.ink, fontSize: 13),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onLongPress: widget.onEdit == null
              ? null
              : () => editValue('$prefix${activityDays ? 'Days' : 'Hours'}'),
          child: SizedBox(
            width: double.infinity,
            height: 116,
            child: CustomPaint(
              painter: _StudioChart(
                c,
                bars: true,
                lateSpike: activityDays,
                series: _sceneSeries(
                  config['$prefix${activityDays ? 'Days' : 'Hours'}'],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _StudioChart extends CustomPainter {
  final SimColors colors;
  final bool lateSpike, bars;
  final List<double>? series;
  final double? axisMaximum;
  const _StudioChart(
    this.colors, {
    this.lateSpike = false,
    this.bars = false,
    this.series,
    this.axisMaximum,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = colors.divider;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      if (i == 3 || bars) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      } else {
        for (var x = 0.0; x < size.width; x += 5) {
          canvas.drawLine(
            Offset(x, y),
            Offset(math.min(x + 2.5, size.width), y),
            gridPaint,
          );
        }
      }
    }
    final samples = series;
    final maximum = math.max(
      axisMaximum ?? 1.0,
      samples?.reduce(math.max) ?? 1.0,
    );
    if (bars) {
      final count = samples?.length ?? (lateSpike ? 7 : 24);
      final peak = samples?.indexOf(maximum) ?? count - 3;
      for (var i = 0; i < count; i++) {
        final width = size.width / count;
        final height =
            size.height *
            (samples == null
                ? .14 + .52 * i / count + .09 * math.sin(i * .94)
                : .94 * samples[i] / maximum);
        canvas.drawRect(
          Rect.fromLTWH(i * width, size.height - height, width - 2, height),
          Paint()..color = insightBlue.withValues(alpha: i == peak ? 1 : .22),
        );
      }
      return;
    }
    final values = samples == null
        ? lateSpike
              ? [.91, .91, .91, .90, .89, .85, .67, .09]
              : [.12, .32, .72, .91, .91, .89, .75]
        : samples
              .map(
                (value) =>
                    1 - (axisMaximum == null ? .94 : 1) * value / maximum,
              )
              .toList();
    final line = Path();
    for (final (index, value) in values.indexed) {
      final x = size.width * index / (values.length - 1);
      final y = size.height * value;
      index == 0 ? line.moveTo(x, y) : line.lineTo(x, y);
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x440672d8), Color(0x020672d8)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = insightBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    if (samples != null && samples.length <= 12) {
      for (final (index, value) in values.indexed) {
        final point = Offset(
          size.width * index / (values.length - 1),
          size.height * value,
        );
        canvas.drawCircle(point, 2.1, Paint()..color = colors.surface);
        canvas.drawCircle(
          point,
          2.1,
          Paint()
            ..color = insightBlue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StudioChart oldDelegate) =>
      oldDelegate.colors.dark != colors.dark ||
      oldDelegate.lateSpike != lateSpike ||
      oldDelegate.bars != bars ||
      oldDelegate.series != series ||
      oldDelegate.axisMaximum != axisMaximum;
}
