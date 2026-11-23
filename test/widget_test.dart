// Replaces the counter-app test that `flutter create` generates, which would
// not compile against Vaultix.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vaultix/core/theme/app_colors.dart';
import 'package:vaultix/core/theme/app_theme.dart';
import 'package:vaultix/core/widgets/empty_state.dart';
import 'package:vaultix/core/widgets/password_strength_meter.dart';
import 'package:vaultix/core/widgets/pin_pad.dart';

Widget host(Widget child, {Brightness brightness = Brightness.light}) =>
    MaterialApp(
      theme: brightness == Brightness.light
          ? AppTheme.light(AppColors.primary)
          : AppTheme.dark(AppColors.primary),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // HapticFeedback talks to the platform; answer quietly in tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  test('themes build for both brightness modes with the chosen accent', () {
    const accent = Color(0xFF20B486);
    expect(AppTheme.light(accent).colorScheme.primary, accent);
    expect(AppTheme.dark(accent).colorScheme.primary, accent);
    expect(AppTheme.dark(accent).brightness, Brightness.dark);
  });

  testWidgets('strength meter shows a label, and nothing for empty input',
      (tester) async {
    await tester.pumpWidget(host(const PasswordStrengthMeter(password: '')));
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.pumpWidget(
        host(const PasswordStrengthMeter(password: 'correct-Horse-battery-7-staple')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Strong'), findsOneWidget);

    await tester.pumpWidget(host(const PasswordStrengthMeter(password: 'abc')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Very weak'), findsOneWidget);
  });

  testWidgets('empty state shows its action and calls it', (tester) async {
    var tapped = false;
    await tester.pumpWidget(host(EmptyState(
      icon: Icons.lock_rounded,
      title: 'Your vault is empty',
      message: 'Add your first password.',
      actionLabel: 'Add password',
      onAction: () => tapped = true,
    )));
    expect(find.text('Your vault is empty'), findsOneWidget);
    await tester.tap(find.text('Add password'));
    expect(tapped, isTrue);
  });

  testWidgets('PIN pad reports the PIN once all digits are entered',
      (tester) async {
    String? entered;
    await tester.pumpWidget(host(PinPad(onCompleted: (pin) => entered = pin)));

    for (final d in ['1', '9', '4', '7', '2']) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
    expect(entered, isNull); // five of six digits so far

    await tester.tap(find.text('0'));
    await tester.pump();
    expect(entered, '194720');

    // Let the pad clear itself (150 ms) so no timer is left pending.
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('PIN pad ignores input while disabled', (tester) async {
    String? entered;
    await tester.pumpWidget(
        host(PinPad(enabled: false, onCompleted: (pin) => entered = pin)));
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('5'));
      await tester.pump();
    }
    expect(entered, isNull);
  });
}
