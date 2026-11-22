import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/data/auto_lock_provider.dart';
import 'auth_controller.dart';

/// Locks the vault on inactivity and when the app has been in the background
/// for longer than the configured timeout (0 = lock as soon as it leaves the
/// foreground).
class AutoLockWatcher extends ConsumerStatefulWidget {
  const AutoLockWatcher({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AutoLockWatcher> createState() => _AutoLockWatcherState();
}

class _AutoLockWatcherState extends ConsumerState<AutoLockWatcher>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _pausedAt;

  bool get _unlocked =>
      ref.read(authControllerProvider).status == AuthStatus.unlocked;

  void _lock() => ref.read(authControllerProvider.notifier).lock();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (!_unlocked) return;
    final secs = ref.read(autoLockProvider);
    if (secs <= 0) return;
    _timer = Timer(Duration(seconds: secs), _lock);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final secs = ref.read(autoLockProvider);
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      _timer?.cancel();
      if (secs == 0 && _unlocked) _lock();
    } else if (state == AppLifecycleState.resumed) {
      final paused = _pausedAt;
      _pausedAt = null;
      if (paused != null && _unlocked) {
        if (DateTime.now().difference(paused).inSeconds >= secs) {
          _lock();
        } else {
          _restartTimer();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(autoLockProvider, (_, __) => _restartTimer());
    ref.listen<AuthStatus>(
      authControllerProvider.select((s) => s.status),
      (_, status) {
        if (status == AuthStatus.unlocked) {
          _restartTimer();
        } else {
          _timer?.cancel();
        }
      },
    );
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restartTimer(),
      child: widget.child,
    );
  }
}
