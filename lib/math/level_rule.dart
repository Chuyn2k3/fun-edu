/// Level after a practice session: >= 80% first-try correct moves up,
/// <= 40% moves down, otherwise stays. Clamped to 0..levelCount-1.
int nextLevelIndex({
  required int current,
  required int firstTryCorrect,
  required int total,
  required int levelCount,
}) {
  // An empty session carries no evidence, so never move.
  if (total <= 0) return current.clamp(0, levelCount - 1);
  var next = current;
  if (firstTryCorrect * 5 >= total * 4) {
    next = current + 1;
  } else if (firstTryCorrect * 5 <= total * 2) {
    next = current - 1;
  }
  return next.clamp(0, levelCount - 1);
}
