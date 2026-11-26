// Which questions a round may hold, given the voice and the sound switch.
import { makeRound, type Q } from './generate';

type Rng = () => number;

/** "Which letter did Chíp say?" needs a voice the child can actually hear. */
export function quizVoiceOn(hasVoice: boolean, soundOn: boolean): boolean {
  return hasVoice && soundOn;
}

/** Swaps the letter questions from [from] onwards for silent ones. */
export function withoutLetters(round: Q[], from: number, rng: Rng): Q[] {
  const silent = makeRound(rng, { voice: false });
  return round.map((q, i) => (i >= from && q.kind === 'letter' ? silent[i] : q));
}
