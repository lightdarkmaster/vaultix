import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Numeric keypad with PIN dots. Calls [onCompleted] when [length] digits are
/// entered, then clears itself so the caller can show errors / next steps.
class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.onCompleted,
    this.length = 6,
    this.enabled = true,
    this.errorText,
  });

  final ValueChanged<String> onCompleted;
  final int length;
  final bool enabled;
  final String? errorText;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  String _digits = '';

  void _tap(String d) {
    if (!widget.enabled || _digits.length >= widget.length) return;
    HapticFeedback.selectionClick();
    setState(() => _digits += d);
    if (_digits.length == widget.length) {
      final pin = _digits;
      widget.onCompleted(pin);
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _digits = '');
      });
    }
  }

  void _back() {
    if (!widget.enabled || _digits.isEmpty) return;
    setState(() => _digits = _digits.substring(0, _digits.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 7),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _digits.length
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.15),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 32,
          child: Center(
            child: widget.errorText == null
                ? null
                : Text(widget.errorText!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.error, fontSize: 13)),
          ),
        ),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final d in row) _key(context, d)],
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 88, height: 80),
            _key(context, '0'),
            SizedBox(
              width: 88,
              height: 80,
              child: IconButton(
                tooltip: 'Delete',
                onPressed: widget.enabled ? _back : null,
                icon: const Icon(Icons.backspace_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _key(BuildContext context, String d) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 88,
      height: 80,
      child: Center(
        child: Material(
          color: scheme.onSurface.withValues(alpha: 0.06),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.enabled ? () => _tap(d) : null,
            child: SizedBox(
              width: 68,
              height: 68,
              child: Center(
                child: Text(d,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
