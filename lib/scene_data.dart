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
  int endViews, seconds;
  double growthPercent;
  bool exactViewGrowth;
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
    this.endViews = 0,
    this.seconds = 8,
    this.growthPercent = 0,
    this.exactViewGrowth = true,
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
    endViews: j['endViews'] ?? 0,
    seconds: j['seconds'] ?? 8,
    growthPercent: (j['growthPercent'] as num?)?.toDouble() ?? 0,
    exactViewGrowth: j['exactViewGrowth'] as bool? ?? true,
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
    'endViews': endViews,
    'seconds': seconds,
    'growthPercent': growthPercent,
    'exactViewGrowth': exactViewGrowth,
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
    posts: [
      ScenePost(
        id: '1',
        caption: 'Un nuovo punto di vista.',
        likes: '2.4K',
        views: '18.2K',
        growthPercent: 1.1,
        seconds: 1,
        audio: 'suono originale - il.tuo.brand',
      ),
      ScenePost(
        id: '2',
        caption: 'La tua prossima campagna.',
        likes: '854',
        views: '9.6K',
        growthPercent: .7,
        seconds: 1,
        audio: 'suono originale - il.tuo.brand',
      ),
      ScenePost(
        id: '3',
        caption: 'Racconta la tua storia.',
        likes: '1.8K',
        views: '14.1K',
        growthPercent: 1.3,
        seconds: 1,
        audio: 'suono originale - il.tuo.brand',
      ),
    ],
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
