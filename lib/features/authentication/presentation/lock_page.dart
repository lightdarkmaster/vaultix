import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/pin_pad.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/vaultix_text_field.dart';
import '../domain/auth_service.dart';
import 'auth_controller.dart';

class LockPage extends ConsumerStatefulWidget {
  const LockPage({super.key});

  @override
  ConsumerState<LockPage> createState() => _LockPageState();
}

class _LockPageState extends ConsumerState<LockPage> {
  final _password = TextEditingController();
  bool _usePin = false;
  bool _busy = false;
  String? _error;
  DateTime? _lockedUntil;
  Timer? _ticker;

  AuthController get _auth => ref.read(authControllerProvider.notifier);

  @override
  void initState() {
    super.initState();
    final s = ref.read(authControllerProvider);
    _usePin = s.pinEnabled;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshLockout();
      if (mounted && s.biometricEnabled && _lockedUntil == null) {
        _unlockBiometric();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _password.dispose();
    super.dispose();
  }

  Future<void> _refreshLockout() async =>
      _setLock(await _auth.lockoutRemaining());

  void _setLock(Duration? left) {
    _ticker?.cancel();
    if (left == null) {
      if (mounted) setState(() => _lockedUntil = null);
      return;
    }
    _lockedUntil = DateTime.now().add(left);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (DateTime.now().isAfter(_lockedUntil!)) {
        _ticker?.cancel();
        setState(() {
          _lockedUntil = null;
          _error = null;
        });
      } else {
        setState(() {});
      }
    });
    if (mounted) setState(() {});
  }

  void _handle(UnlockOutcome o) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (o.status) {
        case UnlockStatus.success:
          break;
        case UnlockStatus.wrong:
          final what = _usePin ? 'PIN' : 'master password';
          _error = o.attemptsLeft != null
              ? 'Incorrect $what. ${o.attemptsLeft} attempt'
                  '${o.attemptsLeft == 1 ? '' : 's'} left before a temporary lock.'
              : 'Incorrect $what.';
        case UnlockStatus.lockedOut:
          _error = null;
          _setLock(o.lockedFor);
        case UnlockStatus.pinRemoved:
          _usePin = false;
          _error = 'PIN removed after too many wrong attempts. '
              'Use your master password.';
        case UnlockStatus.cancelled:
          break;
        case UnlockStatus.unavailable:
          _error = 'That unlock method is not available.';
      }
    });
    if (o.status != UnlockStatus.success) _password.clear();
  }

  Future<void> _unlockPassword() async {
    if (_busy || _lockedUntil != null || _password.text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    _handle(await _auth.unlockWithPassword(_password.text));
  }

  Future<void> _unlockPin(String pin) async {
    if (_busy || _lockedUntil != null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    _handle(await _auth.unlockWithPin(pin));
  }

  Future<void> _unlockBiometric() async {
    if (_busy || _lockedUntil != null) return;
    setState(() => _busy = true);
    _handle(await _auth.unlockWithBiometric());
  }

  String _remaining() {
    final left = _lockedUntil!.difference(DateTime.now());
    final s = left.inSeconds.clamp(0, 86400);
    return '${(s ~/ 60).toString().padLeft(2, '0')}:'
        '${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final locked = _lockedUntil != null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock_rounded,
                          size: 40, color: scheme.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text('Your vault is locked',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.65))),
                  const SizedBox(height: 28),
                  if (locked) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Too many failed attempts.\nTry again in ${_remaining()}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: scheme.error, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ] else if (_usePin) ...[
                    PinPad(
                      length: AppConstants.pinLength,
                      enabled: !_busy,
                      errorText: _error,
                      onCompleted: _unlockPin,
                    ),
                  ] else ...[
                    VaultixTextField(
                      controller: _password,
                      label: 'Master password',
                      icon: Icons.key_rounded,
                      isPassword: true,
                      autofocus: !auth.biometricEnabled,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _unlockPassword(),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(_error!,
                            style: TextStyle(color: scheme.error, fontSize: 13)),
                      ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Unlock',
                      icon: Icons.lock_open_rounded,
                      isLoading: _busy,
                      onPressed: _unlockPassword,
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (!locked && auth.biometricEnabled)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _unlockBiometric,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Use biometrics'),
                    ),
                  if (auth.pinEnabled && !locked)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _usePin = !_usePin;
                                _error = null;
                              }),
                      child: Text(_usePin
                          ? 'Use master password instead'
                          : 'Use PIN instead'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
