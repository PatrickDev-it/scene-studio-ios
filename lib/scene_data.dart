import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScenePost {
  String id,
      caption,
      video,
      cover,
      likes,
      comments,
      saves,
      shares,
      views,
      audio;
  String scheduledLabel;
  Map<String, String> analytics;
  String sampleComments;
  ScenePost({
    required this.id,
    this.caption = '',
    this.video = '',
    this.cover = '',
    this.likes = '1.2K',
    this.comments = '24',
    this.saves = '81',
    this.shares = '12',
    this.views = '1.2K',
    this.audio = 'suono originale',
    this.scheduledLabel = '',
    Map<String, String>? analytics,
    this.sampleComments = '',
  }) : analytics = analytics ?? {};
  factory ScenePost.fromJson(Map<String, dynamic> j) => ScenePost(
    id: j['id'] ?? '',
    caption: j['caption'] ?? '',
    video: j['video'] ?? '',
    cover: j['cover'] ?? '',
    likes: j['likes'] ?? '0',
    comments: j['comments'] ?? '0',
    saves: j['saves'] ?? '0',
    shares: j['shares'] ?? '0',
    views: j['views'] ?? '0',
    audio: j['audio'] ?? '',
    scheduledLabel: j['scheduledLabel'] ?? '',
    analytics: Map<String, String>.from(j['analytics'] ?? {}),
    sampleComments: j['sampleComments'] ?? '',
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'caption': caption,
    'video': video,
    'cover': cover,
    'likes': likes,
    'comments': comments,
    'saves': saves,
    'shares': shares,
    'views': views,
    'audio': audio,
    'scheduledLabel': scheduledLabel,
    'analytics': analytics,
    'sampleComments': sampleComments,
  };
}

enum StartupMode { last, viewer, setup }

class SceneData {
  String name, handle, bio, avatar, followers, following, likes;
  List<ScenePost> posts;
  bool darkMode;
  int inboxUnread;
  StartupMode startupMode;
  bool? lastWasViewer;
  List<String>? homePostIds;
  Map<String, String> inbox, studio;
  Map<String, Map<String, String>> studioPeriods;
  SceneData({
    this.name = 'Il tuo brand',
    this.handle = 'il.tuo.brand',
    this.bio = 'La tua prossima storia inizia qui.',
    this.avatar = '',
    this.followers = '12.4K',
    this.following = '128',
    this.likes = '248K',
    required this.posts,
    this.darkMode = false,
    this.inboxUnread = 15,
    this.startupMode = StartupMode.last,
    this.lastWasViewer,
    this.homePostIds,
    Map<String, String>? inbox,
    Map<String, String>? studio,
    Map<String, Map<String, String>>? studioPeriods,
  }) : inbox = inbox ?? {},
       studio = studio ?? {},
       studioPeriods = studioPeriods ?? {};

  List<ScenePost> get homePosts {
    final ids = homePostIds;
    if (ids == null) return posts;
    final byId = {for (final post in posts) post.id: post};
    return [for (final id in ids.toSet()) ?byId[id]];
  }

  factory SceneData.demo() => SceneData(
    name: 'animalchaos281',
    handle: 'animalchaos281',
    bio: 'Powered by @Plug AI',
    avatar: 'assets/scene/avatar.jpg',
    following: '0',
    followers: '1,709',
    likes: '46.2K',
    inboxUnread: 71,
    posts: [
      for (final (index, label, views) in const [
        (1, 'Carpet cleaning', '335'),
        (2, 'Keep me guessing forever?', '30,820'),
        (3, 'Papaya', '1,882'),
        (4, 'Into the bowl', '119,589'),
        (5, 'Homemade Triangoli', '43,638'),
        (6, 'On the cutting board', '10,648'),
        (7, 'On the table', '17,328'),
        (8, 'From the kitchen', '35,273'),
        (9, 'Fusilli al telefono', '800,764'),
      ])
        ScenePost(
          id: '$index',
          caption: label,
          cover: 'assets/scene/cover-${index.toString().padLeft(2, '0')}.jpg',
          views: views,
          audio: 'original sound - animalchaos281',
        ),
    ],
    studio: {
      'summaryViews': '1M',
      'summaryFollowers': '1,111',
      'summaryLikes': '42K',
      'summaryViewsDelta': '367',
      'summaryFollowersDelta': '220',
      'summaryLikesDelta': '551',
      'bannerTitle': 'Enter:\n#TikTokThanksgivingContest',
      'bannerText': r'Post to win up to $3,000',
      'bannerImage': 'assets/scene/studio-contest.jpg',
      'promo2Text': 'Create posts with featured sounds and earn rewards.',
    },
    studioPeriods: {
      '0': {
        'date': 'Nov 6 - Nov 12',
        'postViews': '1.2M',
        'profileViews': '38.5K',
        'likes': '41.5K',
        'comments': '1.4K',
        'shares': '6.2K',
        'postViewsDelta': '367.2',
        'profileViewsDelta': '573',
        'likesDelta': '551.3',
        'commentsDelta': '119',
        'sharesDelta': '212.4',
        'postViewsChange': '942.4K',
        'profileViewsChange': '32.8K',
        'likesChange': '35.1K',
        'commentsChange': '744',
        'sharesChange': '4.2K',
        'viewers': '859.2K',
        'newViewers': '841.5K',
        'chartAxis': '525100;350100;175000',
        'chart': '461000;332000;63000;56000;52000;57000;83000',
      },
      '3': {
        'date': 'Nov 13, 2025 - Nov 12, 2026',
        'viewers': '1.3M',
        'newViewers': '1.1M',
        'viewerChartAxis': '426500;284300;142200',
        'viewerChart': '0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;6200;1400;19000;5000;31000;372000;56000;117000',
      },
    },
  );

  factory SceneData.fromJson(Map<String, dynamic> j) => SceneData(
    name: j['name'] ?? '',
    handle: j['handle'] ?? '',
    bio: j['bio'] ?? '',
    avatar: j['avatar'] ?? '',
    followers: j['followers'] ?? '',
    following: j['following'] ?? '',
    likes: j['likes'] ?? '',
    darkMode: j['darkMode'] ?? false,
    inboxUnread: j['inboxUnread'] ?? 15,
    startupMode:
        StartupMode.values.asNameMap()[j['startupMode']] ?? StartupMode.last,
    lastWasViewer: j['lastWasViewer'] as bool?,
    homePostIds: (j['homePostIds'] as List?)?.whereType<String>().toList(),
    inbox: Map<String, String>.from(j['inbox'] ?? {}),
    studio: Map<String, String>.from(j['studio'] ?? {}),
    studioPeriods: (j['studioPeriods'] as Map<String, dynamic>? ?? {}).map(
      (key, value) => MapEntry(key, Map<String, String>.from(value as Map)),
    ),
    posts: ((j['posts'] as List?) ?? [])
        .map((p) => ScenePost.fromJson(Map<String, dynamic>.from(p)))
        .toList(),
  );
  Map<String, dynamic> toJson() => {
    'name': name,
    'handle': handle,
    'bio': bio,
    'avatar': avatar,
    'followers': followers,
    'following': following,
    'likes': likes,
    'darkMode': darkMode,
    'inboxUnread': inboxUnread,
    'startupMode': startupMode.name,
    'lastWasViewer': lastWasViewer,
    'homePostIds': homePostIds,
    'inbox': inbox,
    'studio': studio,
    'studioPeriods': studioPeriods,
    'posts': posts.map((p) => p.toJson()).toList(),
  };
}

class SceneStore {
  static bool get _qa => Platform.environment['SCENE_STUDIO_QA'] == '1';
  static String get key =>
      _qa ? 'scene_studio_data_qa_v1' : 'scene_studio_data_v1';
  static Future<SceneData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return SceneData.demo();
    try {
      return SceneData.fromJson(jsonDecode(raw));
    } catch (_) {
      return SceneData.demo();
    }
  }

  static Future<void> save(SceneData data) async =>
      (await SharedPreferences.getInstance()).setString(
        key,
        jsonEncode(data.toJson()),
      );
  static Future<String?> importFile({required bool video}) async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: video
          ? ['mp4', 'mov', 'm4v']
          : ['jpg', 'jpeg', 'png', 'webp'],
    );
    final src = result?.path;
    if (src == null) return null;
    final dir = Directory(
      '${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}${_qa ? 'SceneStudioMediaQA' : 'SceneStudioMedia'}',
    );
    await dir.create(recursive: true);
    final ext = result!.extension ?? (video ? 'mp4' : 'jpg');
    final dest =
        '${dir.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(src).copy(dest);
    return dest;
  }
}
