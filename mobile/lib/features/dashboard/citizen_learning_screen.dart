import 'package:flutter/material.dart';

import '../../constants/urja_theme.dart';
import '../../services/auth_service.dart';
import '../../services/learning_service.dart';

class CitizenLearningScreen extends StatefulWidget {
  const CitizenLearningScreen({super.key});

  @override
  State<CitizenLearningScreen> createState() => _CitizenLearningScreenState();
}

class _CitizenLearningScreenState extends State<CitizenLearningScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final ScrollController _wasteGameScrollController = ScrollController(
    keepScrollOffset: false,
  );
  List<LearningChapter> _chapters = [];
  Set<String> _completedVersions = {};
  WasteGameCatalog? _catalog;
  final Map<String, String> _answers = {};
  List<WasteGameItem> _roundItems = [];
  bool _loading = true;
  bool _submittingGame = false;
  int _roundIndex = 0;
  String? _selectedWasteBucketId;
  String? _lastSortedItemLabel;
  String? _lastSortedBucketLabel;
  String? _lastSortedGuidance;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);
    _load();
  }

  void _onTabChanged() {
    if (_tabs.index != 1 || _tabs.indexIsChanging) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _wasteGameScrollController.hasClients) {
        _wasteGameScrollController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _wasteGameScrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait([
        LearningService.instance.getChapters(),
        LearningService.instance.getProgress(),
        LearningService.instance.getWasteGameCatalog(),
      ]);
      if (!mounted) return;
      final progress = values[1] as LearningProgress;
      final catalog = values[2] as WasteGameCatalog;
      final roundItems = catalog.items.take(15).toList();
      final roundChanged =
          roundItems.length != _roundItems.length ||
          roundItems.any(
            (item) => !_roundItems.any((current) => current.id == item.id),
          );
      if (roundChanged) roundItems.shuffle();
      setState(() {
        _chapters = values[0] as List<LearningChapter>;
        _completedVersions = progress.completedVersions;
        _catalog = catalog;
        if (roundChanged) {
          _roundItems = roundItems;
          _answers.clear();
          _roundIndex = 0;
          _selectedWasteBucketId = null;
          _lastSortedItemLabel = null;
          _lastSortedBucketLabel = null;
          _lastSortedGuidance = null;
        }
        _answers.removeWhere(
          (itemId, bucketId) =>
              !catalog.items.any((item) => item.id == itemId) ||
              !catalog.buckets.any((bucket) => bucket.id == bucketId),
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _answerChapter(LearningChapter chapter) async {
    final answerId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        String? selectedAnswer;
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: const TextStyle(
                      color: UrjaTheme.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    chapter.summary,
                    style: const TextStyle(
                      color: UrjaTheme.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (chapter.content.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.28,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final paragraph in chapter.content)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  paragraph,
                                  style: const TextStyle(
                                    color: UrjaTheme.ink,
                                    fontSize: 13,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    chapter.question,
                    style: const TextStyle(
                      color: UrjaTheme.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RadioGroup<String>(
                    groupValue: selectedAnswer,
                    onChanged: (value) =>
                        setSheetState(() => selectedAnswer = value),
                    child: Column(
                      children: [
                        for (final option in chapter.options)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              color: selectedAnswer == option.id
                                  ? UrjaTheme.mint
                                  : Colors.white,
                              child: RadioListTile<String>(
                                value: option.id,
                                title: Text(option.label),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Reward: ${chapter.coinReward} Green Coins · awarded once per chapter version',
                    style: const TextStyle(
                      color: UrjaTheme.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selectedAnswer == null
                          ? null
                          : () => Navigator.pop(context, selectedAnswer),
                      child: const Text('Check answer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (answerId == null) return;
    try {
      final result = await LearningService.instance.completeChapter(
        chapter,
        answerId,
      );
      if (!mounted) return;
      final awarded = (result['coinsAwarded'] as num?)?.toInt() ?? 0;
      final alreadyCompleted = result['alreadyCompleted'] == true;
      String balanceNote = '';
      try {
        await AuthService.instance.refreshProfile();
      } catch (error) {
        balanceNote =
            ' Balance refresh failed: ${error.toString().replaceFirst('Exception: ', '')}';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            alreadyCompleted
                ? 'This chapter version was already completed.$balanceNote'
                : 'Chapter complete · +$awarded Green Coins.$balanceNote',
          ),
        ),
      );
      setState(
        () => _completedVersions.add('${chapter.id}:${chapter.version}'),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(error);
    }
  }

  Future<void> _submitGame() async {
    final catalog = _catalog;
    if (catalog == null || _roundItems.isEmpty) return;
    if (_answers.length != _roundItems.length) {
      _showMessage('Sort every item before submitting your game.');
      return;
    }
    setState(() => _submittingGame = true);
    try {
      final result = await LearningService.instance.playWasteGame(_answers);
      if (!mounted) return;
      final correct = (result['correctCount'] as num?)?.toInt() ?? 0;
      final total =
          (result['itemCount'] as num?)?.toInt() ?? _roundItems.length;
      final coins = (result['coinsAwarded'] as num?)?.toInt() ?? 0;
      final alreadyPlayed = result['alreadyPlayedToday'] == true;
      String balanceNote = '';
      try {
        await AuthService.instance.refreshProfile();
      } catch (error) {
        balanceNote =
            ' Balance refresh failed: ${error.toString().replaceFirst('Exception: ', '')}';
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(
            alreadyPlayed ? Icons.replay_rounded : Icons.celebration_rounded,
            color: UrjaTheme.leaf,
          ),
          title: Text(alreadyPlayed ? 'Practice complete' : 'Nice sorting!'),
          content: Text(
            '$correct of $total items matched the server’s guidance. '
            '${alreadyPlayed ? 'Today’s reward was already claimed.' : '+$coins Green Coins awarded.'} '
            'This game does not record real waste collection or CO₂ impact.$balanceNote',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      final nextRound = catalog.items.take(15).toList()..shuffle();
      setState(() {
        _roundItems = nextRound;
        _answers.clear();
        _roundIndex = 0;
        _selectedWasteBucketId = null;
        _lastSortedItemLabel = null;
        _lastSortedBucketLabel = null;
        _lastSortedGuidance = null;
      });
    } catch (error) {
      if (mounted) _showMessage(error);
    } finally {
      if (mounted) setState(() => _submittingGame = false);
    }
  }

  void _sortWasteItem(WasteGameItem item, String bucketId) {
    if (_answers.containsKey(item.id)) return;
    final bucket = _catalog?.buckets
        .where((candidate) => candidate.id == bucketId)
        .toList();
    if (bucket == null || bucket.isEmpty) return;
    setState(() {
      _answers[item.id] = bucketId;
      _roundIndex += 1;
      _selectedWasteBucketId = null;
      _lastSortedItemLabel = item.label;
      _lastSortedBucketLabel = bucket.first.label;
      _lastSortedGuidance = item.guidance;
    });
  }

  void _showMessage(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: UrjaTheme.canvas,
    appBar: AppBar(
      title: const Text('Learn & play'),
      bottom: TabBar(
        controller: _tabs,
        labelColor: UrjaTheme.forest,
        unselectedLabelColor: UrjaTheme.muted,
        indicatorColor: UrjaTheme.leaf,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        tabs: const [
          Tab(text: 'Green lessons'),
          Tab(text: 'Waste sorting'),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: _error != null && _chapters.isEmpty && _catalog == null
        ? _LearningError(message: _error!, onRetry: _load)
        : TabBarView(
            controller: _tabs,
            children: [_buildChapters(), _buildWasteGame()],
          ),
  );

  Widget _buildChapters() {
    if (_loading && _chapters.isEmpty) {
      return const _LearningLoading();
    }
    if (_chapters.isEmpty) {
      return const _LearningEmpty(
        title: 'No lessons available yet',
        message:
            'Learning content will appear when it is published by the server.',
      );
    }
    final completedCount = _chapters
        .where((chapter) => _isChapterCompleted(chapter))
        .length;
    final currentIndex = _chapters.indexWhere(
      (chapter) => !_isChapterCompleted(chapter),
    );
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
        children: [
          const _LearningHero(
            icon: Icons.menu_book_rounded,
            title: 'Your learning trail',
            message:
                'Follow each short chapter, answer its quiz, and earn Green Coins as you go.',
          ),
          const SizedBox(height: 14),
          _ChapterProgressCard(
            completed: completedCount,
            total: _chapters.length,
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < _chapters.length; index++) ...[
            Align(
              alignment: index.isEven
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.88,
                child: _ChapterCard(
                  chapter: _chapters[index],
                  number: index + 1,
                  isCompleted: _isChapterCompleted(_chapters[index]),
                  isCurrent: currentIndex == index,
                  isLocked: currentIndex >= 0 && index > currentIndex,
                  onTap: () {
                    if (currentIndex >= 0 && index > currentIndex) {
                      _showMessage(
                        'Complete the previous chapter to unlock this one.',
                      );
                      return;
                    }
                    _answerChapter(_chapters[index]);
                  },
                ),
              ),
            ),
            if (index < _chapters.length - 1)
              Align(
                alignment: index.isEven
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index.isEven ? 28 : 0,
                    left: index.isEven ? 0 : 28,
                    top: 3,
                    bottom: 3,
                  ),
                  child: Icon(
                    Icons.south_rounded,
                    size: 25,
                    color: UrjaTheme.leaf.withValues(alpha: 0.55),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 8),
          const Text(
            'Chapter rewards are credited once per published chapter version.',
            textAlign: TextAlign.center,
            style: TextStyle(color: UrjaTheme.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  bool _isChapterCompleted(LearningChapter chapter) =>
      _completedVersions.contains('${chapter.id}:${chapter.version}');

  Widget _buildWasteGame() {
    final catalog = _catalog;
    if (_loading && catalog == null) return const _LearningLoading();
    if (catalog == null) {
      return _LearningError(
        message: _error ?? 'Waste sorting is unavailable right now.',
        onRetry: _load,
      );
    }
    if (catalog.buckets.isEmpty || catalog.items.length < 10) {
      return const _LearningEmpty(
        title: 'Sorting round not ready',
        message:
            'A sorting round needs at least 10 waste items and published bins. Try again later.',
      );
    }

    final total = _roundItems.length;
    final isComplete = total > 0 && _answers.length == total;
    final currentItem = isComplete || _roundIndex >= total
        ? null
        : _roundItems[_roundIndex];
    final selectedBuckets = catalog.buckets
        .where((bucket) => bucket.id == _selectedWasteBucketId)
        .toList();
    final selectedBucket = selectedBuckets.isEmpty
        ? null
        : selectedBuckets.first;

    return ListView(
      key: const PageStorageKey<String>('waste-sorting-round'),
      controller: _wasteGameScrollController,
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        _WasteRoundProgress(
          completed: _answers.length,
          total: total,
          onRestart: _submittingGame
              ? null
              : () => setState(() {
                  _roundItems = List.of(catalog.items.take(15))..shuffle();
                  _answers.clear();
                  _roundIndex = 0;
                  _selectedWasteBucketId = null;
                  _lastSortedItemLabel = null;
                  _lastSortedBucketLabel = null;
                  _lastSortedGuidance = null;
                }),
        ),
        if (currentItem != null) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 142,
            child: _WasteDraggableItem(
              item: currentItem,
              selected: true,
              onTap: () {},
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ITEM ${_roundIndex + 1} OF $total',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: UrjaTheme.muted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(2, 16, 2, 8),
            child: Text(
              'CHOOSE A BIN',
              style: TextStyle(
                color: UrjaTheme.forest,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          for (final bucket in catalog.buckets) ...[
            _WasteBucketTarget(
              bucket: bucket,
              itemCount: _answers.values
                  .where((answer) => answer == bucket.id)
                  .length,
              selected: bucket.id == _selectedWasteBucketId,
              onTap: () => setState(() {
                _selectedWasteBucketId = bucket.id;
              }),
              onAccept: (item) => _sortWasteItem(item, bucket.id),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            onPressed: _submittingGame || selectedBucket == null
                ? null
                : () {
                    _sortWasteItem(currentItem, selectedBucket.id);
                  },
            icon: const Icon(Icons.add_task_rounded),
            label: Text(
              _roundIndex + 1 == total ? 'Sort final item' : 'Sort this item',
            ),
          ),
        ] else ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: UrjaTheme.mint,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: UrjaTheme.line),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.celebration_rounded,
                  color: UrjaTheme.forest,
                  size: 38,
                ),
                SizedBox(height: 8),
                Text(
                  'All items sorted!',
                  style: TextStyle(
                    color: UrjaTheme.forest,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Check your answers to finish the round.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: UrjaTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _submittingGame ? null : _submitGame,
            icon: _submittingGame
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(
              _submittingGame
                  ? 'Checking your sort…'
                  : 'Check my sort · ${catalog.rewardCoins} coins',
            ),
          ),
        ],
        if (_lastSortedItemLabel != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: UrjaTheme.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sorted $_lastSortedItemLabel → $_lastSortedBucketLabel',
                  style: const TextStyle(
                    color: UrjaTheme.forest,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (_lastSortedGuidance != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    _lastSortedGuidance!,
                    style: const TextStyle(
                      color: UrjaTheme.muted,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Waste rules differ by location. Follow your local collection guidance. '
          'Game rewards are not a measure of waste collected or emissions saved.',
          textAlign: TextAlign.center,
          style: TextStyle(color: UrjaTheme.muted, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }
}

class _LearningHero extends StatelessWidget {
  const _LearningHero({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [UrjaTheme.forest, Color(0xFF28744C)],
      ),
      borderRadius: BorderRadius.circular(23),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFB8E4C3), size: 25),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                message,
                style: const TextStyle(
                  color: Color(0xFFDCEFE1),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
    required this.number,
    required this.isCompleted,
    required this.isCurrent,
    required this.isLocked,
    required this.onTap,
  });

  final LearningChapter chapter;
  final int number;
  final bool isCompleted;
  final bool isCurrent;
  final bool isLocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stateColor = isLocked ? UrjaTheme.muted : UrjaTheme.forest;
    final stateLabel = isCompleted
        ? 'COMPLETED'
        : isLocked
        ? 'LOCKED'
        : isCurrent
        ? 'YOUR NEXT CHAPTER'
        : 'REPLAY CHAPTER';
    return Card(
      color: isCurrent ? const Color(0xFFF0F9F1) : Colors.white,
      elevation: isCurrent ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isCurrent ? UrjaTheme.leaf : UrjaTheme.line,
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? UrjaTheme.leaf
                      : isLocked
                      ? const Color(0xFFF0F1F2)
                      : UrjaTheme.mint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_rounded
                      : isLocked
                      ? Icons.lock_rounded
                      : Icons.eco_rounded,
                  color: isCompleted ? Colors.white : stateColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHAPTER $number · $stateLabel',
                      style: TextStyle(
                        color: stateColor,
                        fontSize: 9,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chapter.title,
                      style: TextStyle(
                        color: isLocked ? UrjaTheme.muted : UrjaTheme.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chapter.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: UrjaTheme.muted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '+${chapter.coinReward} Green Coins',
                      style: const TextStyle(
                        color: UrjaTheme.leaf,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isCompleted
                    ? Icons.replay_rounded
                    : isLocked
                    ? Icons.lock_outline_rounded
                    : Icons.arrow_forward_rounded,
                color: stateColor,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterProgressCard extends StatelessWidget {
  const _ChapterProgressCard({required this.completed, required this.total});

  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: UrjaTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.route_rounded,
                color: UrjaTheme.forest,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$completed of $total chapters complete',
                  style: const TextStyle(
                    color: UrjaTheme.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: UrjaTheme.forest,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: UrjaTheme.mint,
              valueColor: const AlwaysStoppedAnimation<Color>(UrjaTheme.leaf),
            ),
          ),
        ],
      ),
    );
  }
}

class _WasteRoundProgress extends StatelessWidget {
  const _WasteRoundProgress({
    required this.completed,
    required this.total,
    required this.onRestart,
  });

  final int completed;
  final int total;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: UrjaTheme.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.recycling_rounded, color: UrjaTheme.forest),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waste-sort challenge · $total items',
                      style: const TextStyle(
                        color: UrjaTheme.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$completed of $total sorted · one item at a time',
                      style: const TextStyle(
                        color: UrjaTheme.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRestart != null)
                IconButton(
                  tooltip: 'Restart round',
                  onPressed: onRestart,
                  icon: const Icon(Icons.restart_alt_rounded),
                ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: UrjaTheme.forest,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: UrjaTheme.mint,
              valueColor: const AlwaysStoppedAnimation(UrjaTheme.leaf),
            ),
          ),
        ],
      ),
    );
  }
}

class _WasteDraggableItem extends StatelessWidget {
  const _WasteDraggableItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final WasteGameItem item;
  final bool selected;
  final VoidCallback onTap;

  String get emoji {
    return switch (item.id) {
      'fruit-peel' => '🍌',
      'vegetable-scraps' => '🥕',
      'tea-leaves' => '🍃',
      'clean-bottle' => '🧴',
      'clean-cardboard' => '📦',
      'glass-jar' => '🫙',
      'aluminium-can' => '🥫',
      'used-battery' => '🔋',
      'old-mobile' => '📱',
      'cfl-bulb' => '💡',
      'soiled-tissue' => '🧻',
      'snack-wrapper' => '🍬',
      'broken-ceramic' => '☕',
      _ => '🗑️',
    };
  }

  Widget card({required bool dragging}) => Tooltip(
    message: item.guidance,
    child: InkWell(
      onTap: dragging ? null : onTap,
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: dragging || selected ? UrjaTheme.mint : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? UrjaTheme.leaf : UrjaTheme.line,
            width: selected ? 2 : 1,
          ),
          boxShadow: dragging
              ? const []
              : const [
                  BoxShadow(
                    color: Color(0x12174B35),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                child: Text(emoji, style: const TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: UrjaTheme.ink,
                fontSize: 10,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Draggable<WasteGameItem>(
    data: item,
    feedback: Material(
      color: Colors.transparent,
      child: SizedBox(
        width: (MediaQuery.sizeOf(context).width - 42) / 3,
        child: card(dragging: true),
      ),
    ),
    childWhenDragging: Opacity(opacity: 0.3, child: card(dragging: false)),
    child: card(dragging: false),
  );
}

class _WasteBucketTarget extends StatelessWidget {
  const _WasteBucketTarget({
    required this.bucket,
    required this.itemCount,
    required this.selected,
    required this.onTap,
    required this.onAccept,
  });

  final WasteBucket bucket;
  final int itemCount;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<WasteGameItem> onAccept;

  IconData get icon => switch (bucket.id) {
    'ORGANIC' => Icons.compost_rounded,
    'DRY_RECYCLABLE' => Icons.recycling_rounded,
    'SPECIAL_HANDLING' => Icons.battery_charging_full_rounded,
    _ => Icons.delete_outline_rounded,
  };

  Color get color => switch (bucket.id) {
    'ORGANIC' => const Color(0xFF2E7D32),
    'DRY_RECYCLABLE' => const Color(0xFF1976D2),
    'SPECIAL_HANDLING' => const Color(0xFF8E44AD),
    _ => const Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) => DragTarget<WasteGameItem>(
    onWillAcceptWithDetails: (_) => true,
    onAcceptWithDetails: (details) => onAccept(details.data),
    builder: (context, candidates, rejected) {
      final isHovering = candidates.isNotEmpty;
      return Semantics(
        button: true,
        label: '${bucket.label}, $itemCount items sorted',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.fromLTRB(7, 5, 7, 4),
            decoration: BoxDecoration(
              color: isHovering || selected
                  ? color.withValues(alpha: 0.12)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovering || selected ? color : UrjaTheme.line,
                width: isHovering || selected ? 2 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x10174B35),
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 70,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Positioned(
                        bottom: 1,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 37,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                color.withValues(alpha: 0.68),
                                color,
                                color.withValues(alpha: 0.78),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(9),
                              top: Radius.circular(4),
                            ),
                            border: Border.all(
                              color: color.withValues(alpha: 0.75),
                            ),
                          ),
                          child: Icon(icon, color: Colors.white, size: 23),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        left: 6,
                        right: 6,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33101820),
                                blurRadius: 3,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 1,
                        child: Container(
                          width: 18,
                          height: 4,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        bucket.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (itemCount > 0) ...[
                      const SizedBox(width: 3),
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        child: Text(
                          '$itemCount',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _LearningLoading extends StatelessWidget {
  const _LearningLoading();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: UrjaTheme.leaf));
}

class _LearningEmpty extends StatelessWidget {
  const _LearningEmpty({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.eco_outlined, color: UrjaTheme.leaf, size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: UrjaTheme.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: UrjaTheme.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    ),
  );
}

class _LearningError extends StatelessWidget {
  const _LearningError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: UrjaTheme.muted, size: 36),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: UrjaTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
