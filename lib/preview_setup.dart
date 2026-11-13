import 'package:flutter/material.dart';

import 'main.dart' show PostCover;
import 'scene_data.dart';

const studioPeriodLabels = ['7 days', '28 days', '60 days', '365 days'];
const studioMetricKeys = <String, String>{
  'postViews': 'Visualizzazioni dei post',
  'profileViews': 'Visite al profilo',
  'likes': 'Mi piace',
  'comments': 'Commenti',
  'shares': 'Condivisioni',
  'rewards': 'Ricompense stimate',
  'viewers': 'Spettatori totali',
  'newViewers': 'Nuovi spettatori',
  'followers': 'Follower totali',
  'netFollowers': 'Follower netti',
  'liveViews': 'Visualizzazioni LIVE',
  'liveFollowers': 'Nuovi follower LIVE',
};

class HomeSequenceEditor extends StatefulWidget {
  final SceneData data;
  final VoidCallback onSave;
  const HomeSequenceEditor({
    super.key,
    required this.data,
    required this.onSave,
  });
  @override
  State<HomeSequenceEditor> createState() => _HomeSequenceEditorState();
}

class _HomeSequenceEditorState extends State<HomeSequenceEditor> {
  late List<ScenePost> sequence = [...widget.data.homePosts];
  late bool useAll = widget.data.homePostIds == null;

  void save() {
    widget.data.homePostIds = useAll
        ? null
        : [for (final post in sequence) post.id];
    widget.onSave();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.data.posts.where(
      (post) => !sequence.contains(post),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Sequenza Home')),
      body: SafeArea(
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Usa tutti i video del profilo'),
              subtitle: const Text(
                'Disattiva per scegliere i primi N video e ordinarli.',
              ),
              value: useAll,
              onChanged: (value) => setState(() {
                useAll = value;
                if (value) sequence = [...widget.data.posts];
              }),
            ),
            if (!useAll)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: Text('${sequence.length} video in Home')),
                    TextButton(
                      onPressed: sequence.isEmpty
                          ? null
                          : () => setState(sequence.clear),
                      child: const Text('Svuota selezione'),
                    ),
                  ],
                ),
              ),
            if (!useAll && available.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<ScenePost>(
                  isExpanded: true,
                  hint: const Text('Aggiungi un video alla Home'),
                  items: [
                    for (final post in available)
                      DropdownMenuItem(
                        value: post,
                        child: Text(
                          _label(post),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (post) {
                    if (post != null) setState(() => sequence.add(post));
                  },
                ),
              ),
            Expanded(
              child: sequence.isEmpty
                  ? const Center(child: Text('Nessun video nella Home'))
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      buildDefaultDragHandles: false,
                      onReorderItem: (oldIndex, newIndex) {
                        if (!useAll) {
                          setState(
                            () => sequence.insert(
                              newIndex,
                              sequence.removeAt(oldIndex),
                            ),
                          );
                        }
                      },
                      itemCount: sequence.length,
                      itemBuilder: (context, index) {
                        final post = sequence[index];
                        return ListTile(
                          key: ValueKey(post.id),
                          leading: SizedBox(
                            width: 31,
                            height: 44,
                            child: PostCover(post: post, index: index),
                          ),
                          title: Text(
                            _label(post),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            post.video.isEmpty
                                ? 'Solo miniatura'
                                : 'Video locale',
                          ),
                          trailing: useAll
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: 'Togli dalla Home',
                                      onPressed: () => setState(
                                        () => sequence.removeAt(index),
                                      ),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: const Icon(Icons.drag_handle),
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: save,
                child: const Text('Salva sequenza'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _label(ScenePost post) => post.caption.isEmpty
      ? 'Video ${widget.data.posts.indexOf(post) + 1}'
      : post.caption;
}

enum PreviewSetupSection { studio, inbox }

class PreviewSettingsEditor extends StatefulWidget {
  final SceneData data;
  final PreviewSetupSection section;
  final VoidCallback onSave;
  const PreviewSettingsEditor({
    super.key,
    required this.data,
    required this.section,
    required this.onSave,
  });

  @override
  State<PreviewSettingsEditor> createState() => _PreviewSettingsEditorState();
}

class _PreviewSettingsEditorState extends State<PreviewSettingsEditor> {
  final fields = <String, TextEditingController>{};
  String period = '0';
  late bool popup = widget.data.inbox['popup'] != 'off';
  bool get studio => widget.section == PreviewSetupSection.studio;

  @override
  void dispose() {
    for (final controller in fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget field(
    String label,
    String id,
    String? initial, {
    String? hint,
    int lines = 1,
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: TextField(
      key: ValueKey(id),
      controller: fields.putIfAbsent(
        id,
        () => TextEditingController(text: initial),
      ),
      minLines: 1,
      maxLines: lines,
      keyboardType: numeric ? TextInputType.number : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    ),
  );

  Widget studioField(
    String label,
    String key, {
    bool byPeriod = false,
    String? hint,
    int lines = 1,
  }) {
    final scope = byPeriod ? period : 'studio';
    final values = byPeriod
        ? widget.data.studioPeriods[period]
        : widget.data.studio;
    return field(label, '$scope/$key', values?[key], hint: hint, lines: lines);
  }

  void save() {
    final data = widget.data;
    for (final MapEntry(key: id, value: input) in fields.entries) {
      final parts = id.split('/');
      final key = parts.last;
      final scope = parts.first;
      if (scope == 'inbox' && key == 'unread') {
        data.inboxUnread = (int.tryParse(input.text.trim()) ?? 0).clamp(
          0,
          99999,
        );
        continue;
      }
      final values = switch (scope) {
        'inbox' => data.inbox,
        'studio' => data.studio,
        _ => data.studioPeriods.putIfAbsent(scope, () => {}),
      };
      final value = input.text.trim();
      if (value.isEmpty) {
        values.remove(key);
      } else {
        values[key] = value;
      }
    }
    if (!studio) data.inbox['popup'] = popup ? 'on' : 'off';
    widget.onSave();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(studio ? 'TikTok Studio' : 'Notifiche Inbox')),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: FilledButton(
        onPressed: save,
        child: const Text('Salva impostazioni'),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      children: studio ? studioFields() : inboxFields(),
    ),
  );

  List<Widget> inboxFields() {
    final data = widget.data;
    return [
      const Text('0 nasconde il badge. Da 100 in su compare 99+.'),
      field(
        'Numero sul badge rosso',
        'inbox/unread',
        data.inboxUnread.toString(),
        numeric: true,
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Fumetto all’avvio'),
        subtitle: const Text(
          'Mostra il riepilogo sopra Inbox quando arrivano le notifiche.',
        ),
        value: popup,
        onChanged: (value) => setState(() => popup = value),
      ),
      for (final (key, label, fallback) in [
        ('replies', 'Commenti nel riepilogo', '4'),
        ('likes', 'Mi piace nel riepilogo', '4'),
        ('follows', 'Follower nel riepilogo', '6'),
      ])
        field(
          label,
          'inbox/$key',
          data.inbox[key],
          hint: fallback,
          numeric: true,
        ),
    ];
  }

  List<Widget> studioFields() => [
    const Text(
      'Lascia vuoto un campo per usare il valore simulato. Ogni intervallo salva i propri valori.',
    ),
    ExpansionTile(
      title: const Text('Schermata iniziale di Studio'),
      children: [
        studioField('Visualizzazioni dei post', 'summaryViews'),
        studioField('Follower netti', 'summaryFollowers'),
        studioField('Mi piace', 'summaryLikes'),
        studioField('Variazione visualizzazioni (%)', 'summaryViewsDelta'),
        studioField('Variazione follower (%)', 'summaryFollowersDelta'),
        studioField('Variazione mi piace (%)', 'summaryLikesDelta'),
        studioField(
          'Titolo del banner',
          'bannerTitle',
          hint: '#DailyLife Post Contest',
          lines: 2,
        ),
        studioField('Testo del banner', 'bannerText'),
        studioField('Prima scheda monetizzazione', 'promo1Title'),
        studioField('Descrizione prima scheda', 'promo1Text'),
        studioField('Seconda scheda monetizzazione', 'promo2Title'),
        studioField('Descrizione seconda scheda', 'promo2Text'),
        studioField('Voci Inspiration (una per riga)', 'topics', lines: 4),
        studioField(
          'Testo della sezione LIVE',
          'liveText',
          hint: 'No LIVE data',
          lines: 2,
        ),
      ],
    ),
    const SizedBox(height: 5),
    DropdownButtonFormField<String>(
      initialValue: period,
      decoration: const InputDecoration(
        labelText: 'Intervallo analitiche',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final (i, label) in studioPeriodLabels.indexed)
          DropdownMenuItem(value: i.toString(), child: Text(label)),
      ],
      onChanged: (value) {
        if (value != null) setState(() => period = value);
      },
    ),
    studioField('Date da mostrare', 'date', byPeriod: true),
    for (final entry in studioMetricKeys.entries)
      studioField(entry.value, entry.key, byPeriod: true),
    ExpansionTile(
      key: const ValueKey('studio-changes'),
      title: const Text('Variazioni e grafico'),
      children: [
        for (final entry in studioMetricKeys.entries)
          studioField(
            'Variazione ${entry.value.toLowerCase()} (%)',
            '${entry.key}Delta',
            byPeriod: true,
          ),
        for (final key in [
          'postViews',
          'profileViews',
          'likes',
          'comments',
          'shares',
        ])
          studioField(
            'Differenza ${studioMetricKeys[key]!.toLowerCase()}',
            '${key}Change',
            byPeriod: true,
          ),
        studioField(
          'Scala Overview (tre valori separati da ;)',
          'chartAxis',
          byPeriod: true,
        ),
        studioField(
          'Scala Viewers (tre valori separati da ;)',
          'viewerChartAxis',
          byPeriod: true,
        ),
        studioField(
          'Grafico Overview (punti separati da ;)',
          'chart',
          byPeriod: true,
          hint: '3200; 5200; 4000; 1700',
        ),
        for (final (label, key) in [
          ('Viewers', 'viewerChart'),
          ('Followers', 'followerChart'),
          ('LIVE', 'liveChart'),
        ])
          studioField(
            'Grafico $label (punti separati da ;)',
            key,
            byPeriod: true,
          ),
        studioField(
          'Sorgenti di traffico (Nome: percentuale)',
          'traffic',
          byPeriod: true,
          lines: 4,
        ),
      ],
    ),
    for (final (prefix, title) in [
      ('viewer', 'Pubblico'),
      ('follower', 'Follower'),
    ])
      ExpansionTile(
        key: ValueKey(prefix),
        title: Text(title),
        children: [
          studioField(
            'Genere (Nome: percentuale)',
            '${prefix}Gender',
            byPeriod: true,
            lines: 4,
          ),
          studioField(
            'Età (Fascia: percentuale)',
            '${prefix}Age',
            byPeriod: true,
            lines: 4,
          ),
          studioField(
            'Località (Paese: percentuale)',
            '${prefix}Locations',
            byPeriod: true,
            lines: 4,
          ),
          studioField(
            'Testo delle ore di attività',
            '${prefix}Active',
            byPeriod: true,
            lines: 3,
          ),
          studioField(
            'Valori per ora (separati da ;)',
            '${prefix}Hours',
            byPeriod: true,
          ),
          studioField(
            'Valori per giorno (separati da ;)',
            '${prefix}Days',
            byPeriod: true,
          ),
        ],
      ),
  ];
}
