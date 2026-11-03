import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/citizen_api.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  List<Map<String, dynamic>> _chapters = [];
  Map<String, dynamic>? _wasteCatalog;
  final Map<String, String> _answers = {};
  String? _error;
  bool _loading = true;
  bool _submittingGame = false;
  String? _completedChapter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final chaptersFuture = CitizenApi.instance.getLearningChapters();
      final catalogFuture = CitizenApi.instance.getWasteGameCatalog();
      final chapters = await chaptersFuture;
      final catalog = await catalogFuture;
      if (!mounted) return;
      final items = catalog['items'];
      if (items is! List) {
        throw const FormatException('Sorting game catalog is unavailable.');
      }
      setState(() {
        _chapters = chapters;
        _wasteCatalog = catalog;
        _answers.clear();
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _answerChapter(Map<String, dynamic> chapter) async {
    final options = chapter['options'];
    final id = chapter['id'];
    final version = chapter['version'];
    if (id is! String || version is! num || options is! List) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
          children: [
            Text(
              chapter['question'] as String? ??
                  chapter['title'] as String? ??
                  'Quick check',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 9),
            for (final option in options.whereType<Map>())
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option['label'] as String? ?? ''),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, option['id'] as String?),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    try {
      final result = await CitizenApi.instance.completeChapter(
        id: id,
        version: version.toInt(),
        answerId: choice,
      );
      if (!mounted) return;
      setState(() => _completedChapter = id);
      final reward = result['coinsAwarded'];
      _toast(
        reward is num
            ? '${result['message'] ?? 'Chapter complete'} · +${reward.toInt()} Green Coins'
            : result['message'] as String? ?? 'Chapter complete',
      );
    } catch (error) {
      if (mounted) _toast(error.toString());
    }
  }

  Future<void> _submitGame() async {
    final items = _wasteCatalog?['items'];
    if (items is! List || items.isEmpty) return;
    if (items.any(
      (item) =>
          item is Map &&
          (item['id'] is! String ||
              !_answers.containsKey(item['id'] as String)),
    )) {
      _toast('Sort every item before submitting.');
      return;
    }
    setState(() => _submittingGame = true);
    try {
      final answers = items.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return <String, String>{
          'itemId': map['id'] as String,
          'bucket': _answers[map['id']]!,
        };
      }).toList();
      final result = await CitizenApi.instance.playWasteGame(
        idempotencyKey: DateTime.now().microsecondsSinceEpoch.toString(),
        answers: answers,
      );
      if (!mounted) return;
      _toast(
        '${result['message'] ?? 'Game submitted'} · ${result['correctCount']}/${result['itemCount']} correct · +${result['coinsAwarded'] ?? 0} coins',
      );
      setState(() => _answers.clear());
    } catch (error) {
      if (mounted) _toast(error.toString());
    } finally {
      if (mounted) setState(() => _submittingGame = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final items = _wasteCatalog?['items'] is List
        ? (_wasteCatalog!['items'] as List).whereType<Map>().toList()
        : const <Map>[];
    final buckets = _wasteCatalog?['buckets'] is List
        ? (_wasteCatalog!['buckets'] as List).whereType<Map>().toList()
        : const <Map>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn & play'),
        backgroundColor: UrjaColors.canvas,
      ),
      body: _loading && _chapters.isEmpty && _wasteCatalog == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                children: [
                  if (_error != null) ...[
                    _ErrorPanel(message: _error!, onRetry: _load),
                    const SizedBox(height: 14),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: UrjaColors.peach,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Text('📚', style: TextStyle(fontSize: 27)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Learn something useful. Play for Green Coins. No game score is counted as environmental impact.',
                            style: TextStyle(height: 1.4, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 21),
                  const Text(
                    'Short chapters',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 9),
                  if (_chapters.isEmpty)
                    const _EmptyLearnCard(
                      message: 'No chapters are available right now.',
                    )
                  else
                    for (final chapter in _chapters)
                      Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: UrjaColors.mint,
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: UrjaColors.forest,
                            ),
                          ),
                          title: Text(
                            chapter['title'] as String? ??
                                'Mission LiFE chapter',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            chapter['summary'] as String? ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: _completedChapter == chapter['id']
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: UrjaColors.leaf,
                                )
                              : const Icon(Icons.arrow_forward_rounded),
                          onTap: () => _answerChapter(chapter),
                        ),
                      ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Waste sorting sprint',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${_wasteCatalog?['rewardCoins'] ?? 0} 🪙',
                        style: const TextStyle(
                          color: UrjaColors.forest,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'One reward per UTC day. Sorting practice does not mean waste was collected.',
                    style: TextStyle(
                      color: UrjaColors.muted,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    const _EmptyLearnCard(
                      message:
                          'Sorting game items are not available right now.',
                    )
                  else
                    for (final item in items)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(13, 11, 13, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['label'] as String? ?? 'Item',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (item['guidance'] is String)
                                Text(
                                  item['guidance'] as String,
                                  style: const TextStyle(
                                    color: UrjaColors.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              DropdownButtonFormField<String>(
                                initialValue: _answers[item['id']],
                                decoration: const InputDecoration(
                                  labelText: 'Choose a bin',
                                  filled: false,
                                  border: InputBorder.none,
                                ),
                                items: buckets
                                    .map(
                                      (bucket) => DropdownMenuItem(
                                        value: bucket['id'] as String?,
                                        child: Text(
                                          bucket['label'] as String? ??
                                              bucket['id'] as String? ??
                                              '',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  final id = item['id'];
                                  if (id is String && value != null) {
                                    setState(() => _answers[id] = value);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    FilledButton(
                      onPressed: _submittingGame ? null : _submitGame,
                      child: _submittingGame
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text('Check my sorting'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(message),
      trailing: IconButton(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ),
  );
}

class _EmptyLearnCard extends StatelessWidget {
  const _EmptyLearnCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(17),
      child: Text(message, style: const TextStyle(color: UrjaColors.muted)),
    ),
  );
}
