import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long a passed parent gate keeps the parent corner open.
const Duration parentUnlockDuration = Duration(minutes: 10);

/// In-memory expiry of the last passed parent gate; null when never passed.
/// A deep link to `/parent` must show the gate itself unless this is in the
/// future.
final parentUnlockedUntilProvider = StateProvider<DateTime?>((ref) => null);

bool isParentUnlocked(DateTime? until, DateTime now) =>
    until != null && now.isBefore(until);
