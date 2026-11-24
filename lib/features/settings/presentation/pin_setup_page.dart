import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/pin_pad.dart';
import '../../authentication/presentation/auth_controller.dart';

class PinSetupPage extends ConsumerStatefulWidget {
  const PinSetupPage({super.key});

  @override
  ConsumerState<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends ConsumerState<PinSetupPage> {
  String? _first;
  String? _error;
  bool _busy = false;

  bool _isWeak(String pin) {
    if (RegExp(r'^(\d)\1+$').hasMatch(pin)) return true;
    return pin == '123456' || pin == '654321' || pin == '012345';
  }

  Future<void> _onPin(String pin) async {
    if (_first == null) {
      if (_isWeak(pin)) {
        setState(() => _error = 'Too easy to guess. Choose a less obvious PIN.');
        return;
      }
      setState(() {
        _first = pin;
        _error = null;
      });
      return;
    }
    if (pin != _first) {
      setState(() {
        _first = null;
        _error = 'PINs did not match. Start again.';
      });
      return;
    }
    setState(() => _busy = true);
    final ok = await ref.read(authControllerProvider.notifier).enablePin(pin);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not enable PIN. Unlock the vault and try again.')),
      );
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('PIN unlock enabled')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up PIN')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _first == null ? 'Choose a 6-digit PIN' : 'Confirm your PIN',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'After 5 wrong PINs it is removed and your master password '
                  'is required.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 28),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  )
                else
                  PinPad(
                    length: AppConstants.pinLength,
                    errorText: _error,
                    onCompleted: _onPin,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
