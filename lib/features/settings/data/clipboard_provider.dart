import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/security/clipboard_service.dart';
import '../../../core/theme/theme_provider.dart';

/// Seconds before copied secrets are wiped from the clipboard (0 = never).
const clipboardClearOptions = <int, String>{
  15: 'After 15 seconds',
  30: 'After 30 seconds',
  60: 'After 1 minute',
  120: 'After 2 minutes',
  0: 'Never',
};

class ClipboardClearNotifier extends Notifier<int> {
  @override
  int build() {
    final stored = ref
        .watch(sharedPreferencesProvider)
        .getInt(AppConstants.prefClipboardClearSeconds);
    return (stored != null && clipboardClearOptions.containsKey(stored))
        ? stored
        : 30;
  }

  Future<void> set(int seconds) async {
    state = seconds;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(AppConstants.prefClipboardClearSeconds, seconds);
  }
}

final clipboardClearProvider =
    NotifierProvider<ClipboardClearNotifier, int>(ClipboardClearNotifier.new);

final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  final service = ClipboardService(() => ref.read(clipboardClearProvider));
  ref.onDispose(service.dispose);
  return service;
});
