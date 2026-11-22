import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/auth_controller.dart';
import '../../features/authentication/presentation/lock_page.dart';
import '../../features/authentication/presentation/setup_page.dart';
import '../../features/authentication/presentation/splash_page.dart';
import '../../features/categories/presentation/categories_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/password_generator/presentation/generator_page.dart';
import '../../features/settings/presentation/change_master_password_page.dart';
import '../../features/settings/presentation/pin_setup_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/vault/presentation/vault_page.dart';
import '../widgets/app_shell.dart';

const _authPages = {'/splash', '/setup', '/lock'};

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthStatus>(
    authControllerProvider.select((s) => s.status),
    (_, __) => refresh.value++,
  );

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final loc = state.matchedLocation;
      final target = switch (status) {
        AuthStatus.loading => '/splash',
        AuthStatus.setupRequired => '/setup',
        AuthStatus.locked => '/lock',
        AuthStatus.unlocked => _authPages.contains(loc) ? '/home' : null,
      };
      return target == loc ? null : target;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(path: '/setup', builder: (_, __) => const SetupPage()),
      GoRoute(path: '/lock', builder: (_, __) => const LockPage()),
      GoRoute(path: '/pin-setup', builder: (_, __) => const PinSetupPage()),
      GoRoute(path: '/categories', builder: (_, __) => const CategoriesPage()),
      GoRoute(
        path: '/change-master',
        builder: (_, __) => const ChangeMasterPasswordPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, __) => const DashboardPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/vault', builder: (_, __) => const VaultPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/generator', builder: (_, __) => const GeneratorPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
          ]),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
