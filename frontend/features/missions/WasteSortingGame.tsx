'use client';

import { useState } from 'react';
import { useUrja } from '@/contexts/UrjaContext';
import { today } from '@/lib/calculations';
import { Card } from '@/components/ui/Primitives';

type WasteBin = 'ORGANIC' | 'DRY_RECYCLABLE' | 'SPECIAL_HANDLING' | 'RESIDUAL';

const bins: { id: WasteBin; label: string; icon: string }[] = [
  { id: 'ORGANIC', label: 'Wet / organic', icon: '🍌' },
  { id: 'DRY_RECYCLABLE', label: 'Dry recycling', icon: '♻️' },
  { id: 'SPECIAL_HANDLING', label: 'Special care', icon: '🔋' },
  { id: 'RESIDUAL', label: 'Residual waste', icon: '🗑️' },
];

const items: {
  id: string;
  label: string;
  icon: string;
  guidance: string;
  bin: WasteBin;
}[] = [
  {
    id: 'fruit-peel',
    label: 'Fruit peel',
    icon: '🍊',
    guidance: 'Often accepted with organic waste; check local composting rules.',
    bin: 'ORGANIC',
  },
  {
    id: 'clean-bottle',
    label: 'Clean, dry plastic bottle',
    icon: '🧴',
    guidance: 'Keep recyclables clean and dry; locally accepted plastics vary.',
    bin: 'DRY_RECYCLABLE',
  },
  {
    id: 'used-battery',
    label: 'Used household battery',
    icon: '🔋',
    guidance: 'Keep batteries out of wet waste and use an authorized collection point.',
    bin: 'SPECIAL_HANDLING',
  },
  {
    id: 'soiled-tissue',
    label: 'Soiled tissue paper',
    icon: '🧻',
    guidance: 'Usually residual waste; follow your local municipal instructions.',
    bin: 'RESIDUAL',
  },
  {
    id: 'vegetable-scraps',
    label: 'Vegetable scraps',
    icon: '🥬',
    guidance: 'Keep food scraps separate; follow your local wet-waste rules.',
    bin: 'ORGANIC',
  },
  {
    id: 'clean-cardboard',
    label: 'Clean cardboard',
    icon: '📦',
    guidance: 'Flatten it and keep paper or cardboard dry for collection.',
    bin: 'DRY_RECYCLABLE',
  },
  {
    id: 'old-mobile',
    label: 'Old mobile phone',
    icon: '📱',
    guidance: 'Use an authorized e-waste collection or take-back point.',
    bin: 'SPECIAL_HANDLING',
  },
  {
    id: 'snack-wrapper',
    label: 'Multi-layer snack wrapper',
    icon: '🍬',
    guidance: 'Usually not accepted with clean recyclables; check local instructions.',
    bin: 'RESIDUAL',
  },
  {
    id: 'tea-leaves',
    label: 'Used tea leaves',
    icon: '🍵',
    guidance: 'Drain excess liquid before placing tea leaves with organic waste.',
    bin: 'ORGANIC',
  },
  {
    id: 'glass-jar',
    label: 'Empty glass jar',
    icon: '🫙',
    guidance: 'Handle carefully and check your local glass collection rules.',
    bin: 'DRY_RECYCLABLE',
  },
  {
    id: 'cfl-bulb',
    label: 'CFL bulb',
    icon: '💡',
    guidance: 'Do not break it; use an authorized collection point for safe handling.',
    bin: 'SPECIAL_HANDLING',
  },
  {
    id: 'broken-ceramic',
    label: 'Broken ceramic cup',
    icon: '☕',
    guidance: 'Wrap it securely to prevent injury and follow residual-waste guidance.',
    bin: 'RESIDUAL',
  },
  {
    id: 'aluminium-can',
    label: 'Empty drink can',
    icon: '🥫',
    guidance: 'Rinse and dry recyclable metal containers where accepted.',
    bin: 'DRY_RECYCLABLE',
  },
];

type Phase = 'intro' | 'sorting' | 'complete';

function shuffledItems() {
  const shuffled = [...items];
  for (let index = shuffled.length - 1; index > 0; index -= 1) {
    const swapIndex = Math.floor(Math.random() * (index + 1));
    [shuffled[index], shuffled[swapIndex]] = [shuffled[swapIndex], shuffled[index]];
  }
  return shuffled;
}

export default function WasteSortingGame() {
  const { state, setState, notify } = useUrja();
  const [phase, setPhase] = useState<Phase>('intro');
  const [round, setRound] = useState(items);
  const [index, setIndex] = useState(0);
  const [answers, setAnswers] = useState<boolean[]>([]);
  const [choice, setChoice] = useState<WasteBin | null>(null);
  const todayKey = today();
  const rewardKey = `${todayKey}:waste-sort`;
  const playedToday = Boolean(state.missionLogs[rewardKey]);
  const current = round[index];
  const correct = current && choice === current.bin;
  const score = answers.filter(Boolean).length;

  const startRound = () => {
    setRound(shuffledItems());
    setIndex(0);
    setAnswers([]);
    setChoice(null);
    setPhase('sorting');
  };

  const submitAnswer = () => {
    if (!current || !choice) return;

    const wasCorrect = choice === current.bin;
    const nextAnswers = [...answers, wasCorrect];
    setAnswers(nextAnswers);
    setChoice(null);

    if (index + 1 < round.length) {
      setIndex(index + 1);
      return;
    }

    setPhase('complete');
    if (!playedToday) {
      setState((previous) => ({
        ...previous,
        xp: previous.xp + 25,
        missionLogs: {
          ...previous.missionLogs,
          [rewardKey]: { date: todayKey, selfReported: true },
        },
      }));
      notify('Sorting round complete! +25 XP');
    }
  };

  return (
    <section className="waste-game" aria-labelledby="waste-game-title">
      <Card className="waste-game-card">
        <div className="waste-game-heading">
          <div>
            <span className="eyebrow">ONE ROUND · 13 ITEMS</span>
            <h2 id="waste-game-title">Waste-sort challenge</h2>
          </div>
          <span className="waste-game-badge" aria-label="Reward: 25 experience points">
            🌟 25 XP
          </span>
        </div>

        {phase === 'intro' && (
          <div className="waste-game-intro">
            <div className="waste-game-preview" aria-hidden="true">
              <span>🍌</span>
              <span>🧴</span>
              <span>🔋</span>
              <span>📦</span>
              <span>🗑️</span>
            </div>
            <p>
              Sort all 13 items into the best-fit bin. Tap a bin to answer; you can play again
              anytime, and the XP bonus is available once each day.
            </p>
            <p className="note">
              Local waste rules vary. This practice game is not a municipal collection guide.
            </p>
            {playedToday && (
              <p className="waste-game-earned">✅ Today&apos;s XP reward is claimed.</p>
            )}
            <button type="button" className="btn full" onClick={startRound}>
              Start sorting
            </button>
          </div>
        )}

        {phase === 'sorting' && current && (
          <>
            <div
              className="waste-game-progress-row"
              aria-live="polite"
              aria-label={`Item ${index + 1} of ${round.length}`}
            >
              <span>
                Item <strong>{index + 1}</strong> of {round.length}
              </span>
              <span>✅ {score} correct</span>
            </div>
            <div
              className="progress waste-game-progress"
              role="progressbar"
              aria-label="Sorting progress"
              aria-valuemin={0}
              aria-valuemax={round.length}
              aria-valuenow={index}
            >
              <i style={{ width: `${(index / round.length) * 100}%` }} />
            </div>

            <div className="waste-item-card" aria-live="polite">
              <span className="waste-item-icon" aria-hidden="true">
                {current.icon}
              </span>
              <span className="waste-item-label">{current.label}</span>
              <span className="waste-item-prompt">Which bin should this go in?</span>
            </div>

            <div className="waste-bin-list" role="group" aria-label="Choose a waste bin">
              {bins.map((bin) => (
                <button
                  type="button"
                  key={bin.id}
                  className={`waste-bin-button${choice === bin.id ? ' selected' : ''}`}
                  aria-pressed={choice === bin.id}
                  onClick={() => setChoice(bin.id)}
                  disabled={choice !== null}
                >
                  <span aria-hidden="true">{bin.icon}</span>
                  {bin.label}
                </button>
              ))}
            </div>

            {choice && (
              <div
                className={`waste-game-feedback${correct ? ' is-correct' : ' is-incorrect'}`}
                role="status"
              >
                <strong>
                  {correct
                    ? 'Nicely sorted!'
                    : `Not quite — try ${bins.find((bin) => bin.id === current.bin)?.label}.`}
                </strong>
                <span>{current.guidance}</span>
                <button type="button" className="btn full" onClick={submitAnswer}>
                  {index + 1 === round.length ? 'See my results' : 'Next item'}
                </button>
              </div>
            )}
          </>
        )}

        {phase === 'complete' && (
          <div className="waste-game-results" role="status">
            <span className="waste-result-icon" aria-hidden="true">
              {score === round.length ? '🏆' : score >= 9 ? '🌟' : '🌱'}
            </span>
            <h3>
              {score === round.length
                ? 'Perfect sorting!'
                : score >= 9
                  ? 'Great work!'
                  : 'Good practice!'}
            </h3>
            <p className="waste-result-score">
              {score} <span>/ {round.length} correct</span>
            </p>
            <p className="note">
              {playedToday
                ? 'Your daily XP reward was already claimed. You can still practice again.'
                : 'You earned 25 XP for completing today’s round.'}{' '}
              XP is a game reward, not a measure of waste diverted or environmental savings.
            </p>
            <button type="button" className="btn full" onClick={startRound}>
              Play another round
            </button>
          </div>
        )}
      </Card>
    </section>
  );
}
