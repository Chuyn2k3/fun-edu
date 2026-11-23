import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_client.dart';
import '../auth/session_controller.dart';
import '../net/network_status.dart';
import '../online_config.dart';
import 'friends_api.dart';
import 'lobby_client.dart';

/// Clock used for friend-code expiration checks (tests override).
final friendsClockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Result of a friend management action (`createCode`, `redeemCode`, `removeFriend`).
@immutable
class FriendsActionResult<T> {
  const FriendsActionResult.ok([this.data])
      : errorCode = null,
        errorMessage = null;

  const FriendsActionResult.err({
    required this.errorCode,
    required this.errorMessage,
  }) : data = null;

  final T? data;
  final String? errorCode;
  final String? errorMessage;

  bool get ok => errorMessage == null;
}

/// View state managed by [FriendsController].
@immutable
class FriendsState {
  const FriendsState({
    this.friends = const [],
    this.activeCode,
    this.errorMessage,
    this.offline = false,
  });

  final List<FriendFamily> friends;
  final FriendCode? activeCode;
  final String? errorMessage;
  final bool offline;

  FriendsState copyWith({
    List<FriendFamily>? friends,
    FriendCode? Function()? activeCode,
    String? Function()? errorMessage,
    bool? offline,
  }) =>
      FriendsState(
        friends: friends ?? this.friends,
        activeCode: activeCode == null ? this.activeCode : activeCode(),
        errorMessage: errorMessage == null ? this.errorMessage : errorMessage(),
        offline: offline ?? this.offline,
      );
}

/// Maps a server/network error from friend endpoints to a code and Vietnamese
/// parent-friendly message.
({String code, String message, bool offline}) mapFriendError(
  Object error, {
  required bool networkOffline,
}) {
  if (error is ApiException) {
    final code = error.code;
    if (error.unauthorized || code == 'signed_out') {
      return (
        code: 'signed_out',
        message: 'Ba mẹ cần đăng nhập lại Tài khoản gia đình',
        offline: false,
      );
    }
    if (error.status == 429 || code == 'too_many') {
      return (
        code: 'too_many',
        message: 'Thử nhiều lần quá, đợi một chút rồi thử lại nhé',
        offline: false,
      );
    }
    switch (code) {
      case 'code_invalid':
      case 'bad_request':
        return (
          code: 'invalid_code',
          message: 'Mã không đúng hoặc đã hết hạn',
          offline: false,
        );
      case 'self':
        return (
          code: 'self_code',
          message: 'Đây là mã của chính nhà mình',
          offline: false,
        );
      case 'already_friends':
        return (
          code: 'already_friends',
          message: 'Hai nhà đã là bạn rồi',
          offline: false,
        );
      case 'too_many_friends':
        return (
          code: 'limit_reached',
          message: 'Đã đủ 50 bạn',
          offline: false,
        );
    }
    if (error.status == 400 || error.status == 404) {
      return (
        code: 'invalid_code',
        message: 'Mã không đúng hoặc đã hết hạn',
        offline: false,
      );
    }
    if (error.status == 0) {
      if (networkOffline) {
        return (
          code: 'network',
          message: 'Không có kết nối mạng. Kiểm tra lại Wi-Fi hoặc 4G nhé',
          offline: true,
        );
      }
      return (
        code: 'server_unreachable',
        message: 'Không kết nối được tới máy chủ FunEdu. Thử lại sau nhé',
        offline: false,
      );
    }
  }
  if (networkOffline) {
    return (
      code: 'network',
      message: 'Không có kết nối mạng. Kiểm tra lại Wi-Fi hoặc 4G nhé',
      offline: true,
    );
  }
  return (
    code: 'server_unreachable',
    message: 'Chưa thực hiện được. Ba mẹ kiểm tra mạng rồi thử lại nhé',
    offline: false,
  );
}

/// Manages the family's race-friend list, active invite code, and live lobby
/// presence/friendship updates. Never makes network calls in guest mode.
class FriendsController extends AsyncNotifier<FriendsState> {
  final Map<String, List<FriendFamily>> _cachedByFamily = {};
  FriendCode? _activeCode;
  Timer? _expiryTimer;
  bool _disposed = false;
  int _loadEpoch = 0;

  DateTime Function() get _clock => ref.read(friendsClockProvider);
  bool get _isOffline =>
      ref.read(networkStatusProvider) == NetState.offline;

  bool get _signedInAndEnabled =>
      ref.read(onlineConfigProvider).enabled &&
      ref.read(sessionProvider).valueOrNull != null;

  @override
  Future<FriendsState> build() async {
    _disposed = false;
    final config = ref.watch(onlineConfigProvider);

    ref.onDispose(() {
      _disposed = true;
      _cancelExpiryTimer();
    });

    var resolvingInitialSession = false;
    ref.listen<String?>(
      sessionProvider.select((s) => s.valueOrNull?.familyId),
      (prev, next) {
        if (!_disposed && !resolvingInitialSession && prev != next) {
          ref.invalidateSelf();
        }
      },
    );

    ref.listen<(bool, Set<String>)>(
      lobbyClientProvider.select((s) => (s.connected, s.onlineFriends)),
      (prev, next) {
        if (_disposed) return;
        final current = state.valueOrNull;
        if (current == null) return;
        final (connected, onlineIds) = next;
        if (connected) {
          _updatePresence(onlineIds);
        } else if (prev?.$1 == true && !connected) {
          _updatePresence(const {});
        }
      },
    );

    ref.listen<LobbyFriendEvent?>(
      lobbyClientProvider.select((s) => s.lastFriendEvent),
      (prev, next) {
        if (_disposed || next == null || next.seq == prev?.seq) return;
        if (!next.added) {
          _removeLocally(next.familyId);
        } else {
          unawaited(refresh());
        }
      },
    );

    ref.listen<NetState>(networkStatusProvider, (prev, next) {
      if (_disposed || !_signedInAndEnabled) return;
      if (prev != null && prev != NetState.online && next == NetState.online) {
        if (state.valueOrNull?.errorMessage != null) {
          unawaited(refresh());
        }
      }
    });

    if (!config.enabled) {
      _cancelExpiryTimer();
      _activeCode = null;
      _cachedByFamily.clear();
      return const FriendsState();
    }

    final session = ref.read(sessionProvider);
    final String? familyId;
    if (session.hasValue) {
      familyId = session.valueOrNull?.familyId;
    } else {
      resolvingInitialSession = true;
      familyId = (await ref.read(sessionProvider.future))?.familyId;
      resolvingInitialSession = false;
    }
    if (_disposed) return const FriendsState();

    if (familyId == null) {
      _cancelExpiryTimer();
      _activeCode = null;
      _cachedByFamily.clear();
      return const FriendsState();
    }

    return _fetchList(familyId);
  }

  Future<FriendsState> _fetchList(String familyId) async {
    final epoch = ++_loadEpoch;
    try {
      final raw = await ref.read(friendsApiProvider).listFriends();
      if (_disposed || epoch != _loadEpoch) {
        return state.valueOrNull ?? const FriendsState();
      }
      final merged = _mergeLobbyPresence(raw);
      _cachedByFamily[familyId] = merged;
      return FriendsState(
        friends: merged,
        activeCode: _validActiveCode(),
      );
    } catch (e) {
      if (_disposed) return const FriendsState();
      final mapped = mapFriendError(e, networkOffline: _isOffline);
      final cached = _cachedByFamily[familyId] ?? const <FriendFamily>[];
      return FriendsState(
        friends: cached,
        activeCode: _validActiveCode(),
        errorMessage: mapped.message,
        offline: mapped.offline,
      );
    }
  }

  /// Reloads the friend list from the server (no-op in guest mode).
  Future<void> refresh() async {
    if (_disposed || !_signedInAndEnabled) return;
    final familyId = ref.read(sessionProvider).valueOrNull?.familyId;
    if (familyId == null) return;
    final next = await _fetchList(familyId);
    if (_disposed) return;
    state = AsyncData(next);
  }

  /// Creates a new 6-character friend code and schedules automatic expiry cleanup.
  Future<FriendsActionResult<FriendCode>> createCode() async {
    if (_disposed || !_signedInAndEnabled) {
      return const FriendsActionResult.err(
        errorCode: 'signed_out',
        errorMessage: 'Ba mẹ cần đăng nhập Tài khoản gia đình',
      );
    }
    try {
      final code = await ref.read(friendsApiProvider).createCode();
      if (_disposed) return FriendsActionResult.ok(code);
      _setActiveCode(code);
      final current = state.valueOrNull ?? const FriendsState();
      state = AsyncData(
        current.copyWith(
          activeCode: () => _validActiveCode(),
          errorMessage: () => null,
          offline: false,
        ),
      );
      return FriendsActionResult.ok(code);
    } catch (e) {
      final mapped = mapFriendError(e, networkOffline: _isOffline);
      return FriendsActionResult.err(
        errorCode: mapped.code,
        errorMessage: mapped.message,
      );
    }
  }

  /// Redeems [rawCode], adding the friend family on success.
  Future<FriendsActionResult<FriendFamily>> redeemCode(String rawCode) async {
    if (_disposed || !_signedInAndEnabled) {
      return const FriendsActionResult.err(
        errorCode: 'signed_out',
        errorMessage: 'Ba mẹ cần đăng nhập Tài khoản gia đình',
      );
    }
    final normalized = normalizeFriendCode(rawCode);
    if (normalized.isEmpty) {
      return const FriendsActionResult.err(
        errorCode: 'invalid_code',
        errorMessage: 'Mã không đúng hoặc đã hết hạn',
      );
    }
    try {
      final added = await ref.read(friendsApiProvider).redeemCode(normalized);
      if (_disposed) return FriendsActionResult.ok(added);
      final lobby = ref.read(lobbyClientProvider);
      final friend = lobby.connected
          ? added.copyWith(online: lobby.onlineFriends.contains(added.familyId))
          : added;

      final current = state.valueOrNull ?? const FriendsState();
      final nextFriends = [
        ...current.friends.where((f) => f.familyId != friend.familyId),
        friend,
      ];
      final familyId = ref.read(sessionProvider).valueOrNull?.familyId;
      if (familyId != null) {
        _cachedByFamily[familyId] = List.unmodifiable(nextFriends);
      }
      state = AsyncData(
        current.copyWith(
          friends: List.unmodifiable(nextFriends),
          errorMessage: () => null,
          offline: false,
        ),
      );
      return FriendsActionResult.ok(friend);
    } catch (e) {
      final mapped = mapFriendError(e, networkOffline: _isOffline);
      return FriendsActionResult.err(
        errorCode: mapped.code,
        errorMessage: mapped.message,
      );
    }
  }

  /// Removes the friendship with [familyId] on the server and locally.
  Future<FriendsActionResult<void>> removeFriend(String familyId) async {
    if (_disposed || !_signedInAndEnabled) {
      return const FriendsActionResult.err(
        errorCode: 'signed_out',
        errorMessage: 'Ba mẹ cần đăng nhập Tài khoản gia đình',
      );
    }
    try {
      await ref.read(friendsApiProvider).removeFriend(familyId);
      if (_disposed) return const FriendsActionResult.ok();
      _removeLocally(familyId);
      return const FriendsActionResult.ok();
    } catch (e) {
      final mapped = mapFriendError(e, networkOffline: _isOffline);
      return FriendsActionResult.err(
        errorCode: mapped.code,
        errorMessage: mapped.message,
      );
    }
  }

  List<FriendFamily> _mergeLobbyPresence(List<FriendFamily> raw) {
    final lobby = ref.read(lobbyClientProvider);
    if (!lobby.connected) return List<FriendFamily>.unmodifiable(raw);
    return List<FriendFamily>.unmodifiable([
      for (final f in raw)
        f.copyWith(online: lobby.onlineFriends.contains(f.familyId)),
    ]);
  }

  void _updatePresence(Set<String> onlineIds) {
    final current = state.valueOrNull;
    if (current == null || current.friends.isEmpty) return;
    var changed = false;
    final next = <FriendFamily>[];
    for (final f in current.friends) {
      final isOnline = onlineIds.contains(f.familyId);
      if (isOnline != f.online) changed = true;
      next.add(isOnline == f.online ? f : f.copyWith(online: isOnline));
    }
    if (!changed) return;
    final unmodifiable = List<FriendFamily>.unmodifiable(next);
    final familyId = ref.read(sessionProvider).valueOrNull?.familyId;
    if (familyId != null) {
      _cachedByFamily[familyId] = unmodifiable;
    }
    state = AsyncData(current.copyWith(friends: unmodifiable));
  }

  void _removeLocally(String otherFamilyId) {
    final current = state.valueOrNull;
    if (current == null) return;
    final next = List<FriendFamily>.unmodifiable(
      current.friends.where((f) => f.familyId != otherFamilyId),
    );
    final familyId = ref.read(sessionProvider).valueOrNull?.familyId;
    if (familyId != null) {
      _cachedByFamily[familyId] = next;
    }
    state = AsyncData(current.copyWith(friends: next));
  }

  FriendCode? _validActiveCode() {
    final code = _activeCode;
    if (code == null) return null;
    if (!code.expiresAt.isAfter(_clock())) {
      _activeCode = null;
      _cancelExpiryTimer();
      return null;
    }
    return code;
  }

  void _setActiveCode(FriendCode code) {
    _cancelExpiryTimer();
    final delay = code.expiresAt.difference(_clock());
    if (delay <= Duration.zero) {
      _activeCode = null;
      return;
    }
    _activeCode = code;
    _expiryTimer = Timer(delay, () {
      _expiryTimer = null;
      _activeCode = null;
      if (_disposed) return;
      final current = state.valueOrNull;
      if (current != null && current.activeCode != null) {
        state = AsyncData(current.copyWith(activeCode: () => null));
      }
    });
  }

  void _cancelExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
  }
}

final friendsControllerProvider =
    AsyncNotifierProvider<FriendsController, FriendsState>(
  FriendsController.new,
);

/// Convenience provider exposing just the live friend list.
final friendsProvider = Provider<AsyncValue<List<FriendFamily>>>((ref) {
  return ref.watch(friendsControllerProvider).whenData((s) => s.friends);
});
