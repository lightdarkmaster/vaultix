import 'dart:async';

import 'package:flutter/services.dart';

/// Copies text and clears the clipboard again after a delay.
///
/// The clipboard is only cleared if it still holds what we put there (so we
/// don't wipe something the user copied later). If Android refuses to let a
/// background app read the clipboard, we clear anyway, because leaving a
/// password behind is the worse failure.
class ClipboardService {
  ClipboardService(this._delaySeconds);

  /// Returns the configured delay in seconds; 0 means never clear.
  final int Function() _delaySeconds;

  Timer? _timer;
  String? _pending;

  int get delaySeconds => _delaySeconds();

  Future<void> copy(String text, {bool sensitive = true}) async {
    await Clipboard.setData(ClipboardData(text: text));
    _timer?.cancel();
    _timer = null;
    _pending = null;
    final secs = _delaySeconds();
    if (!sensitive || secs <= 0) return;
    _pending = text;
    _timer = Timer(Duration(seconds: secs), clearIfPending);
  }

  Future<void> clearIfPending() async {
    final pending = _pending;
    _timer?.cancel();
    _timer = null;
    _pending = null;
    if (pending == null) return;
    try {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      final text = current?.text;
      if (text != null && text.isNotEmpty && text != pending) return;
    } catch (_) {
      // Could not read (background restriction): fall through and clear.
    }
    await Clipboard.setData(const ClipboardData(text: ''));
  }

  void dispose() => _timer?.cancel();
}
