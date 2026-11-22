import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_provider.dart';

/// Seconds of inactivity before locking. 0 = lock when the app is backgrounded.
const autoLockOptions = <int, String>{
  0: 'As soon as I leave the app',
  60: 'After 1 minute',
  300: 'After 5 minutes',
  900: 'After 15 minutes',
  1800: 'After 30 minutes',
};

class AutoLockNotifier extends Notifier<int> {
  @override
  int build() {
    final stored = ref
        .watch(sharedPreferencesProvider)
        .getInt(AppConstants.prefAutoLockSeconds);
    return (stored != null && autoLockOptions.containsKey(stored))
        ? stored
        : 60;
  }

  Future<void> set(int seconds) async {
    state = seconds;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(AppConstants.prefAutoLockSeconds, seconds);
  }
}

final autoLockProvider =
    NotifierProvider<AutoLockNotifier, int>(AutoLockNotifier.new);
