import 'package:flutter_test/flutter_test.dart';
import 'package:urja/services/learning_service.dart';

void main() {
  test('learning progress tracks completion by chapter version', () {
    final progress = LearningProgress.fromJson({
      'completions': [
        {'chapterId': 'electricity-at-home', 'version': 1},
      ],
    });
    const completed = LearningChapter(
      id: 'electricity-at-home',
      version: 1,
      title: 'Electricity at home',
      summary: 'Read an electricity bill.',
      question: 'Which comparison is useful?',
      options: [],
      coinReward: 10,
    );
    const updatedChapter = LearningChapter(
      id: 'electricity-at-home',
      version: 2,
      title: 'Electricity at home',
      summary: 'Read an electricity bill.',
      question: 'Which comparison is useful?',
      options: [],
      coinReward: 10,
    );

    expect(progress.isCompleted(completed), isTrue);
    expect(progress.isCompleted(updatedChapter), isFalse);
  });

  test('learning progress rejects malformed completions', () {
    expect(
      () => LearningProgress.fromJson({
        'completions': [
          {'chapterId': 'electricity-at-home', 'version': '1'},
        ],
      }),
      throwsFormatException,
    );
  });
}
