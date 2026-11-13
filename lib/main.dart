import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'scene_data.dart';
import 'preview_setup.dart';
import 'simulation.dart';

const accent = Color(0xffe94360);
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SceneApp());
}

class SceneApp extends StatelessWidget {
  const SceneApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'TikTok',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: accent),
      scaffoldBackgroundColor: const Color(0xfff7f7f8),
      fontFamily: 'TikTokSans',
    ),
    home: const StudioRoot(),
  );
}

class StudioRoot extends StatefulWidget {
  const StudioRoot({super.key});
  @override
  State<StudioRoot> createState() => _StudioRootState();
}

class _StudioRootState extends State<StudioRoot> {
  SceneData? data;
  bool showPreview = false;
  @override
  void initState() {
    super.initState();
    SceneStore.load().then((value) {
      if (!mounted) return;
      setState(() {
        data = value;
        showPreview = switch (value.startupMode) {
          StartupMode.viewer => true,
          StartupMode.setup => false,
          StartupMode.last => value.lastWasViewer ?? Platform.isIOS,
        };
        value.lastWasViewer = showPreview;
      });
    });
  }

  void refresh() {
    setState(() {});
    SceneStore.save(data!);
  }

  Future<void> setMode(bool viewer) async {
    final scene = data!;
    if (showPreview == viewer) return;
    scene.lastWasViewer = viewer;
    await SceneStore.save(scene);
    if (mounted) setState(() => showPreview = viewer);
  }

  @override
  Widget build(BuildContext context) {
    final scene = data;
    if (scene == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: PreviewLaunchArtwork(),
        ),
      );
    }
    if (showPreview) {
      return Simulator(
        data: scene,
        startInFeed: true,
        onSetup: () => setMode(false),
      );
    }
    return Scaffold(
      body: Center(
        child: Container(
          width: 460,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x13000000), blurRadius: 20)],
          ),
          child: Material(
            color: Colors.white,
            child: SetupScreen(
              data: scene,
              onChanged: refresh,
              onPreview: () => setMode(true),
            ),
          ),
        ),
      ),
    );
  }
}

class SetupScreen extends StatefulWidget {
  final SceneData data;
  final VoidCallback onChanged;
  final VoidCallback onPreview;
  const SetupScreen({
    super.key,
    required this.data,
    required this.onChanged,
    required this.onPreview,
  });
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late final TextEditingController name,
      handle,
      bio,
      following,
      followers,
      likes;
  @override
  void initState() {
    super.initState();
    final d = widget.data;
    name = TextEditingController(text: d.name);
    handle = TextEditingController(text: d.handle);
    bio = TextEditingController(text: d.bio);
    following = TextEditingController(text: d.following);
    followers = TextEditingController(text: d.followers);
    likes = TextEditingController(text: d.likes);
  }

  void save() {
    final d = widget.data;
    d.name = name.text;
    d.handle = handle.text.replaceFirst(RegExp(r'^@'), '');
    d.bio = bio.text;
    d.following = following.text;
    d.followers = followers.text;
    d.likes = likes.text;
    widget.onChanged();
  }

  @override
  void dispose() {
    for (final c in [name, handle, bio, following, followers, likes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pickAvatar() async {
    try {
      final p = await SceneStore.importFile(video: false);
      if (p != null) {
        setState(() => widget.data.avatar = p);
        save();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossibile importare la foto: $e')),
        );
      }
    }
  }

  Future<void> editPost([ScenePost? post]) async {
    save();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostEditor(
          post: post,
          onSave: (p) {
            if (post == null) widget.data.posts.add(p);
            widget.onChanged();
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void preview() {
    save();
    widget.onPreview();
  }

  Widget field(String label, TextEditingController c, {String? hint}) =>
      TextField(
        controller: c,
        onChanged: (_) => save(),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      );
  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 15),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scene Studio',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.6,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Prepara la tua simulazione',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: preview,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 13,
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Anteprima'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
              children: [
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Anteprima scura',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text('Profilo, menu e analitiche'),
                    value: d.darkMode,
                    onChanged: (v) {
                      setState(() => d.darkMode = v);
                      save();
                    },
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<StartupMode>(
                  initialValue: d.startupMode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Modalità all’avvio',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: StartupMode.last,
                      child: Text('Ultima modalità usata'),
                    ),
                    DropdownMenuItem(
                      value: StartupMode.viewer,
                      child: Text('Sempre Viewer'),
                    ),
                    DropdownMenuItem(
                      value: StartupMode.setup,
                      child: Text('Sempre Setup'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => d.startupMode = value);
                    widget.onChanged();
                  },
                ),
                const SizedBox(height: 6),
                const Text(
                  'Dal Viewer, tieni premuto Profile in basso per tornare qui.',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Profilo',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    InkWell(
                      onTap: pickAvatar,
                      borderRadius: BorderRadius.circular(40),
                      child: Stack(
                        children: [
                          Avatar(path: d.avatar, radius: 30),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Foto profilo\nTocca per importare un’immagine',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                field('Nome visualizzato', name),
                const SizedBox(height: 12),
                field('Nome utente', handle),
                const SizedBox(height: 12),
                field('Bio', bio),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: field('Seguiti', following)),
                    const SizedBox(width: 8),
                    Expanded(child: field('Follower', followers)),
                    const SizedBox(width: 8),
                    Expanded(child: field('Mi piace', likes)),
                  ],
                ),
                const SizedBox(height: 12),
                for (final (icon, label, page) in [
                  (
                    Icons.play_circle_outline,
                    'Sequenza Home',
                    HomeSequenceEditor(data: d, onSave: widget.onChanged),
                  ),
                  (
                    Icons.insights_outlined,
                    'Analitiche e schermate TikTok Studio',
                    PreviewSettingsEditor(
                      data: d,
                      section: PreviewSetupSection.studio,
                      onSave: widget.onChanged,
                    ),
                  ),
                  (
                    Icons.notifications_outlined,
                    'Badge e notifiche Inbox',
                    PreviewSettingsEditor(
                      data: d,
                      section: PreviewSetupSection.inbox,
                      onSave: widget.onChanged,
                    ),
                  ),
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(icon),
                    title: Text(label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context)
                          .push(MaterialPageRoute<void>(builder: (_) => page));
                      if (mounted) setState(() {});
                    },
                  ),
                const SizedBox(height: 27),
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Video della scena',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'File, miniature e numeri simulati',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => editPost(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Aggiungi'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (d.posts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Aggiungi il primo video della scena.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ...d.posts.asMap().entries.map((entry) {
                  final p = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: const Color(0xfff5f5f6),
                      borderRadius: BorderRadius.circular(10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: SizedBox(
                            width: 42,
                            height: 56,
                            child: PostCover(post: p, index: entry.key),
                          ),
                        ),
                        title: Text(
                          p.caption.isEmpty
                              ? 'Video ${entry.key + 1}'
                              : p.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          p.video.isEmpty
                              ? 'Video non ancora importato'
                              : '${p.views} visualizzazioni',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') {
                              editPost(p);
                            } else if (v == 'delete') {
                              setState(() => d.posts.remove(p));
                              widget.onChanged();
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Modifica'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Rimuovi dalla scena'),
                            ),
                          ],
                        ),
                        onTap: () => editPost(p),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Text(
                  'Tutti i contenuti sono simulati e salvati sul dispositivo.',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostEditor extends StatefulWidget {
  final ScenePost? post;
  final void Function(ScenePost) onSave;
  const PostEditor({super.key, this.post, required this.onSave});
  @override
  State<PostEditor> createState() => _PostEditorState();
}

class _PostEditorState extends State<PostEditor> {
  late ScenePost post;
  late final TextEditingController caption,
      audio,
      views,
      likes,
      comments,
      saves,
      shares,
      endViews,
      growthPercent,
      scheduledLabel,
      seconds;
  @override
  void initState() {
    super.initState();
    post = widget.post == null
        ? ScenePost(id: DateTime.now().microsecondsSinceEpoch.toString())
        : ScenePost.fromJson(widget.post!.toJson());
    caption = TextEditingController(text: post.caption);
    audio = TextEditingController(text: post.audio);
    views = TextEditingController(text: post.views);
    likes = TextEditingController(text: post.likes);
    comments = TextEditingController(text: post.comments);
    saves = TextEditingController(text: post.saves);
    shares = TextEditingController(text: post.shares);
    endViews = TextEditingController(
      text: post.endViews == 0 ? '' : post.endViews.toString(),
    );
    growthPercent = TextEditingController(
      text: post.growthPercent == 0 ? '' : post.growthPercent.toString(),
    );
    scheduledLabel = TextEditingController(text: post.scheduledLabel);
    seconds = TextEditingController(text: post.seconds.toString());
  }

  @override
  void dispose() {
    for (final c in [
      caption,
      audio,
      views,
      likes,
      comments,
      saves,
      shares,
      endViews,
      growthPercent,
      scheduledLabel,
      seconds,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pick(bool video) async {
    try {
      final p = await SceneStore.importFile(video: video);
      if (p != null) setState(() => video ? post.video = p : post.cover = p);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Importazione non riuscita: $e')),
        );
      }
    }
  }

  void save() {
    post.caption = caption.text;
    post.audio = audio.text;
    post.views = views.text;
    post.likes = likes.text;
    post.comments = comments.text;
    post.saves = saves.text;
    post.shares = shares.text;
    post.endViews = int.tryParse(endViews.text) ?? 0;
    final growth = double.tryParse(growthPercent.text.replaceAll(',', '.'));
    post.growthPercent = growth != null && growth.isFinite
        ? growth.clamp(0, 1000).toDouble()
        : 0;
    post.scheduledLabel = scheduledLabel.text.trim();
    post.seconds = (int.tryParse(seconds.text) ?? 8).clamp(1, 3600);
    if (widget.post != null) {
      final target = widget.post!;
      target.caption = post.caption;
      target.audio = post.audio;
      target.views = post.views;
      target.likes = post.likes;
      target.comments = post.comments;
      target.saves = post.saves;
      target.shares = post.shares;
      target.video = post.video;
      target.cover = post.cover;
      target.endViews = post.endViews;
      target.growthPercent = post.growthPercent;
      target.scheduledLabel = post.scheduledLabel;
      target.seconds = post.seconds;
      target.analytics = Map.of(post.analytics);
      target.sampleComments = post.sampleComments;
    }
    widget.onSave(post);
    Navigator.pop(context);
  }

  Widget f(String label, TextEditingController c, {bool numeric = false}) =>
      TextField(
        controller: c,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        inputFormatters: numeric
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: Text(
        widget.post == null ? 'Nuovo video' : 'Modifica video',
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      actions: [
        TextButton(
          onPressed: save,
          child: const Text(
            'Salva',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => pick(true),
                icon: const Icon(Icons.video_library_outlined),
                label: Text(
                  post.video.isEmpty ? 'Importa video' : 'Video selezionato',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => pick(false),
                icon: const Icon(Icons.image_outlined),
                label: Text(
                  post.cover.isEmpty ? 'Miniatura' : 'Miniatura scelta',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'MP4 o MOV dal dispositivo. La miniatura è facoltativa.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 20),
        f('Descrizione', caption),
        const SizedBox(height: 12),
        f('Audio visualizzato', audio),
        const SizedBox(height: 20),
        const Text(
          'Numeri visualizzati',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: f('Visualizzazioni', views)),
            const SizedBox(width: 8),
            Expanded(child: f('Mi piace', likes)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: f('Commenti', comments)),
            const SizedBox(width: 8),
            Expanded(child: f('Salvataggi', saves)),
            const SizedBox(width: 8),
            Expanded(child: f('Condivisioni', shares)),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          'Animazione visualizzazioni',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        const Text(
          'La griglia aggiorna le visualizzazioni dopo il caricamento del profilo.',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: f('Valore finale', endViews, numeric: true)),
            const SizedBox(width: 8),
            Expanded(child: f('Durata in secondi', seconds, numeric: true)),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Il valore finale ha precedenza sulla percentuale. Sono ammessi contatori con K e M.',
          style: TextStyle(fontSize: 12, color: Colors.black45),
        ),
        const SizedBox(height: 12),
        f('Incremento visualizzazioni (%)', growthPercent),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Incremento ben visibile'),
          subtitle: const Text(
            'Mostra le cifre durante l’aumento, anche quando il valore è abbreviato.',
          ),
          value: post.exactViewGrowth,
          onChanged: (value) => setState(() => post.exactViewGrowth = value),
        ),
        const SizedBox(height: 12),
        f('Data per riquadro programmato (facoltativa)', scheduledLabel),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AnalyticsEditor(post: post)),
          ),
          icon: const Icon(Icons.insights_outlined),
          label: const Text('Personalizza analitiche e commenti'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: save,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
          child: const Text('Salva video'),
        ),
      ],
    ),
  );
}

class Avatar extends StatelessWidget {
  final String path;
  final double radius;
  const Avatar({super.key, required this.path, this.radius = 26});
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: const Color(0xffe8e8e8),
    backgroundImage: path.isNotEmpty && File(path).existsSync()
        ? FileImage(File(path))
        : null,
    child: path.isEmpty
        ? Icon(Icons.person, color: Colors.grey.shade500, size: radius)
        : null,
  );
}

class PostCover extends StatelessWidget {
  final ScenePost post;
  final int index;
  const PostCover({super.key, required this.post, required this.index});
  @override
  Widget build(BuildContext context) {
    if (post.cover.isNotEmpty && File(post.cover).existsSync()) {
      return Image.file(File(post.cover), fit: BoxFit.cover);
    }
    final colors = [
      const Color(0xff43555a),
      const Color(0xffa28d7b),
      const Color(0xff7e5f62),
      const Color(0xff717569),
      const Color(0xff6b697a),
    ];
    return Container(
      color: colors[index % colors.length],
      child: Center(
        child: Icon(
          post.video.isEmpty
              ? Icons.add_photo_alternate_outlined
              : Icons.play_circle_outline,
          color: Colors.white38,
          size: 30,
        ),
      ),
    );
  }
}
