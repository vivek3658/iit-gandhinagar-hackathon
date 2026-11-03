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
        LearningService.instance.getWasteGameCatalog(),
      ]);
      if (!mounted) return;
      final catalog = values[1] as WasteGameCatalog;
      setState(() {
        _chapters = values[0] as List<LearningChapter>;
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
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                    child: ListTile(
                      title: Text(option.label),
                      trailing: const Icon(Icons.arrow_forward_rounded),
                      onTap: () => Navigator.pop(context, option.id),
                    ),
                  ),
                ),
              const SizedBox(height: 5),
              Text(
                'Reward: up to ${chapter.coinReward} Green Coins · once per chapter version',
                style: const TextStyle(
                  color: UrjaTheme.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          const _LearningHero(
            icon: Icons.menu_book_rounded,
            title: 'Learn something useful',
            message:
                'Short lessons from the URJA content service. Rewards are granted once for each chapter version.',
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < _chapters.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ChapterCard(
                chapter: _chapters[index],
                number: index + 1,
                onTap: () => _answerChapter(_chapters[index]),
              ),
            ),
        ],
      ),
    );
  }

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
    required this.onTap,
  });

  final LearningChapter chapter;
  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: UrjaTheme.mint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                number.toString().padLeft(2, '0'),
                style: const TextStyle(
                  color: UrjaTheme.forest,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.title,
                    style: const TextStyle(
                      color: UrjaTheme.ink,
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
            const Icon(Icons.chevron_right_rounded, color: UrjaTheme.muted),
          ],
        ),
      ),
    ),
  );
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
