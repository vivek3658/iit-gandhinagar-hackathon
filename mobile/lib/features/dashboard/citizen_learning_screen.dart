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
  List<LearningChapter> _chapters = [];
  Set<String> _completedVersions = {};
  WasteGameCatalog? _catalog;
  final Map<String, String> _answers = {};
  bool _loading = true;
  bool _submittingGame = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
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
      setState(() {
        _chapters = values[0] as List<LearningChapter>;
        _completedVersions = progress.completedVersions;
        _catalog = catalog;
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
                  const SizedBox(height: 18),
                  Text(
                    chapter.question,
                    style: const TextStyle(
                      color: UrjaTheme.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final option in chapter.options)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        color: selectedAnswer == option.id
                            ? UrjaTheme.mint
                            : Colors.white,
                        child: RadioListTile<String>(
                          value: option.id,
                          groupValue: selectedAnswer,
                          title: Text(option.label),
                          onChanged: (value) =>
                              setSheetState(() => selectedAnswer = value),
                        ),
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
    if (catalog == null || catalog.items.isEmpty) return;
    if (_answers.length != catalog.items.length) {
      _showMessage('Sort every item before submitting your game.');
      return;
    }
    setState(() => _submittingGame = true);
    try {
      final result = await LearningService.instance.playWasteGame(_answers);
      if (!mounted) return;
      final correct = (result['correctCount'] as num?)?.toInt() ?? 0;
      final total =
          (result['itemCount'] as num?)?.toInt() ?? catalog.items.length;
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
      setState(() => _answers.clear());
    } catch (error) {
      if (mounted) _showMessage(error);
    } finally {
      if (mounted) setState(() => _submittingGame = false);
    }
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          _LearningHero(
            icon: Icons.recycling_rounded,
            title: 'Sort it right',
            message:
                'Choose the best bucket for each item using your local guidance. Finish all items to submit for up to ${catalog.rewardCoins} Green Coins.',
          ),
          const SizedBox(height: 14),
          if (catalog.buckets.isEmpty || catalog.items.isEmpty)
            const _LearningEmpty(
              title: 'Sorting game not configured',
              message:
                  'The server has not published buckets or items yet. Try again later.',
            )
          else ...[
            for (final item in catalog.items)
              _WasteItemCard(
                item: item,
                buckets: catalog.buckets,
                selectedBucket: _answers[item.id],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _answers[item.id] = value);
                },
              ),
            const SizedBox(height: 10),
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
                    : 'Submit ${_answers.length}/${catalog.items.length}',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This is a learning game. It does not confirm that waste was collected or calculate environmental impact.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: UrjaTheme.muted,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
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

class _WasteItemCard extends StatelessWidget {
  const _WasteItemCard({
    required this.item,
    required this.buckets,
    required this.selectedBucket,
    required this.onChanged,
  });

  final WasteGameItem item;
  final List<WasteBucket> buckets;
  final String? selectedBucket;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(
              color: UrjaTheme.ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.guidance,
            style: const TextStyle(
              color: UrjaTheme.muted,
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: selectedBucket,
            decoration: const InputDecoration(
              labelText: 'Choose a bucket',
              isDense: true,
            ),
            items: buckets
                .map(
                  (bucket) => DropdownMenuItem(
                    value: bucket.id,
                    child: Text(bucket.label),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    ),
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
