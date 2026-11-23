import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// While the count is above zero the auto-lock watcher will not lock the
/// vault. Used around the file picker and share sheet, which move Vaultix to
/// the background.
class AutoLockSuspension extends Notifier<int> {
  @override
  int build() => 0;

  void acquire() => state = state + 1;
  void release() => state = max(0, state - 1);
}

final autoLockSuspensionProvider =
    NotifierProvider<AutoLockSuspension, int>(AutoLockSuspension.new);

/// Runs [action] with auto-lock suspended. The suspension is held for two
/// extra seconds afterwards because the "app resumed" event can arrive just
/// after the picker / share sheet future completes.
Future<T> runWithoutAutoLock<T>(WidgetRef ref, Future<T> Function() action) async {
  final suspension = ref.read(autoLockSuspensionProvider.notifier);
  suspension.acquire();
  try {
    return await action();
  } finally {
    Future.delayed(const Duration(seconds: 2), suspension.release);
  }
}
